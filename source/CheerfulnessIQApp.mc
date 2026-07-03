import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;

class CheerfulnessIQApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    (:glance)
    function getGlanceView() {
        return [ new CheerfulnessIQGlanceView() ];
    }

    function getInitialView() {
        var view = new CheerfulnessIQView();
        return [ view, new CheerfulnessIQDelegate(view) ];
    }
}

function getApp() as CheerfulnessIQApp {
    return Application.getApp() as CheerfulnessIQApp;
}