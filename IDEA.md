# IDEA.md — Cheerfulness IQ (Garmin Bio-Adaptive Widget)

## 1. Product Overview
**Cheerfulness IQ** is a native Garmin Connect IQ wearable widget that delivers biometrically aware, contextual mindset shifts. Unlike generic quote apps that randomize static text arrays or depend on constant phone connectivity, Cheerfulness IQ runs an offline, memory-optimized engine that analyzes the user's real-time **Heart Rate Variability (Stress Score)** and **Body Battery** telemetry to serve quotes and atmosphere imagery precisely aligned with their current physiological state.

## 2. Core Value Proposition
* **True Physiological Alignment:** Categorizes the nervous system into four domain quadrants (`Wired`, `Prime`, `Burnout`, `Resting`). If the user is exhausted, it serves grounding, resilient stoicism—never toxic positivity or tone-deaf high-intensity drilling.
* **Massive Offline Scale (30,000+ Quotes):** Built on an indexed raw binary sharding architecture (`.bin`), allowing years of daily use without internet, Bluetooth, or repeats.
* **Zero Battery & Memory Bloat:** Runs strict lazy evaluation on widget mount (`onShow`). No active background processes, zero heap fragmentation, and total live RAM consumption stays below ~45KB inside constrained Garmin watches (64KB–128KB limits).

## 3. Physiological Domain Quadrants (The 2D Matrix)
The engine reads `Toybox.ActivityMonitor` and evaluates:
1. ⚡ **WIRED (`Stress > 50` && `BB > 50`):** High nervous system load paired with high physical capacity.
   * *Content Tone:* Tactical, sharp, execution-focused, channeling intensity.
2. 🌿 **PRIME (`Stress <= 50` && `BB > 50`):** Low nervous system load paired with high capacity.
   * *Content Tone:* Expansive, proactive, visionary, big-picture growth.
3. ⚓ **BURNOUT (`Stress > 50` && `BB <= 50`):** High nervous system load paired with physical deficit.
   * *Content Tone:* Grounding, stoic, resilient, self-compassionate, focus on the immediate step.
4. 🌙 **RESTING (`Stress <= 50` && `BB <= 50`):** Low load, low capacity.
   * *Content Tone:* Restorative, calm, peaceful, validating effort.

*IMPORTANT: Because we use api level 5.0.0 we can access the history of stress and body battery, calculate an average of the last hour and decide with that.*

*Note: The engine includes a **3% Chaos Roll** (`rand() % 100 < 3`) that overrides the computed quadrant with a randomized alternate state to introduce cognitive friction and fresh perspectives.*

## 4. UI Layout & UX Mechanics
* **Spatial Split:** Optimized for circular displays. The top **30%** renders a high-contrast, clipped mood atmosphere bitmap. A 1px divider separates it from the bottom **70%**, which renders a centered, auto-wrapping text body (`WatchUi.TextArea`).
* **Hardware Scrolling:** Physical UP/DOWN keys manipulate the vertical text offset directly (`scrollOffset ±20px`), allowing full reading of long quotes without letting the OS swipe to adjacent widgets.
* **Manual Override & Cooldown:** Physical SELECT key pushes an Action Menu (`Menu2`) offering instant quote advances, manual mood forcing, and an optional **1-Hour Cooldown Toggle** backed by persistent flash storage (`Application.Storage`).