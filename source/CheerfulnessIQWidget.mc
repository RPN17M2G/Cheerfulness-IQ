import Toybox.WatchUi;
import Toybox.Application;
import Toybox.Lang;

class CheerfulnessIQWidget extends WatchUi.Widget {

    function initialize() {
        Widget.initialize();
    }

    function getGlanceView() as WatchUi.GlanceView? {
        return new CheerfulnessIQGlanceView();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new CheerfulnessIQView();
        var delegate = new CheerfulnessIQDelegate(view);
        return [view, delegate];
    }
}

function getApp() as CheerfulnessIQWidget {
    return Application.getApp() as CheerfulnessIQWidget;
}
