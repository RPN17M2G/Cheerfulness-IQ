# Cheerfulness IQ

A Garmin Connect IQ watch app that delivers motivational quotes adapted to your current physiological state. By reading your watch's stress and body battery metrics, it selects content that matches your real-time nervous system condition.

## How It Works

Each time you open the app, Cheerfulness IQ evaluates the last hour of your biometric data and classifies your state into one of four quadrants:

| Mood | Stress | Body Battery | Content |
|------|--------|-------------|---------|
| **Wired** | High | High | Tactical, sharp, execution-focused |
| **Prime** | Low | High | Expansive, visionary, proactive |
| **Burnout** | High | Low | Grounding, resilient, compassionate |
| **Resting** | Low | Low | Restorative, calm, validating |

A 3% chaos roll occasionally serves a quote from a random mood to introduce fresh perspectives.

### Controls

- **UP/DOWN** — Scroll quote text vertically
- **SELECT** — Open menu: advance quote or force-select a mood
- The app appears in the watch face scroll loop via GlanceView

## Architecture

### 30,000 Quotes, 7 MB, On-Device

Quotes are stored as 300 JSON string shard files (75 per mood, 100 quotes each, ~24 KB per shard). The engine loads one shard at a time, extracts a single quote, and immediately nulls the buffer — peak heap usage stays under ~46 KB.

### Project Structure

```
source/
  CheerfulnessIQApp.mc       — App entry point (extends AppBase)
  Core/
    Biometrics.mc             — Stress/BB evaluation + 3% chaos roll
    QuoteEngine.mc            — Lazy shard loader with look-ahead buffer
    ShardIndex.mc             — Auto-generated ResourceId lookup table
  UI/
    CheerfulnessIQView.mc     — 30/70 viewport with mood photo + TextArea
    CheerfulnessIQDelegate.mc — UP/DOWN scroll, SELECT menu trigger
    CheerfulnessIQMenuDelegate.mc  — Menu2 handler (advance, force mood)
    CheerfulnessIQGlanceView.mc    — Smiley logo for watch face scroll loop
scripts/
    build_shards.py           — Pipeline: extract + pack + index
    extract_quotes.py         — Keyword-score 286K quotes into 4 moods
resources/
    quotes/*.json             — 300 JSON string shard files
    drawables/*.png           — 4 mood photos + launcher icon
data/                         — Intermediate text files (gitignored)
```

## Building & Running

### Prerequisites

- Connect IQ SDK 9.2.0+
- A Garmin developer key (`.der` file)
- Python 3.11+ with `requests`

### Data Pipeline

```bash
python scripts/build_shards.py
```

Downloads the quotes database on first run (~114 MB, cached in `%TEMP%`), extracts 30,000 quotes scored by mood keywords, and generates the JSON shard files + `resources.xml` + `ShardIndex.mc`.

### Compile

```bash
monkeyc -d fr255m_sim -f monkey.jungle -o bin/CheerfulnessIQ.prg -y /path/to/developer_key.der
```

Or build from VS Code with the Connect IQ extension.

### Supported Devices

Forerunner 255, 255 Music, 255s, 255s Music, 265

## License & Attribution

### Quotes Dataset

All 30,000 quotes are sourced from [quotes_library](https://github.com/mymi14s/quotes_library) by **Anthony Emmanuel** (mymi14s), used under the MIT License.

```
MIT License

Copyright (c) 2024 Anthony Emmanuel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

### Background Images

Mood photographs are sourced from Unsplash under the Unsplash License (free for commercial and non-commercial use):
- Resting (lake) — by Marc-Olivier Jodoin
- Prime (sunrise fields) — by Aaron Burden
- Burnout (forest) — by Sebastian Unrau
- Wired (purple sunset) — by Pietro De Grandi

### This Project

```
MIT License

Copyright (c) 2024 Cheerfulness IQ Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```
