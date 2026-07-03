import Toybox.SensorHistory;
import Toybox.Math;

module CoreBiometrics {
    private const STRESS_THRESHOLD = 50;
    private const BB_THRESHOLD = 50;
    private const CHAOS_ROLL_PCT = 3;
    private const HISTORY_PERIOD_SECS = 3600;

    function evaluate() as Number {
        var avgStress = _getAverageStress();
        var avgBodyBattery = _getAverageBodyBattery();
        var targetMood = _classify(avgStress, avgBodyBattery);

        if (Math.rand() % 100 < CHAOS_ROLL_PCT) {
            return (targetMood + 1 + (Math.rand() % 3)) % 4;
        }

        return targetMood;
    }

    private function _getAverageStress() as Number {
        try {
            var iterator = SensorHistory.getStressHistory({:period => HISTORY_PERIOD_SECS});
            if (iterator == null) {
                return STRESS_THRESHOLD;
            }
            return _computeAverage(iterator);
        } catch (ex instanceof Exception) {
            return STRESS_THRESHOLD;
        }
    }

    private function _getAverageBodyBattery() as Number {
        try {
            var iterator = SensorHistory.getBodyBatteryHistory({:period => HISTORY_PERIOD_SECS});
            if (iterator == null) {
                return BB_THRESHOLD;
            }
            return _computeAverage(iterator);
        } catch (ex instanceof Exception) {
            return BB_THRESHOLD;
        }
    }

    private function _computeAverage(iterator as SensorHistory.SensorHistoryIterator) as Number {
        var sum = 0;
        var count = 0;
        var sample = iterator.next();
        while (sample != null) {
            sum += sample.data;
            count++;
            sample = iterator.next();
        }
        if (count == 0) {
            return STRESS_THRESHOLD;
        }
        return sum / count;
    }

    private function _classify(avgStress as Number, avgBB as Number) as Number {
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
