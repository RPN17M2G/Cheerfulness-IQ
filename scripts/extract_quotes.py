import sqlite3, os, random

random.seed(42)
DB_PATH = os.path.join(os.environ['TEMP'], 'ciq_quotes_db.sqlite3')
DATA_DIR = "data"
QUOTES_PER_MOOD = 11250

MOOD_KEYWORDS = {
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

def truncate_quote(text):
    if len(text) <= 180:
        return text
    return None

def make_like_clauses(keywords):
    clauses = []
    params = []
    for kw in keywords:
        p = f"%{kw}%"
        clauses.append("(category LIKE ? OR quote LIKE ?)")
        params.extend([p, p])
    return " OR ".join(clauses), params

def main():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    os.makedirs(DATA_DIR, exist_ok=True)

    all_selected = {}
    used_ids = set()

    for mood, keywords in MOOD_KEYWORDS.items():
        clauses, params = make_like_clauses(keywords)
        sql = f"SELECT rowid, author, category, quote FROM Quote WHERE {clauses} LIMIT {QUOTES_PER_MOOD * 4}"
        cursor.execute(sql, params)
        rows = cursor.fetchall()
        print(f"{mood}: {len(rows)} keyword-matched rows")

        selected = []
        for row in rows:
            rid = row[0]
            if rid in used_ids:
                continue
            used_ids.add(rid)
            text = row[3].replace('\ufffd', "'").strip()
            if len(text) < 20:
                continue
            text = truncate_quote(text)
            if text is None:
                continue
            author = row[1] if row[1] else ""
            selected.append((text, author.strip(), row[2] if row[2] else ""))
            if len(selected) >= QUOTES_PER_MOOD:
                break

        print(f"  -> {len(selected)} unique quotes after dedup")
        all_selected[mood] = selected

    total = sum(len(v) for v in all_selected.values())
    print(f"\nTotal collected via keywords: {total}")
    max_mood = max(all_selected, key=lambda m: len(all_selected[m]))
    print(f"  Best mood: {max_mood} ({len(all_selected[max_mood])})")

    needed_moods = [m for m in ["Resting", "Prime", "Burnout", "Wired"] if len(all_selected[m]) < QUOTES_PER_MOOD]
    if needed_moods:
        total_needed = sum(QUOTES_PER_MOOD - len(all_selected[m]) for m in needed_moods)
        print(f"Need {total_needed} more quotes from general pool")
        cursor.execute("SELECT rowid, author, category, quote FROM Quote ORDER BY RANDOM() LIMIT ?",
                       (total_needed * 10,))
        fill_rows = cursor.fetchall()
        fill_idx = 0
        for mood in needed_moods:
            needed = QUOTES_PER_MOOD - len(all_selected[mood])
            added = 0
            while added < needed and fill_idx < len(fill_rows):
                row = fill_rows[fill_idx]
                fill_idx += 1
                rid = row[0]
                if rid in used_ids:
                    continue
                used_ids.add(rid)
                text = row[3].replace('\ufffd', "'").strip()
                if len(text) < 20:
                    continue
                text = truncate_quote(text)
                if text is None:
                    continue
                author = row[1] if row[1] else ""
                all_selected[mood].append((text, author.strip(), row[2] if row[2] else ""))
                added += 1
            print(f"  Filled {mood} with {added} random quotes")

    total_written = 0
    for mood in ["Resting", "Prime", "Burnout", "Wired"]:
        pool = all_selected[mood]
        random.shuffle(pool)
        selected = pool[:QUOTES_PER_MOOD]
        filepath = os.path.join(DATA_DIR, f"{mood.lower()}.txt")
        with open(filepath, "w", encoding="utf-8") as f:
            for text, author, cats in selected:
                display_author = author if author else "Unknown"
                f.write(f"{text}\n\n- {display_author}\0")
        total_written += len(selected)
        print(f"\n{mood}: {len(selected)} quotes written to {filepath}")

    print(f"\n=== TOTAL: {total_written} quotes ===")
    conn.close()

if __name__ == "__main__":
    main()
