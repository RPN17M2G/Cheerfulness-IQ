import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.System;
import Toybox.Lang;

module CoreBiometrics {
    const STRESS_THRESHOLD = 50;
    const BODY_BATTERY_THRESHOLD = 50;
    const CHAOS_ROLL_PERCENTAGE = 3;
    const HISTORY_PERIOD_SECONDS = 300;
    const EVALUATION_COOLDOWN_MS = 300000;

    var lastWasChaotic as Boolean = false;
    var lastEvaluationTime as Number = 0;
    var lastEvaluationResult as Number = -1;

    function evaluate() as Number {
        var now = System.getTimer();
        if (lastEvaluationResult >= 0 && now - lastEvaluationTime < EVALUATION_COOLDOWN_MS) {
            return lastEvaluationResult;
        }
        lastEvaluationTime = now;

        var averageStress = _getAverageStress();
        var latestBodyBattery = _getLatestBodyBattery();
        var targetMood = _classify(averageStress, latestBodyBattery);
        var useChaos = Math.rand() % 100 < CHAOS_ROLL_PERCENTAGE;

        lastEvaluationResult = useChaos
            ? (targetMood + 1 + (Math.rand() % (CoreMood.COUNT - 1))) % CoreMood.COUNT
            : targetMood;
        lastWasChaotic = useChaos;
        return lastEvaluationResult;
    }

    function _getAverageStress() as Number {
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

    function _getLatestBodyBattery() as Number {
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

    function _classify(averageStress as Number, latestBodyBattery as Number) as Number {
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
