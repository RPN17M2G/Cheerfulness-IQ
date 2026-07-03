import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var previousQuote as String = "";

    const QUOTES_PER_SHARD = 100;
    const MAXIMUM_RETRIES = 5;
    const QUOTE_SEPARATOR = "\n|\n";
    const QUOTE_SEPARATOR_LENGTH = 3;

    function extractQuoteFromBin(moodIdentifier as Number) as String {
        var shardCount = CoreShardIndex.SHARD_COUNT;

        for (var attempt = 0; attempt < MAXIMUM_RETRIES; attempt++) {
            var shardIndex = Math.rand() % shardCount;
            var quoteIndex = Math.rand() % QUOTES_PER_SHARD;
            var result = _readQuote(moodIdentifier, shardIndex, quoteIndex);
            if (result != null) {
                return result;
            }
        }

        return "Keep going. One day at a time.\n\n- Unknown";
    }

    function _readQuote(moodIdentifier as Number, shardIndex as Number, quoteIndex as Number) as String? {
        var shardRow = CoreShardIndex.SHARD_IDS[moodIdentifier] as Array<ResourceId>;
        var resourceIdentifier = shardRow[shardIndex];
        var shardData = WatchUi.loadResource(resourceIdentifier) as String;
        if (shardData == null || shardData.length() == 0) {
            return null;
        }

        var startIndex = 0;
        var currentIndex = 0;
        var searchPosition = 0;

        for (var positionInShard = 0; positionInShard <= quoteIndex; positionInShard++) {
            var searchSlice = shardData.substring(searchPosition, shardData.length());
            var found = searchSlice != null ? searchSlice.find(QUOTE_SEPARATOR) : null;
            var separatorPosition = found != null ? searchPosition + found : null;
            if (separatorPosition == null) {
                if (positionInShard == quoteIndex) {
                    startIndex = searchPosition;
                    currentIndex = shardData.length();
                    break;
                }
                shardData = null;
                return null;
            }
            if (positionInShard == quoteIndex) {
                startIndex = searchPosition;
                currentIndex = separatorPosition;
                break;
            }
            searchPosition = separatorPosition + QUOTE_SEPARATOR_LENGTH;
        }

        var quote = shardData.substring(startIndex, currentIndex);
        shardData = null;

        if (quote == null || quote.length() == 0) {
            return null;
        }

        return quote;
    }

    function initialize(moodIdentifier as Number) as Void {
        activeQuote = extractQuoteFromBin(moodIdentifier);
        nextQuote = extractQuoteFromBin(moodIdentifier);
        previousQuote = "";
    }

    function advance(moodIdentifier as Number) as Void {
        previousQuote = activeQuote;
        activeQuote = nextQuote;
        nextQuote = extractQuoteFromBin(moodIdentifier);
    }
}
