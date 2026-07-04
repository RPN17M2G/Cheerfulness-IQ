import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessIQDelegate extends WatchUi.BehaviorDelegate {

    var _view as CheerfulnessIQView;

    function initialize(viewParameter as CheerfulnessIQView) {
        BehaviorDelegate.initialize();
        _view = viewParameter;
    }

    function onNextPage() as Boolean {
        _view.scrollDown();
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scrollUp();
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({
            :title => WatchUi.loadResource(Rez.Strings.MenuTitle) as String
        });

        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.NextQuote) as String,
            "", :next_quote, null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.SelectMood) as String,
            "", :select_mood, null
        ));

        WatchUi.pushView(menu, new CheerfulnessIQMenuDelegate(_view), WatchUi.SLIDE_UP);
        return true;
    }
}
