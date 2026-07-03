import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQView extends WatchUi.View {

    var scrollOffset as Number;
    var activeBitmap as BitmapResource?;
    var moodId as Number;
    var isMoodForced as Boolean;
    var displayQuote as String;

    private const SCROLL_STEP = 25;
    private const SCROLL_MAX_OFFSET = -600;
    private const VIEWPORT_SPLIT_RATIO = 0.3f;
    private const TEXT_AREA_TOP_RATIO = 0.35f;
    private const TEXT_AREA_HORIZONTAL_MARGIN = 18;
    private const BANNER_TEXT_Y = 3;
    private const SHADOW_OFFSET = 1;
    private const CHAOS_INDICATOR_RIGHT_MARGIN = 8;
    private const CHAOS_INDICATOR_Y = 4;

    function initialize() {
        View.initialize();
        scrollOffset = 0;
        activeBitmap = null;
        moodId = 0;
        isMoodForced = false;
        displayQuote = "Loading...";
    }

    function onLayout(deviceContext as Dc) as Void {
    }

    function onShow() as Void {
        if (!isMoodForced) {
            moodId = CoreBiometrics.determineMood();
        }
        isMoodForced = false;

        CoreQuoteEngine.initialize(moodId);
        loadBitmap(moodId);
        displayQuote = CoreQuoteEngine.activeQuote;
        scrollOffset = 0;
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        activeBitmap = null;
    }

    function loadBitmap(moodIdentifier as Number) as Void {
        activeBitmap = WatchUi.loadResource(
            CoreMood.MOOD_BITMAPS[moodIdentifier]
        ) as BitmapResource;
    }

    function onUpdate(deviceContext as Dc) as Void {
        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        deviceContext.clear();

        var screenWidth = deviceContext.getWidth();
        var screenHeight = deviceContext.getHeight();
        var splitY = (screenHeight * VIEWPORT_SPLIT_RATIO).toNumber();

        deviceContext.setClip(0, 0, screenWidth, splitY);

        if (activeBitmap != null) {
            deviceContext.drawBitmap(0, 0, activeBitmap);
        }
        drawMoodBanner(deviceContext, screenWidth);
        deviceContext.clearClip();

        deviceContext.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawLine(0, splitY, screenWidth, splitY);

        var textArea = new WatchUi.TextArea({
            :text => displayQuote,
            :color => Graphics.COLOR_WHITE,
            :font => [Graphics.FONT_XTINY],
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => (screenHeight * TEXT_AREA_TOP_RATIO).toNumber() + scrollOffset,
            :width => screenWidth - TEXT_AREA_HORIZONTAL_MARGIN * 2,
            :height => (screenHeight * (1f - TEXT_AREA_TOP_RATIO)).toNumber()
        });

        deviceContext.setClip(0, splitY + 1, screenWidth, screenHeight - splitY - 1);
        textArea.draw(deviceContext);
        deviceContext.clearClip();
    }

    private function drawMoodBanner(
        deviceContext as Dc,
        screenWidth as Number
    ) as Void {
        var label = CoreMood.LABELS[moodId];
        var centerX = screenWidth / 2;

        drawShadowedText(
            deviceContext, centerX, BANNER_TEXT_Y,
            Graphics.FONT_SMALL, label,
            Graphics.COLOR_WHITE, Graphics.COLOR_BLACK,
            false
        );

        if (CoreBiometrics.isChaotic()) {
            drawShadowedText(
                deviceContext,
                screenWidth - CHAOS_INDICATOR_RIGHT_MARGIN,
                CHAOS_INDICATOR_Y,
                Graphics.FONT_XTINY, "~",
                Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK,
                true
            );
        }
    }

    private function drawShadowedText(
        deviceContext as Dc,
        x as Number, y as Number,
        font as FontDefinition, text as String,
        foregroundColor as Number, shadowColor as Number,
        rightAligned as Boolean
    ) as Void {
        var justifyFlag = rightAligned
            ? Graphics.TEXT_JUSTIFY_RIGHT
            : Graphics.TEXT_JUSTIFY_CENTER;

        deviceContext.setColor(shadowColor, Graphics.COLOR_TRANSPARENT);

        for (var dx = -SHADOW_OFFSET; dx <= SHADOW_OFFSET; dx += SHADOW_OFFSET) {
            for (var dy = -SHADOW_OFFSET; dy <= SHADOW_OFFSET; dy += SHADOW_OFFSET) {
                if (dx == 0 && dy == 0) { continue; }
                deviceContext.drawText(x + dx, y + dy, font, text, justifyFlag);
            }
        }

        deviceContext.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawText(x, y, font, text, justifyFlag);
    }

    function clampScrollOffset() as Void {
        if (scrollOffset > 0) {
            scrollOffset = 0;
        }
        if (scrollOffset < SCROLL_MAX_OFFSET) {
            scrollOffset = SCROLL_MAX_OFFSET;
        }
    }

    function scrollDown() as Void {
        scrollOffset -= SCROLL_STEP;

        if (scrollOffset < SCROLL_MAX_OFFSET) {
            scrollOffset = SCROLL_MAX_OFFSET;
        }
    }

    function scrollUp() as Void {
        scrollOffset += SCROLL_STEP;

        if (scrollOffset > 0) {
            scrollOffset = 0;
        }
    }
}
