import Toybox.Application;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var previousQuote as String = "";
    var lastMoodIdentifier as Number = -1;

    const QUOTES_PER_SHARD = 100;
    const MAXIMUM_RETRIES = 3;

    function extractQuoteFromBin(moodIdentifier as Number) as String {
        var moodShardCount = CoreShardIndex.MOOD_SHARD_COUNTS[moodIdentifier] as Number;

        for (var attempt = 0; attempt < MAXIMUM_RETRIES; attempt++) {
            var shardIndex = Math.rand() % moodShardCount;
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

        var separator = "\n|\n";

        var startPos = 0;
        for (var i = 0; i < quoteIndex; i++) {
            var remainder = shardData.substring(startPos, shardData.length());
            if (remainder == null) { break; }
            var found = remainder.find(separator);
            if (found == null) { break; }
            startPos = startPos + found + 3;
        }

        var remainder = shardData.substring(startPos, shardData.length());
        if (remainder == null) { return null; }
        var endFound = remainder.find(separator);
        var endPos = endFound != null ? startPos + endFound : shardData.length();

        var quote = shardData.substring(startPos, endPos);
        shardData = null;

        if (quote == null || quote.length() == 0) {
            return null;
        }

        return quote;
    }

    function initialize(moodIdentifier as Number) as Void {
        if (moodIdentifier == lastMoodIdentifier && activeQuote.length() > 0) {
            return;
        }
        var storedMood = Application.Storage.getValue("lastMoodIdentifier");
        if (storedMood != null && storedMood == moodIdentifier) {
            var storedQuote = Application.Storage.getValue("activeQuote");
            if (storedQuote != null && storedQuote.toString().length() > 0) {
                activeQuote = storedQuote.toString();
                lastMoodIdentifier = moodIdentifier;
                return;
            }
        }
        lastMoodIdentifier = moodIdentifier;
        activeQuote = extractQuoteFromBin(moodIdentifier);
        Application.Storage.setValue("lastMoodIdentifier", moodIdentifier);
        Application.Storage.setValue("activeQuote", activeQuote);
        nextQuote = "";
        previousQuote = "";
    }

    function advance(moodIdentifier as Number) as Void {
        lastMoodIdentifier = moodIdentifier;
        previousQuote = activeQuote;
        if (nextQuote.length() > 0) {
            activeQuote = nextQuote;
        } else {
            activeQuote = extractQuoteFromBin(moodIdentifier);
        }
        nextQuote = extractQuoteFromBin(moodIdentifier);
        Application.Storage.setValue("lastMoodIdentifier", moodIdentifier);
        Application.Storage.setValue("activeQuote", activeQuote);
    }
}
