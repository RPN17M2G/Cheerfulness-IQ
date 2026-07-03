import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.System;

class CheerfulnessIQDelegate extends WatchUi.BehaviorDelegate {

    var view as CheerfulnessIQView;

    function initialize(v as CheerfulnessIQView) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.scrollOffset = view.scrollOffset - 25;
        WatchUi.requestUpdate();
        return true;
    }

    function onPreviousPage() as Boolean {
        view.scrollOffset = view.scrollOffset + 25;
        if (view.scrollOffset > 0) {
            view.scrollOffset = 0;
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onSelect() as Boolean {
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.MenuTitle) as String});

        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.NextQuote) as String,
            "",
            :next_quote,
            null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.SelectMood) as String,
            "",
            :select_mood,
            null
        ));
        menu.addItem(new WatchUi.MenuItem(
            WatchUi.loadResource(Rez.Strings.ToggleCooldown) as String,
            "",
            :toggle_cooldown,
            null
        ));

        WatchUi.pushView(menu, new CheerfulnessIQMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}
