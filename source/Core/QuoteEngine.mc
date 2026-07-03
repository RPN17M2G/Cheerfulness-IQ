import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var prevQuote as String = "";

    private const QUOTES_PER_SHARD = 100;
    private const MAX_RETRIES = 5;
    private const SEP = "\x01";

    function extractQuoteFromBin(moodId as Number) as String {
        var shardCount = _getShardCount(moodId);

        for (var attempt = 0; attempt < MAX_RETRIES; attempt++) {
            var shardIdx = Math.rand() % shardCount;
            var quoteIdx = Math.rand() % QUOTES_PER_SHARD;
            var result = _readQuote(moodId, shardIdx, quoteIdx);
            if (result != null) {
                return result;
            }
        }

        return "Keep going. One day at a time.\n\n- Unknown";
    }

    private function _readQuote(moodId as Number, shardIdx as Number, quoteIdx as Number) as String? {
        var resourceSymbol = _getBinSymbol(moodId, shardIdx);
        var shardString = WatchUi.loadResource(resourceSymbol) as String;
        if (shardString == null || shardString.length() == 0) {
            return null;
        }

        var startIdx = 0;
        var currentIdx = 0;
        var searchFrom = 0;

        for (var i = 0; i <= quoteIdx; i++) {
            var sepPos = shardString.find(SEP, searchFrom);
            if (sepPos == null) {
                if (i == quoteIdx) {
                    startIdx = searchFrom;
                    currentIdx = shardString.length();
                    break;
                }
                shardString = null;
                return null;
            }
            if (i == quoteIdx) {
                startIdx = searchFrom;
                currentIdx = sepPos;
                break;
            }
            searchFrom = sepPos + 1;
        }

        var quote = shardString.substring(startIdx, currentIdx);
        shardString = null;

        if (quote == null || quote.length() == 0) {
            return null;
        }

        return quote;
    }

    private function _getShardCount(moodId as Number) as Number {
        return 2;
    }

    private function _getBinSymbol(moodId as Number, shardIdx as Number) as Symbol {
        if (moodId == 3) {
            return shardIdx == 0 ? Rez.JsonData.bin_wired_0 : Rez.JsonData.bin_wired_1;
        } else if (moodId == 1) {
            return shardIdx == 0 ? Rez.JsonData.bin_prime_0 : Rez.JsonData.bin_prime_1;
        } else if (moodId == 2) {
            return shardIdx == 0 ? Rez.JsonData.bin_burnout_0 : Rez.JsonData.bin_burnout_1;
        }
        return shardIdx == 0 ? Rez.JsonData.bin_resting_0 : Rez.JsonData.bin_resting_1;
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
