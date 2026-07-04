import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessIQMenuDelegate extends WatchUi.Menu2InputDelegate {

    var _view as CheerfulnessIQView;

    private const MOOD_SYMBOLS = [
        :mood_resting, :mood_prime, :mood_burnout, :mood_wired
    ];

    function initialize(view as CheerfulnessIQView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as MenuItem) {
        var identifier = item.getId() as Symbol;

        if (identifier.equals(:next_quote)) {
            onNextQuote();
        } else if (identifier.equals(:select_mood)) {
            onSelectMood();
        } else if (identifier.equals(:settings)) {
            onSettings();
        } else {
            onForceMood(identifier);
        }
    }

    private function onNextQuote() as Boolean {
        CoreQuoteEngine.advance(_view.moodId);
        _view.scrollOffset = 0;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
        return true;
    }

    private function onSelectMood() as Boolean {
        var menu = new WatchUi.Menu2({
            :title => WatchUi.loadResource(Rez.Strings.SelectMood) as String
        });

        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodRestingLabel) as String,
            "", :mood_resting, null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodPrimeLabel) as String,
            "", :mood_prime, null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodBurnoutLabel) as String,
            "", :mood_burnout, null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.MoodWiredLabel) as String,
            "", :mood_wired, null
        ));

        WatchUi.pushView(menu, self, WatchUi.SLIDE_UP);
        return true;
    }

    private function onForceMood(identifier as Symbol) as Boolean {
        for (var index = 0; index < MOOD_SYMBOLS.size(); index++) {
            if (identifier.equals(MOOD_SYMBOLS[index])) {
                _view.moodId = index;
                _view.isMoodForced = true;
                CoreQuoteEngine.initialize(index);
                _view.loadBitmap(index);
                _view.scrollOffset = 0;
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.requestUpdate();
                return true;
            }
        }
        return false;
    }

    private function onSettings() as Boolean {
        var currentThreshold = CoreBiometrics.stressThreshold();

        var thresholdOptions = [30, 40, 50, 60, 70, 80];
        var menu = new WatchUi.Menu2({
            :title => WatchUi.loadResource(Rez.Strings.StressThresholdLabel) as String
        });

        for (var i = 0; i < thresholdOptions.size(); i++) {
            var optionValue = thresholdOptions[i];
            var sublabel = optionValue == currentThreshold ? "(current)" : "";
            menu.addItem(new WatchUi.MenuItem(
                optionValue.toString(), sublabel, null, null
            ));
        }

        WatchUi.pushView(menu, new SettingsInputDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class SettingsInputDelegate extends WatchUi.Menu2InputDelegate {

    var _view as CheerfulnessIQView;

    function initialize(view as CheerfulnessIQView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as MenuItem) {
        Application.Storage.setValue("stressThreshold", item.getLabel());
        CoreBiometrics.clearCachedResult();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
