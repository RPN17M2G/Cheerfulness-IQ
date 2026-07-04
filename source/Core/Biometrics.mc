import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.System;
import Toybox.Lang;

module CoreBiometrics {

    const STRESS_THRESHOLD = 50;
    const BODY_BATTERY_THRESHOLD = 50;
    const CHAOS_ROLL_PERCENT = 3;
    const HISTORY_PERIOD_SECONDS = 300;
    const EVALUATION_COOLDOWN_MS = 300000;

    var _wasChaotic as Boolean = false;
    var _lastEvaluatedAt as Number = 0;
    var _lastResult as Number = -1;

    function determineMood() as Number {
        var now = System.getTimer();

        if (_lastResult >= 0 && now - _lastEvaluatedAt < EVALUATION_COOLDOWN_MS) {
            return _lastResult;
        }
        _lastEvaluatedAt = now;

        var averageStress = _averageStress();
        var latestBodyBattery = _latestBodyBattery();
        var targetMood = _classifyMood(averageStress, latestBodyBattery);

        var useChaos = Math.rand() % 100 < CHAOS_ROLL_PERCENT;

        _lastResult = useChaos
            ? (targetMood + 1 + (Math.rand() % (CoreMood.COUNT - 1))) % CoreMood.COUNT
            : targetMood;
        _wasChaotic = useChaos;

        return _lastResult;
    }

    function _averageStress() as Number {
        try {
            var iterator = SensorHistory.getStressHistory({:period => HISTORY_PERIOD_SECONDS});
            var total = 0f;
            var sampleCount = 0;
            var sample = iterator.next();

            while (sample != null) {
                var dataValue = sample.data;
                if (dataValue != null) {
                    total += dataValue;
                }
                sampleCount++;
                sample = iterator.next();
            }

            return sampleCount == 0 ? STRESS_THRESHOLD : (total / sampleCount).toNumber();

        } catch (exception) {
            return STRESS_THRESHOLD;
        }
    }

    function _latestBodyBattery() as Number {
        try {
            var iterator = SensorHistory.getBodyBatteryHistory({:period => HISTORY_PERIOD_SECONDS});
            var sample = iterator.next();

            if (sample == null) { return BODY_BATTERY_THRESHOLD; }

            var dataValue = sample.data;
            return dataValue == null ? BODY_BATTERY_THRESHOLD : dataValue.toNumber();

        } catch (exception) {
            return BODY_BATTERY_THRESHOLD;
        }
    }

    function isChaotic() as Boolean {
        return _wasChaotic;
    }

    // Encodes the mood classification as a 2-bit integer where the bits represent stress and body battery.
    // Wired(3) Prime(1) Burnout(2) Resting(0)
    function _classifyMood(averageStress as Number, latestBodyBattery as Number) as Number {
        var moodBits = 0;

        if (averageStress > STRESS_THRESHOLD) {
            moodBits += 2;
        }
        if (latestBodyBattery > BODY_BATTERY_THRESHOLD) {
            moodBits += 1;
        }

        return moodBits;
    }

}
