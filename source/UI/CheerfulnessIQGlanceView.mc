import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = 16;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy - 4, r);

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.fillCircle(cx - 5, cy - 7, 3);
        dc.fillCircle(cx + 5, cy - 7, 3);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy + 1, 8, Graphics.ARC_CLOCKWISE, 340, 200);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + r + 4, Graphics.FONT_XTINY, "CIQ", Graphics.TEXT_JUSTIFY_CENTER);
    }
}
