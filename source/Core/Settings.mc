import Toybox.Application;
import Toybox.Time;

module CoreSettings {
    function getCooldownEnabled() as Boolean {
        var val = Application.getApp().getProperty("cooldown_enabled");
        if (val == null) {
            return false;
        }
        return val as Boolean;
    }

    function setCooldownEnabled(val as Boolean) as Void {
        Application.getApp().setProperty("cooldown_enabled", val);
    }

    function getLastSwap() as Number {
        var val = Application.getApp().getProperty("last_swap");
        if (val == null) {
            return 0;
        }
        return val as Number;
    }

    function setLastSwap(ts as Number) as Void {
        Application.getApp().setProperty("last_swap", ts);
    }

    function canSwapQuote() as Boolean {
        if (!getCooldownEnabled()) {
            return true;
        }
        var now = Time.now().value();
        var lastSwap = getLastSwap();
        return (now - lastSwap) >= 3600;
    }
}
