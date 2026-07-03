import Toybox.Application;
import Toybox.Time;

module CoreSettings {
    private const COOLDOWN_KEY = "cooldown_enabled";
    private const LAST_SWAP_KEY = "last_swap";
    private const COOLDOWN_SECONDS = 3600;

    function getCooldownEnabled() as Boolean {
        var val = Application.getApp().getProperty(COOLDOWN_KEY);
        if (val == null) {
            return false;
        }
        return val as Boolean;
    }

    function setCooldownEnabled(val as Boolean) as Void {
        Application.getApp().setProperty(COOLDOWN_KEY, val);
    }

    private function getLastSwap() as Number {
        var val = Application.getApp().getProperty(LAST_SWAP_KEY);
        if (val == null) {
            return 0;
        }
        return val as Number;
    }

    function setLastSwap(ts as Number) as Void {
        Application.getApp().setProperty(LAST_SWAP_KEY, ts);
    }

    function canSwapQuote() as Boolean {
        if (!getCooldownEnabled()) {
            return true;
        }
        var now = Time.now().value();
        var lastSwap = getLastSwap();
        return (now - lastSwap) >= COOLDOWN_SECONDS;
    }
}
