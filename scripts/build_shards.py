import os
import random
import json

SHARD_SIZE = 100
MOODS = ["Resting", "Prime", "Burnout", "Wired"]
MOOD_FILES = {m: f"data/{m.lower()}.txt" for m in MOODS}
SHARD_DIR = "resources/quotes"
RESOURCE_XML = "resources/resources.xml"

SEPARATOR = "\n|\n"

AUTHORS = [
    "Marcus Aurelius", "Seneca", "Epictetus", "James Clear",
    "Ryan Holiday", "Bren\u00e9 Brown", "Naval Ravikant", "Unknown",
    "Nelson Mandela", "Maya Angelou", "Bruce Lee", "Rumi",
    "Lao Tzu", "Victor Frankl", "Eckhart Tolle", "Marie Curie",
]

QUOTE_TEMPLATES = {
    "Resting": [
        "Rest is not idleness, it is the soil where all growth is nourished.",
        "Almost everything will work again if you unplug it for a few minutes.",
        "Your worth is not measured by your productivity.",
        "Stillness is where the answers come from.",
        "The quieter you become, the more you can hear.",
        "Peace begins with a pause.",
        "You are not a machine. Rest is not a reward it is a requirement.",
        "Nothing in nature blooms all year. Be patient with yourself.",
        "Sometimes the most productive thing you can do is rest.",
        "Let your mind wander. It knows where it needs to go.",
        "Being still does not mean you are doing nothing.",
        "Slow down. You don't have to do everything today.",
        "The day is long. Pace yourself with kindness.",
        "Sleep is the best meditation.",
        "Your body keeps score. Listen to it when it asks for rest.",
        "In the space between thoughts, there is peace.",
        "Recovery is part of the journey, not a detour from it.",
        "Breathe. This moment is enough.",
        "You have done enough. You are enough.",
        "Even the strongest tree bends in the wind.",
        "Rest is an act of self-preservation, not self-indulgence.",
        "Calmness is the cradle of power.",
        "Let go of what you cannot control. Focus on the quiet within.",
        "The mind is like water. When it is still, it reflects clearly.",
        "There is strength in softness.",
        "Sometimes doing nothing is everything.",
        "Rest today so you can rise tomorrow with clarity.",
        "Healing begins when you allow yourself to pause.",
        "Quiet the noise. Listen to the silence.",
        "Peace is not the absence of chaos but the calm within it.",
    ],
    "Prime": [
        "The best time to plant a tree was twenty years ago. The second best time is now.",
        "You are capable of more than you know. Go find out.",
        "Growth happens at the edge of your comfort zone.",
        "Your only competition is the person you were yesterday.",
        "The future belongs to those who believe in the beauty of their dreams.",
        "Action is the antidote to doubt.",
        "Every expert was once a beginner.",
        "Discipline is choosing between what you want now and what you want most.",
        "The only way to do great work is to love what you do.",
        "Dream big. Start small. Act now.",
        "Progress, not perfection.",
        "You can't cross the sea by staring at the water. Start swimming.",
        "Your potential is a seed. Water it with consistent effort.",
        "The most important step is the next one.",
        "Greatness is not born. It is built one day at a time.",
        "What you do today determines what you become tomorrow.",
        "Doubt kills more dreams than failure ever will.",
        "Be the architect of your own future.",
        "Don't wait for the perfect moment. Take the moment and make it perfect.",
        "Vision without action is a daydream. Action without vision is a nightmare.",
        "The only limit to your impact is your imagination and commitment.",
        "You have within you right now everything it takes to succeed.",
        "Fortune favors the bold.",
        "Create the life you want to live, don't wait for it.",
        "Focus on the direction, not the destination.",
        "Small daily improvements lead to stunning results.",
        "Your mindset is the lens through which you see the world. Polish it.",
        "Be the energy you want to attract.",
        "Today is an opportunity to build the life you want.",
        "The difference between who you are and who you want to be is what you do.",
    ],
    "Burnout": [
        "It is okay to not be okay. Healing takes time.",
        "You are not falling apart. You are falling into a new version of yourself.",
        "Even the darkest night will end and the sun will rise.",
        "One small step is still a step forward.",
        "Be gentle with yourself. You are doing the best you can.",
        "This too shall pass.",
        "You can't pour from an empty cup. Take care of yourself first.",
        "Surviving is a form of strength nobody talks about.",
        "Let yourself be a beginner. No one starts strong.",
        "The path to resilience is paved with self-compassion.",
        "Sometimes surviving is the greatest victory.",
        "Storms make trees take deeper roots.",
        "It's okay to set boundaries and say no.",
        "Your feelings are valid. Honor them without judgment.",
        "You are not your mistakes. You are what you learn from them.",
        "Rest when you need to, but don't quit.",
        "The strongest people are not those who show strength but those who find it in weakness.",
        "Take a deep breath. You have made it through 100% of your bad days so far.",
        "You are allowed to be both a masterpiece and a work in progress.",
        "Progress is not linear. Forgive yourself on the hard days.",
        "You don't need to have it all figured out.",
        "Some days the best thing you can do is just show up.",
        "Be proud of yourself for surviving what felt impossible.",
        "The comeback is always stronger than the setback.",
        "Let the struggle shape you, not break you.",
        "Acknowledge your pain but don't let it define you.",
        "You are braver than you believe, stronger than you seem.",
        "It's a slow process but quitting won't speed it up.",
        "Self-compassion is the bridge back to strength.",
        "Failure is just another stepping stone to resilience.",
    ],
    "Wired": [
        "Focus is the new superpower. Guard it with your life.",
        "Channel your intensity into action. Let the world feel your fire.",
        "Precision beats power. Timing beats speed.",
        "You are not here to be average. You are here to be exceptional.",
        "Execute first, justify later.",
        "Energy is contagious. Bring the fire.",
        "The difference between ordinary and extraordinary is that little extra.",
        "Zero excuses. Full commitment.",
        "Turn your frustration into fuel.",
        "Be relentless. Be ruthless with your own standards.",
        "Comfort is a poor substitute for fulfillment.",
        "The obstacle is the way. Run through it.",
        "Today I will do what others won't, so tomorrow I can do what others can't.",
        "Intensity without direction is chaos. Aim carefully.",
        "Pressure is a privilege.",
        "Make it happen. Shock everyone including yourself.",
        "Winners are not people who never fail but people who never quit.",
        "The harder you work, the luckier you get.",
        "No one ever achieved greatness by playing it safe.",
        "Don't count the reps. Make the reps count.",
        "Your only limit is the one you set in your mind.",
        "Attack the day before it attacks you.",
        "Be so focused that you have no time for negativity.",
        "When you feel like quitting, remember why you started.",
        "Explosive effort beats consistent mediocrity.",
        "You were built for this. Act like it.",
        "The grind is the glory.",
        "Be obsessed or be average.",
        "Fire cannot be contained. Neither can you.",
        "This moment is yours. Seize it with both hands.",
    ],
}

def create_mock_data():
    os.makedirs("data", exist_ok=True)
    for mood in MOODS:
        path = MOOD_FILES[mood]
        if os.path.exists(path):
            continue
        templates = QUOTE_TEMPLATES[mood]
        with open(path, "w", encoding="utf-8") as f:
            for i in range(150):
                text = templates[i % len(templates)]
                if i >= len(templates):
                    seed = (i * 7 + 13) % 97
                    text = f"{text.rstrip('.')} \u2014 Reflection {seed}."
                author = AUTHORS[(i * 3 + len(mood)) % len(AUTHORS)]
                f.write(f"{text}\n\n- {author}\0")

def build_shards_for_mood(mood_name, src_path):
    with open(src_path, "r", encoding="utf-8") as f:
        raw = f.read()
    raw_quotes = raw.split("\0")
    quotes = [q for q in raw_quotes if q.strip()]
    total_quotes = len(quotes)
    num_shards = (total_quotes + SHARD_SIZE - 1) // SHARD_SIZE
    entries = []
    os.makedirs(SHARD_DIR, exist_ok=True)
    for shard_idx in range(num_shards):
        start = shard_idx * SHARD_SIZE
        end = min(start + SHARD_SIZE, total_quotes)
        slice_quotes = quotes[start:end]
        combined = SEPARATOR.join(slice_quotes)
        res_id = f"bin_{mood_name.lower()}_{shard_idx}"
        filename = f"{res_id}.json"
        filepath = os.path.join(SHARD_DIR, filename)
        json_str = json.dumps(combined, ensure_ascii=False)
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(json_str)
        size = len(json_str.encode("utf-8"))
        entries.append((res_id, filename, len(slice_quotes), size))
        print(f"  [+] {filename} ({len(slice_quotes)} quotes, {size}B)")
    return entries

def generate_resources_xml(all_entries):
    lines = ['<resources>']
    lines.append('    <string id="AppName">Cheerfulness IQ</string>')
    lines.append('    <string id="MenuTitle">Options</string>')
    lines.append('    <string id="NextQuote">Next Quote</string>')
    lines.append('    <string id="SelectMood">Select Mood</string>')

    lines.append('    <string id="MoodWiredLabel">Wired</string>')
    lines.append('    <string id="MoodPrimeLabel">Prime</string>')
    lines.append('    <string id="MoodBurnoutLabel">Burnout</string>')
    lines.append('    <string id="MoodRestingLabel">Resting</string>')
    lines.append('')
    lines.append('    <!-- Quote Shards (JSON strings) -->')
    for res_id, filename, count, size in all_entries:
        lines.append(f'    <jsonData id="{res_id}" filename="quotes/{filename}" />')
    lines.append('')
    lines.append('    <!-- Mood Bitmaps -->')
    for mood in MOODS:
        lines.append(f'    <bitmap id="Mood{mood}" filename="drawables/mood_{mood.lower()}.png" />')
    lines.append('    <bitmap id="LauncherIcon" filename="drawables/launcher_icon.png" />')
    lines.append('</resources>')
    with open(RESOURCE_XML, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"\n[+] Generated {RESOURCE_XML} with {len(all_entries)} shards.")

def main():
    print("=== Cheerfulness IQ Data Pipeline (JSON String Shards) ===")
    create_mock_data()
    all_entries = []
    for mood in MOODS:
        print(f"\nPacking mood: {mood}")
        print(f"  Source: {MOOD_FILES[mood]}")
        entries = build_shards_for_mood(mood, MOOD_FILES[mood])
        all_entries.extend(entries)
    generate_resources_xml(all_entries)
    print("\n=== Done! ===")

if __name__ == "__main__":
    main()
