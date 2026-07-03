"""
Cheerfulness IQ — Shard Builder Pipeline.

Orchestrates quote extraction, splits each mood's quote pool into numbered
JSON string shard files (100 quotes per shard), and auto-generates the
Connect IQ resource XML and ShardIndex Monkey C source.

Usage:
    python scripts/build_shards.py
"""

import json
import logging
import os
import random
import subprocess
import sys
from typing import Dict, List, Tuple

LOG = logging.getLogger(__name__)

# Re-use mood order from the extraction step.
from extract_quotes import MOOD_ORDER  # noqa: E402

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

QUOTES_PER_SHARD: int = 100
SHARD_OUTPUT_DIRECTORY: str = "resources/quotes"
RESOURCE_XML_PATH: str = "resources/resources.xml"
SHARD_INDEX_FILE_PATH: str = "source/Core/ShardIndex.mc"

QUOTE_SEPARATOR: str = "\n|\n"

MOOD_FILES: Dict[str, str] = {
    mood_name: f"data/{mood_name.lower()}.txt" for mood_name in MOOD_ORDER
}


# ---------------------------------------------------------------------------
# Extraction sub-process
# ---------------------------------------------------------------------------


def run_extraction_step() -> None:
    """Delegate to extract_quotes.py before packing shards."""
    script_path = os.path.join(os.path.dirname(__file__), "extract_quotes.py")
    if not os.path.exists(script_path):
        LOG.warning("Extraction script not found at %s — skipping", script_path)
        return
    LOG.info("  [*] Extracting real quotes from database...")
    result = subprocess.run([sys.executable, script_path], capture_output=True, text=True)
    if result.returncode != 0:
        LOG.error("Extraction failed:\n%s", result.stderr)
        sys.exit(result.returncode)
    if result.stdout:
        LOG.info(result.stdout)


# ---------------------------------------------------------------------------
# Shard packing
# ---------------------------------------------------------------------------


def build_shards_for_mood(
    mood_name: str, source_path: str
) -> List[Tuple[str, str, int, int]]:
    """
    Read the intermediate text file for one mood, split into shards, and
    write each shard as a JSON string file.

    Returns a list of ``(resource_id, filename, quote_count, byte_size)``
    tuples for every shard produced.
    """
    with open(source_path, "r", encoding="utf-8") as handle:
        raw = handle.read()

    raw_quotes = raw.split("\0")
    quotes = [quote for quote in raw_quotes if quote.strip()]
    total_quote_count = len(quotes)
    shard_count = (total_quote_count + QUOTES_PER_SHARD - 1) // QUOTES_PER_SHARD
    entries: List[Tuple[str, str, int, int]] = []

    os.makedirs(SHARD_OUTPUT_DIRECTORY, exist_ok=True)

    for shard_index in range(shard_count):
        start = shard_index * QUOTES_PER_SHARD
        end = min(start + QUOTES_PER_SHARD, total_quote_count)
        slice_quotes = quotes[start:end]

        combined_quotes = QUOTE_SEPARATOR.join(slice_quotes)
        resource_identifier = f"bin_{mood_name.lower()}_{shard_index}"
        filename = f"{resource_identifier}.json"
        filepath = os.path.join(SHARD_OUTPUT_DIRECTORY, filename)

        json_string = json.dumps(combined_quotes, ensure_ascii=False)
        with open(filepath, "w", encoding="utf-8") as handle:
            handle.write(json_string)

        byte_size = len(json_string.encode("utf-8"))
        entries.append((resource_identifier, filename, len(slice_quotes), byte_size))

        LOG.info(
            "  [+] shard %2d/%2d: %s (%d quotes, %d B)",
            shard_index,
            shard_count - 1,
            filename,
            len(slice_quotes),
            byte_size,
        )

    return entries


# ---------------------------------------------------------------------------
# Resource XML generation
# ---------------------------------------------------------------------------


def generate_resource_xml(all_entries: List[Tuple[str, str, int, int]]) -> None:
    """
    Write ``resources/resources.xml`` referencing every shard and every
    mood bitmap.
    """
    lines = ["<resources>"]
    lines.append('    <string id="AppName">Cheerfulness IQ</string>')
    lines.append('    <string id="MenuTitle">Options</string>')
    lines.append('    <string id="NextQuote">Next Quote</string>')
    lines.append('    <string id="SelectMood">Select Mood</string>')
    lines.append('    <string id="MoodWiredLabel">Wired</string>')
    lines.append('    <string id="MoodPrimeLabel">Prime</string>')
    lines.append('    <string id="MoodBurnoutLabel">Burnout</string>')
    lines.append('    <string id="MoodRestingLabel">Resting</string>')
    lines.append("")
    lines.append("    <!-- Quote Shards (JSON strings) -->")
    for resource_identifier, filename, _count, _size in all_entries:
        lines.append(
            f'    <jsonData id="{resource_identifier}" '
            f'filename="quotes/{filename}" />'
        )
    lines.append("")
    lines.append("    <!-- Mood Bitmaps -->")
    for mood_name in MOOD_ORDER:
        lines.append(
            f'    <bitmap id="Mood{mood_name}" '
            f'filename="drawables/mood_{mood_name.lower()}.png" />'
        )
    lines.append(
        '    <bitmap id="LauncherIcon" filename="drawables/launcher_icon.png" />'
    )
    lines.append("</resources>")

    with open(RESOURCE_XML_PATH, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    LOG.info("\n[+] Generated %s with %d shards.", RESOURCE_XML_PATH, len(all_entries))


# ---------------------------------------------------------------------------
# ShardIndex.mc generation
# ---------------------------------------------------------------------------


def generate_shard_index(all_entries: List[Tuple[str, str, int, int]]) -> None:
    """
    Write ``source/Core/ShardIndex.mc`` containing the
    ``const SHARD_IDS[MOOD_COUNT][SHARD_COUNT]`` lookup table and
    ``const SHARD_COUNT`` constant.
    """
    mood_shard_entries: Dict[str, List[Tuple[int, str]]] = {
        mood_name: [] for mood_name in MOOD_ORDER
    }

    for resource_identifier, _filename, _count, _size in all_entries:
        parts = resource_identifier.split("_")
        mood_name = parts[1].capitalize()
        shard_index = int(parts[2])
        mood_shard_entries[mood_name].append((shard_index, resource_identifier))

    max_shards = max(len(entries) for entries in mood_shard_entries.values())

    lines = [
        "// Auto-generated by build_shards.py -- DO NOT EDIT",
        "import Toybox.Lang;",
        "",
        "module CoreShardIndex {",
        "",
        f"    const SHARD_COUNT as Number = {max_shards};",
        "",
        "    const SHARD_IDS as Array = [",
    ]

    for mood_index, mood_name in enumerate(MOOD_ORDER):
        shards = sorted(mood_shard_entries[mood_name], key=lambda pair: pair[0])
        reference_list = ", ".join(
            f"Rez.JsonData.{identifier}" for _, identifier in shards
        )
        trailing_comma = "," if mood_index < len(MOOD_ORDER) - 1 else ""
        lines.append(f"        [{reference_list}]{trailing_comma}")

    lines.append("    ];")
    lines.append("}")
    lines.append("")

    with open(SHARD_INDEX_FILE_PATH, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines))
    LOG.info(
        "[+] Generated %s (%d shards per mood)",
        SHARD_INDEX_FILE_PATH,
        max_shards,
    )


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------


def validate_shards(all_entries: List[Tuple[str, str, int, int]]) -> int:
    """
    Perform post-build sanity checks on every generated shard.

    Returns the number of issues found (``0`` = all clean).
    """
    issues = 0
    LOG.info("\n  [*] Validating generated shards...")

    for resource_identifier, filename, expected_count, expected_size in all_entries:
        filepath = os.path.join(SHARD_OUTPUT_DIRECTORY, filename)

        if not os.path.isfile(filepath):
            LOG.error("    MISSING: %s", filepath)
            issues += 1
            continue

        actual_size = os.path.getsize(filepath)
        if actual_size != expected_size:
            LOG.warning(
                "    SIZE MISMATCH %s: expected %d B, got %d B",
                filename,
                expected_size,
                actual_size,
            )
            issues += 1

        try:
            with open(filepath, "r", encoding="utf-8") as handle:
                decoded = json.load(handle)
        except (json.JSONDecodeError, OSError) as exception:
            LOG.error("    JSON ERROR %s: %s", filename, exception)
            issues += 1
            continue

        quotes = decoded.split(QUOTE_SEPARATOR)
        actual_count = len(quotes)
        if actual_count != expected_count:
            LOG.warning(
                "    COUNT MISMATCH %s: expected %d quotes, found %d",
                filename,
                expected_count,
                actual_count,
            )
            issues += 1

    if issues == 0:
        LOG.info("    All %d shards valid.", len(all_entries))
    else:
        LOG.warning("    %d issue(s) found across %d shards.", issues, len(all_entries))

    return issues


def configure_logging() -> None:
    """Set up a simple stdout logger."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        stream=sys.stdout,
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """Run the full build pipeline: extract → pack → index → validate."""
    configure_logging()
    LOG.info("=== Cheerfulness IQ Data Pipeline (JSON String Shards) ===")

    run_extraction_step()

    all_entries: List[Tuple[str, str, int, int]] = []
    for mood_name in MOOD_ORDER:
        source_path = MOOD_FILES[mood_name]
        LOG.info("\nPacking mood: %s", mood_name)
        LOG.info("  Source: %s", source_path)
        entries = build_shards_for_mood(mood_name, source_path)
        all_entries.extend(entries)

    generate_resource_xml(all_entries)
    generate_shard_index(all_entries)

    validation_issues = validate_shards(all_entries)

    if validation_issues > 0:
        LOG.error("\n=== Pipeline finished with %d issue(s) ===", validation_issues)
        sys.exit(1)

    LOG.info("\n=== Done! ===")


if __name__ == "__main__":
    random.seed(42)
    main()
