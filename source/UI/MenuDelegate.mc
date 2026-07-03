import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;
import Toybox.System;

class CheerfulnessIQMenuDelegate extends WatchUi.Menu2InputDelegate {

    var view as CheerfulnessIQView;

    function initialize(v as CheerfulnessIQView) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item as MenuItem) as Void {
        var id = item.getId();

        if (id.equals(:next_quote)) {
            _onNextQuote();
        } else if (id.equals(:select_mood)) {
            _onSelectMood();
        } else if (id.equals(:toggle_cooldown)) {
            _onToggleCooldown();
        } else if (id.equals(:mood_resting) || id.equals(:mood_prime) ||
                   id.equals(:mood_burnout) || id.equals(:mood_wired)) {
            _onForceMood(id);
        }
    }

    private function _onNextQuote() as Void {
        if (CoreSettings.canSwapQuote()) {
            CoreSettings.setLastSwap(Time.now().value());
            CoreQuoteEngine.advance(view.currentMood);
            view.scrollOffset = 0;
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        }
    }

    private function _onSelectMood() as Void {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.SelectMood) as String});

        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodRestingLabel) as String,
            "",
            :mood_resting,
            null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodPrimeLabel) as String,
            "",
            :mood_prime,
            null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodBurnoutLabel) as String,
            "",
            :mood_burnout,
            null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodWiredLabel) as String,
            "",
            :mood_wired,
            null
        ));

        WatchUi.pushView(menu, self, WatchUi.SLIDE_UP);
    }

    private function _onForceMood(id as Symbol) as Void {
        if (id.equals(:mood_resting)) { view.currentMood = 0; }
        else if (id.equals(:mood_prime)) { view.currentMood = 1; }
        else if (id.equals(:mood_burnout)) { view.currentMood = 2; }
        else if (id.equals(:mood_wired)) { view.currentMood = 3; }

        CoreQuoteEngine.init(view.currentMood);
        view._loadBitmap(view.currentMood);
        view.scrollOffset = 0;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    private function _onToggleCooldown() as Void {
        var enabled = CoreSettings.getCooldownEnabled();
        CoreSettings.setCooldownEnabled(!enabled);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
