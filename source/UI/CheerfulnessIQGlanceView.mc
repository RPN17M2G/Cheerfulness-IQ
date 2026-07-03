import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQGlanceView extends WatchUi.GlanceView {

    function onUpdate(deviceContext as Dc) as Void {
        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        deviceContext.clear();

        deviceContext.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var label = "Cheerfulness";
        deviceContext.drawText(
            deviceContext.getWidth() / 2,
            deviceContext.getHeight() / 2,
            Graphics.FONT_GLANCE,
            label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }
}