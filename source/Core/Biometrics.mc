import Toybox.Application;
import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.System;
import Toybox.Time;
import Toybox.Lang;

module CoreBiometrics {

    const DEFAULT_STRESS_THRESHOLD = 50;
    const BODY_BATTERY_THRESHOLD = 50;
    const CHAOS_ROLL_PERCENT = 3;
    const STRESS_WINDOW_SECONDS = 600;
    const EVALUATION_COOLDOWN_MS = 300000;

    var _wasChaotic as Boolean = false;
    var _lastEvaluatedAt as Number = 0;
    var _lastResult as Number = -1;

    function clearCachedResult() as Void {
        _lastResult = -1;
    }

    function stressThreshold() as Number {
        var stored = Application.Storage.getValue("stressThreshold");
        if (stored == null) { return DEFAULT_STRESS_THRESHOLD; }
        if (stored instanceof Number) { return stored as Number; }
        if (stored instanceof String) { return stored.toNumber(); }
        return DEFAULT_STRESS_THRESHOLD;
    }

    function determineMood() as Number {
        var now = System.getTimer();

        if (_lastResult >= 0 && now - _lastEvaluatedAt < EVALUATION_COOLDOWN_MS) {
            return _lastResult;
        }
        _lastEvaluatedAt = now;

        var isStressHigh = _isStressHigh();
        var latestBodyBattery = _latestBodyBattery();
        var targetMood = _classifyMood(isStressHigh, latestBodyBattery);

        var useChaos = Math.rand() % 100 < CHAOS_ROLL_PERCENT;

        _lastResult = useChaos
            ? (targetMood + 1 + (Math.rand() % (CoreMood.COUNT - 1))) % CoreMood.COUNT
            : targetMood;
        _wasChaotic = useChaos;

        return _lastResult;
    }

    function _isStressHigh() as Boolean {
        try {
            var iterator = SensorHistory.getStressHistory({});
            if (iterator == null) { return false; }

            var total = 0f;
            var count = 0;
            var cutoff = Time.now().value() - STRESS_WINDOW_SECONDS;
            var threshold = stressThreshold();

            var sample = iterator.next();
            while (sample != null) {
                var timestamp = sample.when.value();
                if (timestamp < cutoff) { break; }

                var value = sample.data;
                if (value != null) {
                    total += value;
                    count++;
                }
                sample = iterator.next();
            }

            if (count == 0) { return false; }

            return (total / count) > threshold;

        } catch (exception) {
            return false;
        }
    }

    function _latestBodyBattery() as Number {
        try {
            var iterator = SensorHistory.getBodyBatteryHistory({:period => 1});
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
    function _classifyMood(isStressHigh as Boolean, latestBodyBattery as Number) as Number {
        var moodBits = 0;

        if (isStressHigh) {
            moodBits += 2;
        }
        if (latestBodyBattery > BODY_BATTERY_THRESHOLD) {
            moodBits += 1;
        }

        return moodBits;
    }

}
