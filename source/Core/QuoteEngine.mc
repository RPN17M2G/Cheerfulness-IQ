import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var prevQuote as String = "";

    const QUOTES_PER_SHARD = 100;
    const MAX_RETRIES = 5;
    const SEP = "\n|\n";
    const SEP_LEN = 3;

    function extractQuoteFromBin(moodId as Number) as String {
        var shardCount = CoreShardIndex.SHARD_COUNT;

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

    function _readQuote(moodId as Number, shardIdx as Number, quoteIdx as Number) as String? {
        var row = CoreShardIndex.SHARD_IDS[moodId] as Array<ResourceId>;
        var resId = row[shardIdx];
        var shardString = WatchUi.loadResource(resId) as String;
        if (shardString == null || shardString.length() == 0) {
            return null;
        }

        var startIdx = 0;
        var currentIdx = 0;
        var searchFrom = 0;

        for (var i = 0; i <= quoteIdx; i++) {
            var searchStr = shardString.substring(searchFrom, shardString.length());
            var found = searchStr != null ? searchStr.find(SEP) : null;
            var sepPos = found != null ? searchFrom + found : null;
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
            searchFrom = sepPos + SEP_LEN;
        }

        var quote = shardString.substring(startIdx, currentIdx);
        shardString = null;

        if (quote == null || quote.length() == 0) {
            return null;
        }

        return quote;
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
