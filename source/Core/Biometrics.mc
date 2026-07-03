import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.Lang;

module CoreBiometrics {
    const STRESS_THRESHOLD = 50;
    const BODY_BATTERY_THRESHOLD = 50;
    const CHAOS_ROLL_PERCENTAGE = 3;
    const HISTORY_PERIOD_SECONDS = 3600;

    var lastWasChaotic as Boolean = false;

    function evaluate() as Number {
        var averageStress = _getAverageStress();
        var averageBodyBattery = _getAverageBodyBattery();
        var targetMood = _classify(averageStress, averageBodyBattery);

        if (Math.rand() % 100 < CHAOS_ROLL_PERCENTAGE) {
            lastWasChaotic = true;
            return (targetMood + 1 + (Math.rand() % (CoreMood.COUNT - 1))) % CoreMood.COUNT;
        }

        lastWasChaotic = false;
        return targetMood;
    }

    function _getAverageStress() as Number {
        try {
            var iterator = SensorHistory.getStressHistory({:period => HISTORY_PERIOD_SECONDS});
            return _computeAverage(iterator);
        } catch (exception) {
            return STRESS_THRESHOLD;
        }
    }

    function _getAverageBodyBattery() as Number {
        try {
            var iterator = SensorHistory.getBodyBatteryHistory({:period => HISTORY_PERIOD_SECONDS});
            return _computeAverage(iterator);
        } catch (exception) {
            return BODY_BATTERY_THRESHOLD;
        }
    }

    function _computeAverage(iterator as SensorHistory.SensorHistoryIterator) as Number {
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
        if (sampleCount == 0) {
            return STRESS_THRESHOLD;
        }
        return (total / sampleCount).toNumber();
    }

    // Encode two booleans (stress-high?, battery-high?) as a 2-bit mood ID:
    //
    //   stress > 50   → bit 1 (weight 2)
    //   battery > 50  → bit 0 (weight 1)
    //
    //   0 = Resting  (low stress,  low battery)
    //   1 = Prime    (low stress,  high battery)
    //   2 = Burnout  (high stress, low battery)
    //   3 = Wired    (high stress, high battery)
    function _classify(averageStress as Number, averageBodyBattery as Number) as Number {
        var moodBits = 0;
        if (averageStress > STRESS_THRESHOLD) {
            moodBits += 2;
        }
        if (averageBodyBattery > BODY_BATTERY_THRESHOLD) {
            moodBits += 1;
        }
        return moodBits;
    }
}
