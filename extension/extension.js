import Gio from 'gi://Gio';
import GObject from 'gi://GObject';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as QuickSettings from 'resource:///org/gnome/shell/ui/quickSettings.js';

const HELPER = '/usr/local/libexec/gnome-touchscreen-toggle';

Gio._promisify(Gio.Subprocess.prototype, 'communicate_utf8_async');

const TouchscreenToggle = GObject.registerClass(
class TouchscreenToggle extends QuickSettings.QuickToggle {
    _init() {
        super._init({
            title: _('Touchscreen'),
            iconName: 'input-touchpad-symbolic',
            toggleMode: true,
        });

        this.connect('clicked', () => this._setEnabled(this.checked));
        this._refresh();
    }

    async _run(argv) {
        const process = Gio.Subprocess.new(
            argv,
            Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE);
        const [stdout, stderr] = await process.communicate_utf8_async(null, null);
        if (!process.get_successful())
            throw new Error(stderr.trim() || `Helper exited with status ${process.get_exit_status()}`);
        return stdout.trim();
    }

    async _refresh() {
        try {
            this.checked = (await this._run([HELPER, 'status'])) === 'enabled';
            this.subtitle = this.checked ? _('On') : _('Off');
            this.reactive = true;
        } catch (error) {
            console.error(`Touchscreen Toggle: ${error.message}`);
            this.subtitle = _('Unavailable');
            this.reactive = false;
        }
    }

    async _setEnabled(enabled) {
        this.reactive = false;
        this.subtitle = _('Applying…');

        try {
            await this._run(['pkexec', HELPER, enabled ? 'enable' : 'disable']);
        } catch (error) {
            console.error(`Touchscreen Toggle: ${error.message}`);
            Main.notifyError(_('Touchscreen Toggle'), error.message);
        } finally {
            await this._refresh();
        }
    }
});

const TouchscreenIndicator = GObject.registerClass(
class TouchscreenIndicator extends QuickSettings.SystemIndicator {
    _init() {
        super._init();
        this.quickSettingsItems.push(new TouchscreenToggle());
    }

    destroy() {
        this.quickSettingsItems.forEach(item => item.destroy());
        super.destroy();
    }
});

export default class TouchscreenToggleExtension extends Extension {
    enable() {
        this._indicator = new TouchscreenIndicator();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicator);
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
