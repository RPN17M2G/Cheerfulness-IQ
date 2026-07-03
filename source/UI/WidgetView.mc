import Toybox.WatchUi;
import Toybox.Graphics;
import Toybox.Lang;

class CheerfulnessIQView extends WatchUi.View {

    var scrollOffset as Number;
    var activeBitmap as BitmapResource?;
    var currentMood as Number;
    var moodForced as Boolean;

    private const SCROLL_STEP = 25;
    private const SCROLL_MIN = -800;

    function initialize() {
        View.initialize();
        scrollOffset = 0;
        activeBitmap = null;
        currentMood = 0;
        moodForced = false;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        if (!moodForced) {
            currentMood = CoreBiometrics.evaluate();
        }
        moodForced = false;
        CoreQuoteEngine.init(currentMood);
        loadBitmap(currentMood);
        scrollOffset = 0;
        WatchUi.requestUpdate();
    }

    function onHide() as Void {
        activeBitmap = null;
    }

    function loadBitmap(moodId as Number) as Void {
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
            dc.drawBitmap(0, 0, activeBitmap);
        }
        _drawMoodBanner(dc, currentMood, width, splitY);
        dc.clearClip();

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, splitY, width, splitY);

        var textArea = new WatchUi.TextArea({
            :text => CoreQuoteEngine.activeQuote,
            :color => Graphics.COLOR_WHITE,
            :font => [Graphics.FONT_XTINY],
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => (height * 0.35).toNumber() + scrollOffset,
            :width => width - 36,
            :height => (height * 0.65).toNumber()
        });

        dc.setClip(0, splitY + 1, width, height - splitY - 1);
        textArea.draw(dc);
        dc.clearClip();
    }

    private function _drawMoodBanner(dc as Dc, moodId as Number, width as Number, splitY as Number) as Void {
        var labels = ["Resting", "Prime", "Burnout", "Wired"];
        var label = labels[moodId];
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, 20);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(width / 2, 2, Graphics.FONT_SMALL, label, Graphics.TEXT_JUSTIFY_CENTER);
        if (CoreBiometrics.lastWasChaotic) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(width - 8, 3, Graphics.FONT_XTINY, "~", Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    function clampScrollOffset() as Void {
        if (scrollOffset > 0) {
            scrollOffset = 0;
        }
        if (scrollOffset < SCROLL_MIN) {
            scrollOffset = SCROLL_MIN;
        }
    }

    function scrollDown() as Void {
        scrollOffset -= SCROLL_STEP;
        if (scrollOffset < SCROLL_MIN) {
            scrollOffset = SCROLL_MIN;
        }
    }

    function scrollUp() as Void {
        scrollOffset += SCROLL_STEP;
        if (scrollOffset > 0) {
            scrollOffset = 0;
        }
    }
}
