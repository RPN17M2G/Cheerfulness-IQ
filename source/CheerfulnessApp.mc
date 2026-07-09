import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    (:glance)
    function getGlanceView() {
        return [ new CheerfulnessGlanceView() ];
    }

    function getInitialView() {
        var view = new CheerfulnessView();
        return [ view, new CheerfulnessDelegate(view) ];
    }
}

function getApp() as CheerfulnessApp {
    return Application.getApp() as CheerfulnessApp;
}
