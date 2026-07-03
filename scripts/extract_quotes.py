"""
Cheerfulness IQ — Quote Extraction & Mood Classification Pipeline.

Downloads the MIT-licensed quotes_library SQLite database (cached in %TEMP%),
scores each quote against mood-specific keyword lists, and writes one
intermediate text file per mood containing the top-scoring quotes.

Usage:
    python scripts/extract_quotes.py
"""

import logging
import os
import random
import sqlite3
import sys
from typing import Dict, List, Optional, Tuple

LOG = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

QUOTES_PER_MOOD: int = 11250
MINIMUM_QUOTE_LENGTH: int = 20
MAXIMUM_QUOTE_LENGTH: int = 180
KEYWORD_SAMPLE_MULTIPLIER: int = 4
RANDOM_FILL_MULTIPLIER: int = 10

QUOTES_DATABASE_PATH: str = os.path.join(
    os.environ["TEMP"], "ciq_quotes_db.sqlite3"
)
INTERMEDIATE_DATA_DIRECTORY: str = "data"

UNICODE_REPLACEMENT_CHARACTER: str = "\ufffd"

MOOD_ORDER: List[str] = ["Resting", "Prime", "Burnout", "Wired"]

MOOD_KEYWORDS: Dict[str, List[str]] = {
    "Resting": [
        "peace", "calm", "relax", "sleep", "nature", "gratitude", "simplicity",
        "stillness", "quiet", "gentle", "serenity", "content", "rest", "pause",
        "solitude", "silence", "slow", "breathe", "meditation", "mindfulness",
        "acceptance", "satisfaction", "tranquil", "surrender", "let go",
        "presence", "being", "enough", "dawn", "sunset", "ocean", "river",
        "forest", "garden", "flower", "moon", "star", "sky", "cloud", "rain",
        "comfort", "safe", "home", "kindness", "forgive", "compassion",
        "understanding", "patience", "tender", "hush", "deep",
        "reflection", "contemplation", "prayer", "sacred", "blessing", "grace",
        "renewal", "restoration", "rejuvenation", "refresh", "morning",
        "evening", "twilight", "dusk", "night", "dream", "leisure", "ease",
        "harmony", "balance", "heal", "recover", "nurture", "care", "soothe",
        "float", "drift", "wave", "shore", "breeze", "silent", "still",
        "devotion", "gentleness", "humility", "innocence", "listening",
        "mild", "peaceful", "pensive", "receptive", "serene", "softness",
        "still water", "tranquility", "watching", "whisper", "yield",
    ],
    "Prime": [
        "life", "wisdom", "philosophy", "growth", "learning", "creativity",
        "dream", "future", "happiness", "joy", "inspiration", "vision",
        "purpose", "passion", "potential", "discovery", "explore", "imagination",
        "possibility", "awakening", "curiosity", "beginning", "journey",
        "perspective", "freedom", "light", "hope", "optimism", "positive",
        "thrive", "bloom", "flourish", "rise", "awake", "alive",
        "vibrant", "energy", "enthusiasm", "zeal", "wonder", "awe",
        "beauty", "truth", "knowledge", "enlighten", "wisdom", "mind",
        "thought", "idea", "innovation", "create", "build", "design",
        "craft", "art", "music", "poetry", "write", "read", "book",
        "adventure", "quest", "horizon", "mountain", "summit", "peak",
        "flight", "soar", "wing", "bird", "seed", "spring",
        "fresh", "new", "youth", "vitality", "spark", "shine",
        "bright", "radiant", "laugh", "smile", "dance", "sing",
        "grateful", "thankful", "abundance", "miracle", "magic",
        "discover", "unfold", "become", "transform", "evolve",
        "awake", "consciousness", "realization", "understand",
        "teach", "lesson", "educate", "wisdom", "philosopher",
        "meaning", "purpose", "calling", "vocation", "path",
    ],
    "Burnout": [
        "hope", "perseverance", "resilience", "strength", "courage",
        "healing", "recovery", "survival", "patience", "compassion",
        "struggle", "endurance", "inner strength", "self care",
        "forgive", "vulnerability", "persist", "never quit",
        "overcome", "survive", "weakness", "broken", "fall", "rise",
        "pain", "hurt", "wound", "scar", "ache", "dark", "darkness",
        "night", "shadow", "storm", "rain", "heavy", "weight", "burden",
        "tired", "exhaust", "weary", "fatigue", "anxiety", "fear", "doubt",
        "grief", "loss", "sorrow", "tear", "cry", "lonely", "alone",
        "empty", "fragile", "break", "bleeding", "bruised", "battle",
        "warrior", "climb", "steep", "hard", "difficult", "challenge",
        "trial", "adversity", "hardship", "suffering", "endure", "bear",
        "withstand", "weather", "breathe", "air", "tomorrow",
        "another day", "sunrise", "light", "rebuild", "repair", "mend",
        "restore", "renew", "lesson", "learn", "grow", "stronger",
        "wiser", "deeper", "holding on", "let go", "accept",
        "moving on", "heal", "hurt", "sad", "depression", "anguish",
        "agony", "despair", "sorrow", "mourning", "grieving",
    ],
    "Wired": [
        "leadership", "success", "achievement", "ambition", "motivation",
        "determination", "action", "power", "discipline", "focus", "drive",
        "intensity", "challenge", "excellence", "goal", "goals", "confidence",
        "conquer", "fearless", "commitment", "execution", "winning",
        "greatness", "break barriers", "limitless", "push limits",
        "dominate", "master", "control", "command", "authority",
        "strategy", "tactics", "victory", "triumph", "champion",
        "competition", "rival", "battle", "war", "force", "strength",
        "power", "energy", "fire", "fury", "speed", "agility",
        "precision", "accuracy", "sharp", "edge", "advantage",
        "superior", "elite", "peak", "performance", "results",
        "mission", "objective", "target", "deadline", "hustle", "grind",
        "work ethic", "relentless", "unstoppable", "unbreakable",
        "bold", "daring", "audacious", "ambitious", "driven",
        "hunger", "thirst", "desire", "will", "resolve", "training",
        "practice", "preparation", "ready", "execute", "perform",
        "deliver", "achieve", "accomplish", "prove", "earn",
        "seize", "momentum", "progress", "forward", "advance", "attack",
        "aggressive", "assertive", "decisive", "determined", "focused",
        "warrior", "fighter", "champion", "winner", "victor",
    ],
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def truncate_quote(text: str) -> Optional[str]:
    """
    Return *text* unchanged if it fits within the maximum length, or
    ``None`` so the caller can skip the quote entirely.
    """
    if len(text) <= MAXIMUM_QUOTE_LENGTH:
        return text
    return None


def score_quote(text: str, category: str, keywords: List[str]) -> int:
    """
    Count how many *keywords* appear in the quote's text or category.

    Higher scores indicate a stronger thematic match for the mood.
    """
    lowercase_text = text.lower()
    lowercase_category = category.lower()
    score = 0
    for keyword in keywords:
        if keyword in lowercase_text or keyword in lowercase_category:
            score += 1
    return score


def build_like_clauses(keywords: List[str]) -> Tuple[str, List[str]]:
    """
    Build a SQL ``WHERE`` clause and parameter list for a keyword search.

    Each keyword generates a ``(category LIKE ? OR quote LIKE ?)`` clause.
    """
    like_clauses: List[str] = []
    parameters: List[str] = []
    for keyword in keywords:
        like_pattern = f"%{keyword}%"
        like_clauses.append("(category LIKE ? OR quote LIKE ?)")
        parameters.extend([like_pattern, like_pattern])
    return " OR ".join(like_clauses), parameters


def clean_raw_text(raw: str) -> str:
    """Replace the Unicode replacement character with an ASCII apostrophe."""
    return raw.replace(UNICODE_REPLACEMENT_CHARACTER, "'").strip()


def is_valid_quote(text: str) -> bool:
    """Check that the quote meets minimum length, fits within the maximum,
    and is not a truncated fragment."""
    if len(text) < MINIMUM_QUOTE_LENGTH:
        return False
    if truncate_quote(text) is None:
        return False
    stripped = text.strip()
    if stripped.startswith("...") or stripped.endswith("..."):
        return False
    return True


def configure_logging() -> None:
    """Set up a simple stdout logger."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(message)s",
        stream=sys.stdout,
    )


# ---------------------------------------------------------------------------
# Main extraction logic
# ---------------------------------------------------------------------------


def extract_and_write() -> int:
    """
    Orchestrate the full extraction pipeline.

    Returns ``0`` on success, ``1`` on failure.
    """
    os.makedirs(INTERMEDIATE_DATA_DIRECTORY, exist_ok=True)

    try:
        connection = sqlite3.connect(QUOTES_DATABASE_PATH)
        cursor = connection.cursor()
    except sqlite3.Error as exception:
        LOG.error("Failed to open database at %s: %s", QUOTES_DATABASE_PATH, exception)
        return 1

    all_selected: Dict[str, List[Tuple[str, str, str]]] = {}
    used_row_ids: set = set()

    # -- Keyword-matched pass -------------------------------------------------
    for mood_name, keywords in MOOD_KEYWORDS.items():
        like_clause, parameters = build_like_clauses(keywords)
        query = (
            f"SELECT rowid, author, category, quote FROM Quote "
            f"WHERE {like_clause} "
            f"LIMIT {QUOTES_PER_MOOD * KEYWORD_SAMPLE_MULTIPLIER}"
        )

        try:
            cursor.execute(query, parameters)
            rows = cursor.fetchall()
        except sqlite3.Error as exception:
            LOG.error("SQL error for mood '%s': %s", mood_name, exception)
            connection.close()
            return 1

        LOG.info("%s: %s keyword-matched rows", mood_name, len(rows))

        scored_entries: List[Tuple[int, str, str, str]] = []
        for row in rows:
            row_id = row[0]
            if row_id in used_row_ids:
                continue
            used_row_ids.add(row_id)

            cleaned = clean_raw_text(row[3])
            if not is_valid_quote(cleaned):
                continue

            author = row[1].strip() if row[1] else ""
            category = row[2] if row[2] else ""
            match_score = score_quote(cleaned, category, keywords)
            scored_entries.append((match_score, cleaned, author, category))

        scored_entries.sort(key=lambda entry: -entry[0])
        selected = [
            (text, author, category_name)
            for _, text, author, category_name in scored_entries[:QUOTES_PER_MOOD]
        ]
        LOG.info(
            "  -> %s quotes (top keyword score: %s)",
            len(selected),
            scored_entries[0][0] if scored_entries else 0,
        )
        all_selected[mood_name] = selected

    # -- Fill remaining slots with random quotes ------------------------------
    total_keyword_hits = sum(len(v) for v in all_selected.values())
    LOG.info("\nTotal collected via keywords: %s", total_keyword_hits)

    best_mood = max(all_selected, key=lambda mood: len(all_selected[mood]))
    LOG.info("  Most populous mood: %s (%s)", best_mood, len(all_selected[best_mood]))

    moods_needing_fill = [
        mood_name
        for mood_name in MOOD_ORDER
        if len(all_selected[mood_name]) < QUOTES_PER_MOOD
    ]

    if moods_needing_fill:
        total_fill_needed = sum(
            QUOTES_PER_MOOD - len(all_selected[mood_name])
            for mood_name in moods_needing_fill
        )
        LOG.info("Need %s more quotes from general pool", total_fill_needed)

        try:
            cursor.execute(
                "SELECT rowid, author, category, quote FROM Quote ORDER BY RANDOM() LIMIT ?",
                (total_fill_needed * RANDOM_FILL_MULTIPLIER,),
            )
            random_fill_rows = cursor.fetchall()
        except sqlite3.Error as exception:
            LOG.error("SQL error during random fill: %s", exception)
            connection.close()
            return 1

        fill_index = 0
        for mood_name in moods_needing_fill:
            remaining = QUOTES_PER_MOOD - len(all_selected[mood_name])
            added = 0
            while added < remaining and fill_index < len(random_fill_rows):
                row = random_fill_rows[fill_index]
                fill_index += 1
                row_id = row[0]
                if row_id in used_row_ids:
                    continue
                used_row_ids.add(row_id)

                cleaned = clean_raw_text(row[3])
                if not is_valid_quote(cleaned):
                    continue

                author = row[1].strip() if row[1] else ""
                all_selected[mood_name].append(
                    (cleaned, author, row[2] if row[2] else "")
                )
                added += 1

            LOG.info("  Filled %s with %s random quotes", mood_name, added)

    connection.close()

    # -- Write intermediate text files ----------------------------------------
    total_written = 0
    for mood_name in MOOD_ORDER:
        pool = all_selected[mood_name]
        random.shuffle(pool)
        final_selection = pool[:QUOTES_PER_MOOD]

        output_path = os.path.join(
            INTERMEDIATE_DATA_DIRECTORY, f"{mood_name.lower()}.txt"
        )

        try:
            with open(output_path, "w", encoding="utf-8") as handle:
                for text, author, _category in final_selection:
                    display_author = author if author else "Unknown"
                    handle.write(f"{text}\n\n- {display_author}\0")
        except OSError as exception:
            LOG.error("Failed to write %s: %s", output_path, exception)
            return 1

        LOG.info("%s: %s quotes written to %s", mood_name, len(final_selection), output_path)
        total_written += len(final_selection)

    LOG.info("\n=== TOTAL: %s quotes ===", total_written)
    return 0


def main() -> None:
    """Entry point."""
    configure_logging()
    sys.exit(extract_and_write())


if __name__ == "__main__":
    random.seed(42)
    main()
