import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessIQMenuDelegate extends WatchUi.Menu2InputDelegate {

    var viewReference as CheerfulnessIQView;

    private const MOOD_IDENTIFIER_SYMBOLS = [
        :mood_resting, :mood_prime, :mood_burnout, :mood_wired
    ];

    function initialize(view as CheerfulnessIQView) {
        Menu2InputDelegate.initialize();
        viewReference = view;
    }

    function onSelect(item as MenuItem) {
        var identifier = item.getId() as Symbol;

        if (identifier.equals(:next_quote)) {
            _onNextQuote();
        } else if (identifier.equals(:select_mood)) {
            _onSelectMood();
        } else {
            _onForceMood(identifier);
        }
    }

    private function _onNextQuote() as Boolean {
        CoreQuoteEngine.advance(viewReference.currentMoodIdentifier);
        viewReference.scrollOffset = 0;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
        return true;
    }

    private function _onSelectMood() as Boolean {
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

    private function _onForceMood(identifier as Symbol) as Boolean {
        for (var index = 0; index < MOOD_IDENTIFIER_SYMBOLS.size(); index++) {
            if (identifier.equals(MOOD_IDENTIFIER_SYMBOLS[index])) {
                viewReference.currentMoodIdentifier = index;
                viewReference.isMoodForced = true;
                CoreQuoteEngine.initialize(index);
                viewReference.loadBitmap(index);
                viewReference.scrollOffset = 0;
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                WatchUi.requestUpdate();
                return true;
            }
        }
        return false;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
