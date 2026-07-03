import Toybox.SensorHistory;
import Toybox.Math;
import Toybox.System;

module CoreBiometrics {
    function evaluate() as Number {
        var stressIterator = SensorHistory.getStressHistory({:period => 1});
        var bbIterator = SensorHistory.getBodyBatteryHistory({:period => 1});

        var stressSum = 0;
        var stressCount = 0;
        var sample = stressIterator.next();
        while (sample != null) {
            stressSum += sample.data;
            stressCount++;
            sample = stressIterator.next();
        }

        var bbSum = 0;
        var bbCount = 0;
        sample = bbIterator.next();
        while (sample != null) {
            bbSum += sample.data;
            bbCount++;
            sample = bbIterator.next();
        }

        var avgStress = stressCount > 0 ? stressSum / stressCount : 50;
        var avgBodyBattery = bbCount > 0 ? bbSum / bbCount : 50;

        var targetMood = 0;
        if (avgStress > 50 && avgBodyBattery > 50) {
            targetMood = 3;
        } else if (avgStress <= 50 && avgBodyBattery > 50) {
            targetMood = 1;
        } else if (avgStress > 50 && avgBodyBattery <= 50) {
            targetMood = 2;
        }

        if (Math.rand() % 100 < 3) {
            return (targetMood + 1 + (Math.rand() % 3)) % 4;
        }

        return targetMood;
    }
}
