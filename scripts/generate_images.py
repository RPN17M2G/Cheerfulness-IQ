from PIL import Image, ImageDraw, ImageFont
import math, random, os

W, H = 260, 260
OUT = "resources/drawables"
os.makedirs(OUT, exist_ok=True)

def radial_gradient(w, h, cx, cy, stops):
    img = Image.new("RGB", (w, h))
    max_r = math.sqrt(max(cx, w-cx)**2 + max(cy, h-cy)**2)
    for y in range(h):
        for x in range(w):
            d = math.sqrt((x-cx)**2 + (y-cy)**2) / max_r
            for i in range(len(stops)-1):
                r0, c0 = stops[i]
                r1, c1 = stops[i+1]
                if r0 <= d <= r1:
                    t = (d - r0) / (r1 - r0)
                    r = int(c0[0] + (c1[0]-c0[0])*t)
                    g = int(c0[1] + (c1[1]-c0[1])*t)
                    b = int(c0[2] + (c1[2]-c0[2])*t)
                    img.putpixel((x, y), (r, g, b))
                    break
    return img

def line_gradient(w, h, angle_deg, stops):
    img = Image.new("RGB", (w, h))
    rad = math.radians(angle_deg)
    cx, cy = w/2, h/2
    for y in range(h):
        for x in range(w):
            proj = (x-cx)*math.cos(rad) + (y-cy)*math.sin(rad)
            d = (proj + math.sqrt(w*w + h*h)/2) / math.sqrt(w*w + h*h)
            for i in range(len(stops)-1):
                r0, c0 = stops[i]
                r1, c1 = stops[i+1]
                if r0 <= d <= r1:
                    t = (d - r0) / (r1 - r0)
                    r = int(c0[0] + (c1[0]-c0[0])*t)
                    g = int(c0[1] + (c1[1]-c0[1])*t)
                    b = int(c0[2] + (c1[2]-c0[2])*t)
                    img.putpixel((x, y), (r, g, b))
                    break
    return img

# === Resting: calm teal/indigo abstract water ripples ===
img = radial_gradient(W, H, W/2, H/3, [(0, (20,30,80)), (0.5, (40,70,120)), (0.8, (60,100,140)), (1, (30,50,80))])
draw = ImageDraw.Draw(img)
for r in range(4):
    cr = 40 + r * 35 + random.randint(0, 15)
    cx = W//2 + random.randint(-20, 20)
    cy = H//2 + random.randint(-20, 20)
    color = (70 + r*20, 110 + r*15, 170 - r*10)
    draw.ellipse([cx-cr, cy-cr//2, cx+cr, cy+cr//2], outline=color, width=2)
for _ in range(15):
    x = random.randint(0, W)
    y = random.randint(0, int(H*0.3))
    br = random.randint(1, 2)
    draw.ellipse([x-br, y-br, x+br, y+br], fill=(200, 220, 255))
img.save(f"{OUT}/mood_resting.png", optimize=True)

# === Prime: warm gold/peach sunrise burst ===
img = radial_gradient(W, H, W/2, H+30, [(0, (180,120,50)), (0.3, (235,195,110)), (0.6, (240,215,170)), (0.8, (200,200,180)), (1, (100,150,120))])
draw = ImageDraw.Draw(img)
# Sun burst rings
for i in range(12):
    a = i * 30 + 15
    for r in range(10, 80, 10):
        ex = W//2 + math.cos(math.radians(a)) * r
        ey = H-30 + math.sin(math.radians(a)) * r
        draw.ellipse([ex-2, ey-2, ex+2, ey+2], fill=(255, 230, 120))
# Rising sun
for r in range(35, 5, -2):
    bright = 255 - (35-r) * 3
    draw.ellipse([W//2-r, H-30-r, W//2+r, H-30+r], fill=(255, bright, 80))
img.save(f"{OUT}/mood_prime.png", optimize=True)

# === Burnout: calming teal/green with gold highlights (motivating recovery) ===
img = line_gradient(W, H, 45, [(0, (15,40,35)), (0.3, (30,80,60)), (0.6, (60,120,80)), (0.8, (100,150,110)), (1, (50,90,65))])
draw = ImageDraw.Draw(img)
# Fracture/leaf-like patterns
for _ in range(8):
    x0, y0 = random.randint(50, W-50), random.randint(50, H-50)
    for branch in range(5):
        angle = random.randint(0, 360)
        length = random.randint(20, 60)
        x1 = x0 + math.cos(math.radians(angle)) * length
        y1 = y0 + math.sin(math.radians(angle)) * length
        draw.line([(x0, y0), (x1, y1)], fill=(180, 200, 140, 100), width=2)
        for sub in range(3):
            sa = angle + random.randint(-40, 40)
            sl = length * 0.4
            sx = x1 + math.cos(math.radians(sa)) * sl
            sy = y1 + math.sin(math.radians(sa)) * sl
            draw.line([(x1, y1), (sx, sy)], fill=(150, 180, 120, 80), width=1)
# Gold highlight dots
for _ in range(30):
    x = random.randint(0, W)
    y = random.randint(0, H)
    draw.ellipse([x-1, y-1, x+1, y+1], fill=(220, 200, 100))
img.save(f"{OUT}/mood_burnout.png", optimize=True)

# === Wired: violet/cyan energy with geometric bursts ===
img = radial_gradient(W, H, W*0.7, H*0.3, [(0, (50,10,80)), (0.4, (30,40,100)), (0.7, (20,70,120)), (1, (5,20,40))])
draw = ImageDraw.Draw(img)
# Geometric burst
for i in range(24):
    a = i * 15
    x0, y0 = W//2, H//2 - 30
    for r in range(10, 100, 8):
        x = x0 + math.cos(math.radians(a)) * r
        y = y0 + math.sin(math.radians(a)) * r
        draw.ellipse([x-1, y-1, x+1, y+1], fill=(150+r, 80+r//2, 255-r))
# Connecting lines
for i in range(12):
    a1 = i * 30
    a2 = (i * 30 + 150) % 360
    x1 = W//2 + math.cos(math.radians(a1)) * 100
    y1 = H//2-30 + math.sin(math.radians(a1)) * 100
    x2 = W//2 + math.cos(math.radians(a2)) * 100
    y2 = H//2-30 + math.sin(math.radians(a2)) * 100
    draw.line([(x1, y1), (x2, y2)], fill=(100, 150, 255, 60), width=1)
img.save(f"{OUT}/mood_wired.png", optimize=True)

# === Launcher Icon: clean cheerful logo ===
img = Image.new("RGB", (80, 80), (0, 0, 0))
draw = ImageDraw.Draw(img)
# Outer ring
draw.ellipse([2, 2, 78, 78], outline=(255, 255, 255), width=3)
# Stylized "C" as a smile
draw.arc([10, 15, 70, 65], 200, 340, fill=(255, 255, 255), width=4)
# Eye dots
draw.ellipse([23, 28, 30, 35], fill=(255, 255, 255))
draw.ellipse([50, 28, 57, 35], fill=(255, 255, 255))
# Small sparkle
draw.line([65, 10, 70, 15], fill=(255, 255, 200), width=2)
draw.line([62, 13, 73, 13], fill=(255, 255, 200), width=2)
draw.line([68, 8, 68, 18], fill=(255, 255, 200), width=2)
img.save(f"{OUT}/launcher_icon.png", optimize=True)

for f in os.listdir(OUT):
    print(f"  {f}: {os.path.getsize(f'{OUT}/{f}')} bytes")
print("Done.")
