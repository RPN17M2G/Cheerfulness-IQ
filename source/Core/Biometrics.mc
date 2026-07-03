import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.Lang;

module CoreBiometrics {
    const STRESS_THRESHOLD = 50;
    const BB_THRESHOLD = 50;
    const CHAOS_ROLL_PCT = 3;
    const HISTORY_PERIOD_SECS = 3600;

    var lastWasChaotic as Boolean = false;

    function evaluate() as Number {
        var avgStress = _getAverageStress();
        var avgBodyBattery = _getAverageBodyBattery();
        var targetMood = _classify(avgStress, avgBodyBattery);

        if (Math.rand() % 100 < CHAOS_ROLL_PCT) {
            lastWasChaotic = true;
            return (targetMood + 1 + (Math.rand() % 3)) % 4;
        }

        lastWasChaotic = false;
        return targetMood;
    }

    function _getAverageStress() as Number {
        try {
            var iterator = SensorHistory.getStressHistory({:period => HISTORY_PERIOD_SECS});
            if (iterator == null) {
                return STRESS_THRESHOLD;
            }
            return _computeAverage(iterator);
        } catch (ex) {
            return STRESS_THRESHOLD;
        }
    }

    function _getAverageBodyBattery() as Number {
        try {
            var iterator = SensorHistory.getBodyBatteryHistory({:period => HISTORY_PERIOD_SECS});
            if (iterator == null) {
                return BB_THRESHOLD;
            }
            return _computeAverage(iterator);
        } catch (ex) {
            return BB_THRESHOLD;
        }
    }

    function _computeAverage(iterator as SensorHistory.SensorHistoryIterator) as Number {
        var sum = 0f;
        var count = 0;
        var sample = iterator.next();
        while (sample != null) {
            if (sample.data != null) {
                sum += sample.data;
            }
            count++;
            sample = iterator.next();
        }
        if (count == 0) {
            return STRESS_THRESHOLD;
        }
        return (sum / count).toNumber();
    }

    function _classify(avgStress as Number, avgBB as Number) as Number {
        if (avgStress > STRESS_THRESHOLD && avgBB > BB_THRESHOLD) {
            return 3;
        }
        if (avgStress <= STRESS_THRESHOLD && avgBB > BB_THRESHOLD) {
            return 1;
        }
        if (avgStress > STRESS_THRESHOLD && avgBB <= BB_THRESHOLD) {
            return 2;
        }
        return 0;
    }
}
