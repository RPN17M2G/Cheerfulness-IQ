import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.StringUtil;
import Toybox.Math;

module CoreQuoteEngine {
    var activeQuote as String = "";
    var nextQuote as String = "";
    var prevQuote as String = "";

    private const QUOTES_PER_SHARD = 100;
    private const HEADER_SIZE = 200;
    private const EMPTY_SLOT = 0xFFFF;
    private const MAX_RETRIES = 5;

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
        var bytes = WatchUi.loadResource(resourceSymbol) as ByteArray;
        if (bytes == null) {
            return null;
        }

        var offsetAddr = quoteIdx * 2;
        var startOffset = _readUint16LE(bytes, offsetAddr);

        if (startOffset == EMPTY_SLOT || startOffset < HEADER_SIZE) {
            bytes = null;
            return null;
        }

        var endOffset = EMPTY_SLOT;
        if (quoteIdx < QUOTES_PER_SHARD - 1) {
            endOffset = _readUint16LE(bytes, offsetAddr + 2);
        }

        if (endOffset == EMPTY_SLOT) {
            endOffset = bytes.size();
        }

        var slice = bytes.slice(startOffset, endOffset - 1);
        bytes = null;

        var result = StringUtil.utf8ArrayToString(slice);
        if (result == null || result.length() == 0) {
            return null;
        }

        return result;
    }

    private function _readUint16LE(bytes as ByteArray, addr as Number) as Number {
        var lo = bytes[addr].toNumber();
        var hi = bytes[addr + 1].toNumber();
        return (hi << 8) | lo;
    }

    private function _getShardCount(moodId as Number) as Number {
        return 2;
    }

    private function _getBinSymbol(moodId as Number, shardIdx as Number) as Symbol {
        if (moodId == 3) {
            return shardIdx == 0 ? Rez.RawResources.bin_wired_0 : Rez.RawResources.bin_wired_1;
        } else if (moodId == 1) {
            return shardIdx == 0 ? Rez.RawResources.bin_prime_0 : Rez.RawResources.bin_prime_1;
        } else if (moodId == 2) {
            return shardIdx == 0 ? Rez.RawResources.bin_burnout_0 : Rez.RawResources.bin_burnout_1;
        }
        return shardIdx == 0 ? Rez.RawResources.bin_resting_0 : Rez.RawResources.bin_resting_1;
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
