import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Time;

class CheerfulnessIQMenuDelegate extends WatchUi.Menu2InputDelegate {

    var view as CheerfulnessIQView;

    function initialize(v as CheerfulnessIQView) {
        Menu2InputDelegate.initialize();
        view = v;
    }

    function onSelect(item as MenuItem) {
        var id = item.getId() as Symbol;

        if (id.equals(:next_quote)) {
            _onNextQuote();
        } else if (id.equals(:select_mood)) {
            _onSelectMood();
        } else if (id.equals(:mood_resting) || id.equals(:mood_prime) ||
                   id.equals(:mood_burnout) || id.equals(:mood_wired)) {
            _onForceMood(id);
        }
    }

    private function _onNextQuote() as Boolean {
        CoreQuoteEngine.advance(view.currentMood);
        view.scrollOffset = 0;
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
        return true;
    }

    private function _onForceMood(id as Symbol) as Boolean {
        if (id.equals(:mood_resting)) {
            view.currentMood = 0;
        } else if (id.equals(:mood_prime)) {
            view.currentMood = 1;
        } else if (id.equals(:mood_burnout)) {
            view.currentMood = 2;
        } else if (id.equals(:mood_wired)) {
            view.currentMood = 3;
        }

        view.moodForced = true;
        CoreQuoteEngine.init(view.currentMood);
        view.loadBitmap(view.currentMood);
        view.scrollOffset = 0;
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
