import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQGlanceView extends WatchUi.GlanceView {

    private const FACE_RADIUS = 16;
    private const FACE_CENTER_Y_OFFSET = -4;
    private const EYE_RADIUS = 3;
    private const EYE_HORIZONTAL_OFFSET = 5;
    private const EYE_VERTICAL_OFFSET = -7;
    private const MOUTH_RADIUS = 8;
    private const MOUTH_CENTER_Y_OFFSET = 1;
    private const MOUTH_START_ANGLE = 340;
    private const MOUTH_END_ANGLE = 200;
    private const LABEL_VERTICAL_OFFSET = 4;

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(deviceContext as Dc) as Void {
        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        deviceContext.clear();

        var centerX = deviceContext.getWidth() / 2;
        var centerY = deviceContext.getHeight() / 2;

        deviceContext.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawCircle(centerX, centerY + FACE_CENTER_Y_OFFSET, FACE_RADIUS);

        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        deviceContext.fillCircle(
            centerX - EYE_HORIZONTAL_OFFSET, centerY + EYE_VERTICAL_OFFSET, EYE_RADIUS
        );
        deviceContext.fillCircle(
            centerX + EYE_HORIZONTAL_OFFSET, centerY + EYE_VERTICAL_OFFSET, EYE_RADIUS
        );

        deviceContext.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawArc(
            centerX, centerY + MOUTH_CENTER_Y_OFFSET, MOUTH_RADIUS,
            Graphics.ARC_CLOCKWISE, MOUTH_START_ANGLE, MOUTH_END_ANGLE
        );

        deviceContext.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawText(
            centerX, centerY + FACE_RADIUS + LABEL_VERTICAL_OFFSET,
            Graphics.FONT_XTINY, "CIQ", Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}
