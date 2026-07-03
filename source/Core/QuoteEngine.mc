import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.StringUtil;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var prevQuote as String = "";

    function extractQuoteFromBin(moodId as Number) as String {
        var shardCount = _getShardCount(moodId);
        var shardIdx = Math.rand() % shardCount;
        var quoteIdx = Math.rand() % 100;

        var resourceSymbol = _getBinSymbol(moodId, shardIdx);
        var bytes = WatchUi.loadResource(resourceSymbol) as ByteArray;
        if (bytes == null) {
            return "Stay strong. You've got this.\n\n- Unknown";
        }

        var offsetAddr = quoteIdx * 2;
        var low = bytes[offsetAddr].toNumber();
        var high = bytes[offsetAddr + 1].toNumber();
        var startOffset = (high << 8) | low;

        if (startOffset == 0xFFFF || startOffset < 200) {
            bytes = null;
            return "Keep going. One day at a time.\n\n- Unknown";
        }

        var endOffset = 0;
        if (quoteIdx < 99) {
            var eLow = bytes[offsetAddr + 2].toNumber();
            var eHigh = bytes[offsetAddr + 3].toNumber();
            endOffset = (eHigh << 8) | eLow;
        }

        if (endOffset == 0 || endOffset == 0xFFFF) {
            endOffset = bytes.size();
        }

        var slice = bytes.slice(startOffset, endOffset - 1);
        bytes = null;

        var result = StringUtil.utf8ArrayToString(slice);
        if (result == null || result.length() == 0) {
            return "Breathe. You are exactly where you need to be.\n\n- Unknown";
        }

        return result;
    }

    private function _getShardCount(moodId as Number) as Number {
        return 2;
    }

    private function _getBinSymbol(moodId as Number, shardIdx as Number) as Symbol {
        if (moodId == 3) {
            if (shardIdx == 0) { return Rez.RawResources.bin_wired_0; }
            return Rez.RawResources.bin_wired_1;
        } else if (moodId == 1) {
            if (shardIdx == 0) { return Rez.RawResources.bin_prime_0; }
            return Rez.RawResources.bin_prime_1;
        } else if (moodId == 2) {
            if (shardIdx == 0) { return Rez.RawResources.bin_burnout_0; }
            return Rez.RawResources.bin_burnout_1;
        }
        if (shardIdx == 0) { return Rez.RawResources.bin_resting_0; }
        return Rez.RawResources.bin_resting_1;
    }

    function init(moodId as Number) as Void {
        activeQuote = extractQuoteFromBin(moodId);
        nextQuote = extractQuoteFromBin(moodId);
        prevQuote = "";
    }

    function advance(moodId as Number) as Void {
        prevQuote = activeQuote;
        activeQuote = nextQuote;
        nextQuote = extractQuoteFromBin(moodId);
    }
}
