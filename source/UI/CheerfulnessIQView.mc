import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQView extends WatchUi.View {

    var scrollOffset as Number;
    var activeBitmap as BitmapResource?;
    var currentMoodIdentifier as Number;
    var isMoodForced as Boolean;
    var displayQuote as String;
    var needsLoad as Boolean;
    var freshOpen as Boolean;
    private const SCROLL_STEP_SIZE = 25;
    private const SCROLL_MAX_OFFSET = -600;
    private const VIEWPORT_SPLIT_RATIO = 0.3f;
    private const TEXT_AREA_START_RATIO = 0.35f;
    private const TEXT_AREA_HORIZONTAL_MARGIN = 18;
    private const BANNER_TEXT_Y = 3;
    private const BANNER_SHADOW_OFFSET = 1;
    private const CHAOS_INDICATOR_X_OFFSET = 8;
    private const CHAOS_INDICATOR_Y = 4;

    function initialize() {
        View.initialize();
        scrollOffset = 0;
        activeBitmap = null;
        currentMoodIdentifier = 0;
        isMoodForced = false;
        displayQuote = "Loading...";
        needsLoad = false;
        freshOpen = true;
    }

    function onLayout(deviceContext as Dc) as Void {
    }

    function onShow() as Void {
        if (!isMoodForced) {
            currentMoodIdentifier = CoreBiometrics.evaluate();
        }
        isMoodForced = false;

        if (freshOpen) {
            needsLoad = true;
            freshOpen = false;
            WatchUi.requestUpdate();
        } else {
            CoreQuoteEngine.initialize(currentMoodIdentifier);
            loadBitmap(currentMoodIdentifier);
            displayQuote = CoreQuoteEngine.activeQuote;
            scrollOffset = 0;
            WatchUi.requestUpdate();
        }
    }

    function onHide() as Void {
        activeBitmap = null;
        freshOpen = true;
    }

    function loadBitmap(moodIdentifier as Number) as Void {
        activeBitmap = WatchUi.loadResource(
            CoreMood.MOOD_BITMAP_RESOURCE_IDENTIFIERS[moodIdentifier]
        ) as BitmapResource;
    }

    function onUpdate(deviceContext as Dc) as Void {
        if (needsLoad) {
            CoreQuoteEngine.initialize(currentMoodIdentifier);
            loadBitmap(currentMoodIdentifier);
            displayQuote = CoreQuoteEngine.activeQuote;
            needsLoad = false;
            scrollOffset = 0;
            WatchUi.requestUpdate();
        }

        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        deviceContext.clear();

        var screenWidth = deviceContext.getWidth();
        var screenHeight = deviceContext.getHeight();
        var viewportSplitY = (screenHeight * VIEWPORT_SPLIT_RATIO).toNumber();

        deviceContext.setClip(0, 0, screenWidth, viewportSplitY);
        if (activeBitmap != null) {
            deviceContext.drawBitmap(0, 0, activeBitmap);
        }
        _drawMoodBanner(deviceContext, currentMoodIdentifier, screenWidth);
        deviceContext.clearClip();

        deviceContext.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawLine(0, viewportSplitY, screenWidth, viewportSplitY);

        var textArea = new WatchUi.TextArea({
            :text => displayQuote,
            :color => Graphics.COLOR_WHITE,
            :font => [Graphics.FONT_XTINY],
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => (screenHeight * TEXT_AREA_START_RATIO).toNumber() + scrollOffset,
            :width => screenWidth - TEXT_AREA_HORIZONTAL_MARGIN * 2,
            :height => (screenHeight * (1f - TEXT_AREA_START_RATIO)).toNumber()
        });


        deviceContext.setClip(0, viewportSplitY + 1, screenWidth, screenHeight - viewportSplitY - 1);
        textArea.draw(deviceContext);
        deviceContext.clearClip();
    }

    private function _drawMoodBanner(
        deviceContext as Dc,
        moodIdentifier as Number,
        screenWidth as Number
    ) as Void {
        var currentLabel = CoreMood.LABELS[moodIdentifier];
        var centerX = screenWidth / 2;

        deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawText(
            centerX - BANNER_SHADOW_OFFSET, BANNER_TEXT_Y,
            Graphics.FONT_SMALL, currentLabel, Graphics.TEXT_JUSTIFY_CENTER
        );
        deviceContext.drawText(
            centerX + BANNER_SHADOW_OFFSET, BANNER_TEXT_Y,
            Graphics.FONT_SMALL, currentLabel, Graphics.TEXT_JUSTIFY_CENTER
        );
        deviceContext.drawText(
            centerX, BANNER_TEXT_Y - BANNER_SHADOW_OFFSET,
            Graphics.FONT_SMALL, currentLabel, Graphics.TEXT_JUSTIFY_CENTER
        );
        deviceContext.drawText(
            centerX, BANNER_TEXT_Y + BANNER_SHADOW_OFFSET,
            Graphics.FONT_SMALL, currentLabel, Graphics.TEXT_JUSTIFY_CENTER
        );

        deviceContext.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        deviceContext.drawText(
            centerX, BANNER_TEXT_Y,
            Graphics.FONT_SMALL, currentLabel, Graphics.TEXT_JUSTIFY_CENTER
        );

        if (CoreBiometrics.lastWasChaotic) {
            deviceContext.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            deviceContext.drawText(
                screenWidth - CHAOS_INDICATOR_X_OFFSET - BANNER_SHADOW_OFFSET,
                CHAOS_INDICATOR_Y + BANNER_SHADOW_OFFSET,
                Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT
            );
            deviceContext.drawText(
                screenWidth - CHAOS_INDICATOR_X_OFFSET + BANNER_SHADOW_OFFSET,
                CHAOS_INDICATOR_Y + BANNER_SHADOW_OFFSET,
                Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT
            );
            deviceContext.drawText(
                screenWidth - CHAOS_INDICATOR_X_OFFSET,
                CHAOS_INDICATOR_Y,
                Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT
            );
            deviceContext.drawText(
                screenWidth - CHAOS_INDICATOR_X_OFFSET,
                CHAOS_INDICATOR_Y + BANNER_SHADOW_OFFSET * 2,
                Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT
            );
            deviceContext.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            deviceContext.drawText(
                screenWidth - CHAOS_INDICATOR_X_OFFSET,
                CHAOS_INDICATOR_Y + BANNER_SHADOW_OFFSET,
                Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT
            );
        }
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
        scrollOffset -= SCROLL_STEP_SIZE;
        if (scrollOffset < SCROLL_MAX_OFFSET) {
            scrollOffset = SCROLL_MAX_OFFSET;
        }
    }

    function scrollUp() as Void {
        scrollOffset += SCROLL_STEP_SIZE;
        if (scrollOffset > 0) {
            scrollOffset = 0;
        }
    }
}