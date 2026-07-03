import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

(:glance)
class CheerfulnessIQGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(deviceContext as Dc) as Void {
        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        deviceContext.clear();
        deviceContext.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawText(
            8,
            deviceContext.getHeight() / 2,
            Graphics.FONT_XTINY,
            "Cheerfulness",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}
