from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1024, 1536
FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"
FONTS = {
    "COMMON": {"outer": (24, 84, 104), "edge": (54, 195, 204), "inner": (6, 56, 73), "glow": (32, 165, 177), "star": (103, 166, 194), "label": (18, 116, 145)},
    "RARE": {"outer": (49, 47, 128), "edge": (109, 123, 255), "inner": (31, 24, 97), "glow": (88, 74, 208), "star": (176, 162, 255), "label": (80, 69, 185)},
    "EPIC": {"outer": (68, 35, 132), "edge": (190, 113, 255), "inner": (39, 19, 91), "glow": (148, 70, 218), "star": (255, 199, 63), "label": (126, 59, 189)},
    "LEGENDARY": {"outer": (95, 52, 12), "edge": (255, 200, 67), "inner": (69, 29, 8), "glow": (240, 150, 22), "star": (255, 205, 43), "label": (179, 100, 14)},
}

def font(size):
    return ImageFont.truetype(FONT_BOLD, size)

def centered_text(draw, xy, text, fnt, fill, stroke=0, stroke_fill=(0,0,0,180)):
    draw.text(xy, text, font=fnt, fill=fill, anchor="mm", stroke_width=stroke, stroke_fill=stroke_fill)

def star_points(cx, cy, ro, ri, start=-90):
    import math
    pts=[]
    for i in range(10):
        angle=math.radians(start+i*36)
        rad=ro if i%2==0 else ri
        pts.append((cx+math.cos(angle)*rad, cy+math.sin(angle)*rad))
    return pts

def draw_card(illustration_path, output_path, name, rarity, stars):
    theme=FONTS[rarity]
    card=Image.new("RGBA",(W,H),(0,0,0,0))
    d=ImageDraw.Draw(card)
    # Reusable rarity-family frame geometry.
    d.rounded_rectangle((18,18,1006,1518),radius=84,fill=(*theme["outer"],255))
    d.rounded_rectangle((31,31,993,1505),radius=76,outline=(*theme["edge"],255),width=10)
    d.rounded_rectangle((51,51,973,1485),radius=64,fill=(12,19,36,255),outline=(255,255,255,150),width=3)
    # Interior art atmosphere, fully contained inside the card silhouette.
    for y in range(72,1464):
        t=(y-72)/(1464-72)
        c=tuple(int(theme["inner"][k]*(1-t)+theme["outer"][k]*t*0.33) for k in range(3))
        d.line((68,y,956,y),fill=(*c,255))
    # Gentle rarity-colored halos behind the generated subject.
    glow=Image.new("RGBA",(W,H),(0,0,0,0)); gd=ImageDraw.Draw(glow)
    gd.ellipse((112,350,912,1170),fill=(*theme["glow"],54))
    glow=glow.filter(ImageFilter.GaussianBlur(96))
    card=Image.alpha_composite(card,glow); d=ImageDraw.Draw(card)
    # Fine inset trim and restrained corner accents.
    d.rounded_rectangle((68,68,956,1468),radius=48,outline=(*theme["edge"],175),width=3)
    for cx,cy in ((104,108),(920,108),(104,1428),(920,1428)):
        d.ellipse((cx-7,cy-7,cx+7,cy+7),fill=(*theme["edge"],235))
    # Star row and rarity plaque use deterministic exact text/treatment.
    spacing=68
    start=W/2-(stars-1)*spacing/2
    for i in range(stars):
        cx=start+i*spacing
        pts=star_points(cx,211,27,12)
        d.polygon([(x+2,y+4) for x,y in pts],fill=(0,0,0,150))
        d.polygon(pts,fill=(*theme["star"],255),outline=(255,244,198,255))
        d.line(pts+[pts[0]],fill=(255,248,221,230),width=2)
    d.rounded_rectangle((286,256,738,330),radius=34,fill=(*theme["label"],255),outline=(*theme["edge"],255),width=4)
    centered_text(d,(512,293),rarity.title(),font(39),(255,255,255,255),stroke=2,stroke_fill=(0,0,0,190))
    # Card-specific illustration, generated independently and composed into the family frame.
    art=Image.open(illustration_path).convert("RGBA")
    alpha=art.getchannel("A")
    bbox=alpha.getbbox()
    if not bbox:
        raise ValueError(f"Empty illustration: {illustration_path}")
    l,t,r,b=bbox
    pad=20
    bbox=(max(0,l-pad),max(0,t-pad),min(art.width,r+pad),min(art.height,b+pad))
    art=art.crop(bbox)
    art.thumbnail((850,925),Image.Resampling.LANCZOS)
    x=(W-art.width)//2
    y=354+(925-art.height)//2
    card.alpha_composite(art,(x,y))
    d=ImageDraw.Draw(card)
    # Bottom name field is shared across rarities; font shrinks only as needed.
    d.rounded_rectangle((94,1300,930,1444),radius=42,fill=(10,19,36,235),outline=(*theme["edge"],255),width=5)
    size=68
    while size>36 and d.textbbox((0,0),name,font=font(size),stroke_width=1)[2]>770:
        size-=2
    centered_text(d,(512,1372),name,font(size),(255,255,255,255),stroke=2,stroke_fill=(0,0,0,210))
    # Restore crisp outer silhouette after glow and compositing.
    silhouette=Image.new("L",(W,H),0); sd=ImageDraw.Draw(silhouette)
    sd.rounded_rectangle((18,18,1006,1518),radius=84,fill=255)
    card.putalpha(Image.composite(card.getchannel("A"),Image.new("L",(W,H),0),silhouette))
    card.save(output_path,format="PNG",optimize=True)

def main():
    import sys
    if len(sys.argv) == 6:
        draw_card(Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3], sys.argv[4].upper(), int(sys.argv[5]))
        return
    root=Path(__file__).resolve().parent
    pilots=[
        ("pilot_01_common_scrubby_illustration.png","pilot_01_common_scrubby.png","Scrubby","COMMON",2),
        ("pilot_02_rare_squeegee_illustration.png","pilot_02_rare_squeegee.png","Squeegee","RARE",2),
        ("pilot_03_epic_turbo_scrubby_illustration.png","pilot_03_epic_turbo_scrubby.png","Turbo Scrubby","EPIC",3),
        ("pilot_04_legendary_scrubmaster_x_illustration.png","pilot_04_legendary_scrubmaster_x.png","Scrubmaster X","LEGENDARY",4),
    ]
    for src,dst,name,rarity,stars in pilots:
        draw_card(root/src,root/dst,name,rarity,stars)
        im=Image.open(root/dst)
        print(f"{dst}: {im.width}x{im.height} {im.mode} alpha_bbox={im.getchannel('A').getbbox()}")

if __name__=="__main__":
    main()