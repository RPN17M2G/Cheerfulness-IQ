import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessIQApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new CheerfulnessIQView();
        var delegate = new CheerfulnessIQDelegate(view);
        return [view, delegate];
    }

    (:glance)
    function getGlanceView() {
        return [ new CheerfulnessIQGlanceView() ];
    }
}

function getApp() as CheerfulnessIQApp {
    return Application.getApp() as CheerfulnessIQApp;
}
