import Toybox.Lang;

module CoreMood {
    const RESTING = 0;
    const PRIME = 1;
    const BURNOUT = 2;
    const WIRED = 3;
    const COUNT = 4;

    const LABELS = ["Resting", "Prime", "Burnout", "Wired"];
    const MOOD_BITMAPS = [
        Rez.Drawables.MoodResting,
        Rez.Drawables.MoodPrime,
        Rez.Drawables.MoodBurnout,
        Rez.Drawables.MoodWired
    ];
}
