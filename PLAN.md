# PLAN.md — Execution Plan for Cheerfulness IQ

## ⚠️ STRICT RULES FOR THE AI IMPLEMENTING AGENT
1. **MEMORY LAWS:** You are writing for an embedded environment with a **64KB Heap Limit**. DO NOT use `WatchUi.loadResource()` on JSON files. Do not build OOP class hierarchies. Use **Static Modules** (`module Core { ... }`) and raw byte array slicing (`.bin`).
2. **ZERO MEMORY LEAKS:** Whenever a `ByteArray` or `Resource` is loaded into a local variable for extraction, you MUST explicitly assign that variable to `null` before exiting the function scope so the reference-counting garbage collector reclaims the RAM instantly.
3. **DO NOT PLACEHOLDER:** Write complete, compilable Monkey C (`.mc`) and Python code. Do not output comments like `// add logic here`.

---

## Phase 1: Environment Setup & Directory Structure
Create the exact file skeleton required for a modern Connect IQ SDK project.

### Tasks:
- [ ] Initialize project directories: `source/`, `source/Core/`, `source/UI/`, `resources/`, `resources/drawables/`, `resources/bin/`, and `scripts/`.
- [ ] Create `manifest.xml` targeting Connect IQ SDK 4.0.0+ with permissions `<iq:uses-permission id="FitnessAndSensorData"/>`. Add modern circular AMOLED and MIP devices to compatible targets (e.g., `fenix7`, `forerunner965`, `epix2`).

---

## Phase 2: Offline Data Pipeline (`scripts/build_shards.py`)
Because Connect IQ crashes when loading large JSON files into heap memory, build the offline Python script that compiles raw text quotes into indexed, null-terminated raw binary shards (`.bin`).

### Tasks:
- [ ] Create `scripts/build_shards.py`.
- [ ] Implement data ingestion capable of taking a raw CSV/JSON list of categorized quotes (or generate a realistic mock dataset of 400 quotes across the 4 moods for initial development testing).
- [ ] Implement binary packing logic:
  - Each shard (`.bin`) holds exactly 100 quotes.
  - **Header Block (Bytes 0–199):** Write 100 unsigned 16-bit little-endian integers (`<H` struct format). Each integer is the exact byte offset where quote `i` starts inside the payload block.
  - **Payload Block (Bytes 200+):** Write each quote string formatted as `Quote Text + "\n\n- " + Author + "\0"` encoded in UTF-8.
- [ ] Have the script save shards into `resources/bin/` named as `bin_0_0.bin` (`bin_<moodId>_<shardIndex>.bin`).
- [ ] Have the script auto-generate `resources/resources.xml` declaring all `<rawResource id="bin_0_0" filename="bin/bin_0_0.bin" />` and 4 mood background bitmaps `<bitmap id="mood_img_0" filename="drawables/resting.png" />`.
- [ ] **Verification Gate:** Run `python scripts/build_shards.py` and inspect output `.bin` files to ensure header offsets match exact byte lengths.

---

## Phase 3: Core Domain Modules (`source/Core/`)
Implement static modules for biometrics, settings, and look-ahead quote extraction.

### Tasks:
- [ ] **Create `source/Core/Settings.mc`:**
  - Wrap `Toybox.Application.Storage`.
  - Implement `getCooldownEnabled() as Boolean`, `setCooldownEnabled(val as Boolean) as Void`, and `canSwapQuote() as Boolean`.
  - `canSwapQuote()` returns `true` if cooldown is disabled OR if `Time.now().value() - Storage.getValue("last_swap") >= 3600`.
- [ ] **Create `source/Core/Biometrics.mc`:**
  - Read `ActivityMonitor.getStressHistory(1, false)` and `getBodyBatteryHistory({:period => 1})`.
  - Return `0` (Resting), `1` (Prime), `2` (Burnout), or `3` (Wired) based on the 50/50 quadrant matrix.
  - Apply the `3% Chaos Roll`: If `Math.rand() % 100 < 3`, return `(target + 1 + (Math.rand() % 3)) % 4`.
- [ ] **Create `source/Core/QuoteEngine.mc`:**
  - State variables: `activeQuote as String`, `nextQuote as String`.
  - Implement `extractQuoteFromBin(moodId as Number) as String`:
    1. Roll random shard index and quote index (`0-99`).
    2. Load raw `ByteArray` via `WatchUi.loadResource()`.
    3. Read 16-bit header offsets at `index * 2` and `(index + 1) * 2`.
    4. Slice string payload via `bytes.slice(start, end - 1)` and convert via `StringUtil.utf8ArrayToString()`.
    5. **CRITICAL:** Set `bytes = null;` immediately before returning string.
  - Implement look-ahead buffer methods: `init(moodId)` and `advance(moodId)`.

---

## Phase 4: Presentation & UI Layer (`source/UI/`)
Build the 30/70 viewport renderer, scrolling controls, and action menu.

### Tasks:
- [ ] **Create `source/UI/WidgetView.mc` (`WatchUi.View`):**
  - State: `scrollOffset as Number = 0`, `activeBitmap as BitmapResource?`.
  - `onShow()`: Call `Biometrics.evaluate()`, load mood bitmap, call `QuoteEngine.init(mood)`.
  - `onUpdate(dc)`:
    1. `dc.clear()` to black.
    2. Set top 30% clip region (`dc.setClip(0, 0, width, height * 0.3)`). Draw `activeBitmap` centered horizontally. `dc.clearClip()`.
    3. Draw 1px horizontal dark gray line at `y = height * 0.3`.
    4. Set bottom 70% clip region (`dc.setClip(0, height * 0.3 + 1, width, height)`). Instantiate `WatchUi.TextArea` with text from `QuoteEngine.activeQuote`, centered, `locY = (height * 0.35) + scrollOffset`, font `Graphics.FONT_SMALL`. Draw TextArea. `dc.clearClip()`.
- [ ] **Create `source/UI/WidgetDelegate.mc` (`WatchUi.BehaviorDelegate`):**
  - `onNextPage()` (DOWN key): decrement `view.scrollOffset -= 25; WatchUi.requestUpdate(); return true;`
  - `onPreviousPage()` (UP key): increment `view.scrollOffset += 25; if (scrollOffset > 0) { scrollOffset = 0; } WatchUi.requestUpdate(); return true;`
  - `onSelect()` (SELECT key): Push `Menu2` action menu.
- [ ] **Create `source/UI/MenuDelegate.mc` (`WatchUi.Menu2InputDelegate`):**
  - Handle menu items: `"Next Quote"` (validates cooldown, advances engine, pops view), `"Select Mood"` (pushes submenu of 4 moods to force-override engine), and `"Toggle Cooldown"` (flips boolean in `Settings`).

---

## Phase 5: App Bootstrap & Final Verification
Wire the composition root and execute memory checks.

### Tasks:
- [ ] **Create `source/App.mc` (`Application.AppBase`):**
  - Implement `getInitialView()` returning `[new WidgetView(), new WidgetDelegate(view)]`.
- [ ] **Verification Gate (Simulator Run):**
  - Compile and run in Connect IQ Simulator (`F5`).
  - Open Memory Profiler (`View -> Memory`). Verify peak memory stays under **45KB** when repeatedly clicking "Next Quote". Verify zero memory accumulation (no leaks).