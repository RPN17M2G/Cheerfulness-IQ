import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;

class CheerfulnessIQView extends WatchUi.View {

    var scrollOffset as Number;
    var activeBitmap as BitmapResource?;
    var currentMood as Number;

    function initialize() {
        View.initialize();
        scrollOffset = 0;
        activeBitmap = null;
        currentMood = 0;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        currentMood = CoreBiometrics.evaluate();
        CoreQuoteEngine.init(currentMood);
        _loadBitmap(currentMood);
        scrollOffset = 0;
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        activeBitmap = null;
    }

    private function _loadBitmap(moodId as Number) as Void {
        if (moodId == 1) {
            activeBitmap = WatchUi.loadResource(Rez.Drawables.MoodPrime) as BitmapResource;
        } else if (moodId == 2) {
            activeBitmap = WatchUi.loadResource(Rez.Drawables.MoodBurnout) as BitmapResource;
        } else if (moodId == 3) {
            activeBitmap = WatchUi.loadResource(Rez.Drawables.MoodWired) as BitmapResource;
        } else {
            activeBitmap = WatchUi.loadResource(Rez.Drawables.MoodResting) as BitmapResource;
        }
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var width = dc.getWidth();
        var height = dc.getHeight();
        var splitY = (height * 0.3).toNumber();

        dc.setClip(0, 0, width, splitY);
        if (activeBitmap != null) {
            var bmpW = activeBitmap.getWidth();
            var bmpH = activeBitmap.getHeight();
            var bmpX = (width - bmpW) / 2;
            var bmpY = (splitY - bmpH) / 2;
            dc.drawBitmap(bmpX, bmpY, activeBitmap);
        }
        dc.clearClip();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, splitY, width, splitY);

        var textArea = new WatchUi.TextArea({
            :text => CoreQuoteEngine.activeQuote,
            :color => Graphics.COLOR_WHITE,
            :font => [Graphics.FONT_SMALL],
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => (height * 0.35).toNumber() + scrollOffset,
            :width => width - 8,
            :height => (height * 0.65).toNumber()
        });

        dc.setClip(0, splitY + 1, width, height - splitY - 1);
        textArea.draw(dc);
        dc.clearClip();

        _drawMoodLabel(dc, currentMood, width, height);
    }

    private function _drawMoodLabel(dc as Dc, moodId as Number, width as Number, height as Number) as Void {
        var labels = ["Resting", "Prime", "Burnout", "Wired"];
        var label = labels[moodId];
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 2, Graphics.FONT_XTINY, label, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onReceive(args as Dictionary?) as Void {
    }
}
