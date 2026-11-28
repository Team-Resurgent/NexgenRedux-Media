// A console home of channels, in the style of its time: an orange sky fading to red with rings of dots in it, a
// polished silver floor that the cards stand on and are reflected in, ripples that spread across the floor from an
// emblem in the corner, and channels named at the top left, one above the other. Each channel is a row of cards that
// recede into the distance; the front one is chosen, and opens its demo.

// One of the bubbles in the sky: a soft disc with a ring and a dot at its middle, a ring alone, rings within rings,
// or a dot; where, how large, how faint, and its drift.
class Bubble
{
    Vec2 at;
    float size, alpha, seed;
    int kind;
}

class Card
{
    string id, title, about;
    Texture@ art;
}

class Lane
{
    string name;
    array<Card@> cards;
    int focus = 0;
    float at = 0;       // where the row has slid to, following focus
}

const float CardWide = 410;
const float CardHigh = 312;

class ChannelsScreen : Screen
{
    Font@ huge = Assets::font("global:freesans.sfn", 40);
    Font@ big = Assets::font("global:freesans.sfn", 30);
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ small = Assets::font("global:freesans.sfn", 19);
    Font@ tiny = Assets::font("global:freesans.sfn", 16);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ slide = Assets::sound("global:sound/whoosh.wav");
    Sound@ yes = Assets::sound("global:sound/accept.wav");
    Sound@ back = Assets::sound("global:sound/back.wav");
    Texture@ avatar = Assets::texture("global:picture/avatar.png");
    Texture@ stage = Assets::texture("asset:stage.png");
    Texture@ stageGlow = Assets::texture("asset:stage-glow.png");
    Texture@ cardShape = Assets::texture("asset:card.png");   // white, with soft round corners
    array<Lane@> channels;
    int channel = 2;
    float channelAt = 2;  // follows channel, for the names and cards to slide
    float launching = -1;
    float coming = 0;
    string launchId;
    Texture@ launchArt;
    float time = 0;
    array<Bubble@> bubbles;
    // The bubbles' shapes, drawn once each into a small picture: a disc, a fine ring and a thick one. Each bubble is
    // then a few squares of them, rather than circles of many sides each frame, which the original Xbox can't afford.
    Texture@ discShape;
    Texture@ ringShape;
    Texture@ thickShape;
    bool shapesMade = false;
    array<float> rings;       // when each ripple began
    float nextRing = 0;
    float RingLife = 4.5f;

    void onEnter()
    {
        // The bubbles gather in clusters towards the corners and edges, many small and a few large.
        Random r(11);
        array<Vec2> clusters = { Vec2(380, 60), Vec2(1180, 170), Vec2(900, 250), Vec2(60, 250), Vec2(700, 20), Vec2(1240, 40) };
        array<float> spread = { 150, 120, 120, 80, 120, 70 };
        for (uint k = 0; k < clusters.length(); k++)
            for (int i = 0; i < 36; i++)
            {
                Bubble b;
                b.at = clusters[k] + Vec2(r.normal(0, spread[k]), r.normal(0, spread[k] * 0.7f));
                float big = r.random();
                b.size = big > 0.9f ? r.random(30, 44) : big > 0.65f ? r.random(14, 26) : r.random(4, 12);
                b.alpha = r.random(0.2f, 0.55f);
                b.seed = r.random(0, 100);
                b.kind = b.size > 28 ? 0 : r.randomInt(0, 3);
                bubbles.insertLast(b);
            }

        addChannel("Show", { "cracktro", "lights", "solids", "topple", "moves" });
        addChannel("Games", { "shooter", "platformer", "quest", "skim", "guards" });
        addChannel("Welcome", { "explore", "lens", "machines", "curves" });
        addChannel("Worlds", { "forest", "water", "mist", "blocks" });
        addChannel("System", { "settings", "main", "home", "hub" });
    }

    void addChannel(const string &in name, const array<string> &in ids)
    {
        Lane ch;
        ch.name = name;
        for (uint i = 0; i < ids.length(); i++)
        {
            Card k;
            k.id = ids[i];
            k.title = ids[i];
            if (k.title[0] >= 97 && k.title[0] <= 122) k.title[0] = k.title[0] - 32;
            k.about = "";
            for (uint s = 0; s < Screens::count; s++)
                if (Screens::id(s) == ids[i])
                {
                    k.title = Screens::title(s);
                    k.about = Screens::description(s);
                }
            if (ids[i] == "main") { k.title = "Every demo"; k.about = Screens::count + " of them, of every kind"; }
            @k.art = Assets::texture("global:picture/demos/" + ids[i] + ".jpg");
            ch.cards.insertLast(k);
        }
        channels.insertLast(ch);
    }

    void onResume()
    {
        launching = -1;
        coming = 1;
    }

    void update(float dt)
    {
        time += dt;
        coming = max(coming - dt * 3, 0);
        if (time >= nextRing)
        {
            rings.insertLast(time);
            nextRing = time + random(0.12f, 0.9f);
        }
        while (rings.length() > 0 && time - rings[0] > RingLife)
            rings.removeAt(0);
        channelAt += (float(channel) - channelAt) * clamp(dt * 9, 0, 1);
        for (uint i = 0; i < channels.length(); i++)
            channels[i].at += (float(channels[i].focus) - channels[i].at) * clamp(dt * 9, 0, 1);

        if (launching >= 0)
        {
            launching += dt * 2.6f;
            if (launching >= 1)
            {
                launching = 2;
                Screens::push(launchId);
            }
            return;
        }

        Lane@ ch = channels[uint(channel)];
        if (Input::repeated("right") && ch.focus + 1 < int(ch.cards.length())) { ch.focus++; move.play(0.45f); }
        if (Input::repeated("left") && ch.focus > 0) { ch.focus--; move.play(0.45f); }
        if (Input::repeated("down") && channel + 1 < int(channels.length())) { channel++; slide.play(0.35f, 0, 1.3f); }
        if (Input::repeated("up") && channel > 0) { channel--; slide.play(0.35f, 0, 1.1f); }
        if (Input::pressed("cancel")) { back.play(0.4f); Screens::pop(); }
        if (Input::pressed("accept"))
        {
            Card@ k = ch.cards[uint(ch.focus)];
            yes.play(0.6f);
            Input::rumble(0.25f, 0.12f);
            launchId = k.id;
            @launchArt = k.art;
            launching = 0;
        }
    }

    // --- Drawing ---

    // Orange glowing in the middle, deep red towards the edges, a touch of violet in the far corner, and bubbles.
    void sky(Canvas@ c)
    {
        c.rect(0, 0, 1280, 720, Color(0.45f, 0.08f, 0.03f));
        c.blend = BlendAdd;
        c.glow(700, 300, 760, fade(Color(0.85f, 0.32f, 0.02f), 0.9f));
        c.glow(740, 280, 420, fade(Color(1, 0.6f, 0.1f), 0.55f));
        c.glow(1280, 0, 420, fade(Color(0.35f, 0.15f, 0.45f), 0.5f));
        c.blend = BlendAlpha;
        for (uint i = 0; i < bubbles.length(); i++)
        {
            Bubble@ b = bubbles[i];
            Vec2 at = b.at + Vec2(sin(time * 0.15f + b.seed) * 10, cos(time * 0.12f + b.seed * 1.3f) * 8);
            float a = b.alpha * (0.85f + 0.15f * sin(time * 0.5f + b.seed));
            Color tint = Color(1, 0.93f, 0.85f);
            if (b.kind == 0)
            {
                shape(c, discShape, at, b.size, fade(tint, 0.35f * a));
                shape(c, ringShape, at, b.size, fade(tint, 0.7f * a));
                shape(c, ringShape, at, b.size + 4, fade(tint, 0.3f * a));
                shape(c, discShape, at, max(2.0f, b.size * 0.1f), fade(Color(0.4f, 0.1f, 0.05f), 0.8f * a));
            }
            else if (b.kind == 1)
                shape(c, thickShape, at, b.size, fade(tint, 0.6f * a));
            else if (b.kind == 2)
            {
                shape(c, ringShape, at, b.size, fade(tint, 0.55f * a));
                shape(c, ringShape, at, b.size * 0.6f, fade(tint, 0.45f * a));
                shape(c, discShape, at, b.size * 0.3f, fade(tint, 0.35f * a));
            }
            else
                shape(c, discShape, at, b.size * 0.6f, fade(tint, 0.5f * a));
        }
    }

    // One of the shapes, as large as a radius, tinted.
    void shape(Canvas@ c, Texture@ t, const Vec2 &in at, float radius, const Color &in tint)
    {
        float half = radius * 64 / 56;   // the shapes are drawn 56 across a picture 128 wide, with room for their edges
        c.image(t, at.x - half, at.y - half, half * 2, half * 2, tint);
    }

    // Draws the three shapes into their pictures, once, before anything else is drawn.
    void makeShapes(Canvas@ c)
    {
        shapesMade = true;
        @discShape = Assets::picture(128, 128);
        @ringShape = Assets::picture(128, 128);
        @thickShape = Assets::picture(128, 128);
        if (discShape is null || ringShape is null || thickShape is null) return;
        if (c.beginPicture(discShape)) { c.circle(64, 64, 56, White); c.endPicture(); }
        if (c.beginPicture(ringShape)) { c.ring(64, 64, 56, 4, White); c.endPicture(); }
        if (c.beginPicture(thickShape)) { c.ring(64, 64, 56, 13, White); c.endPicture(); }
    }

    // The floor: the stage from the Xperience skin (see asset/CREDITS.txt), tinted grey as the skin tints it, raised
    // so that its far edge meets the foot of the cards, with its soft glow along that edge.
    void floor(Canvas@ c)
    {
        c.image(stage, 0, 322, 1280, 398, Color(0.553f, 0.553f, 0.553f));
        c.image(stageGlow, 0, 322, 1280, 398, White);
    }

    // Rings that spread out across the floor from the emblem, flattened as the floor is, fading as they go; and the
    // emblem: a glossy green orb in a polished silver rim, with a bold N of our own.
    void ripplesAndEmblem(Canvas@ c)
    {
        float x = 1150, y = 666;
        // Rings one at a time, at moments of their own, each spreading and fading.
        // Fine, but never thinner than a pixel and a half of the real screen, or a small one loses them.
        float fine = max(1.3f, 1.5f * 1280.0f / max(1.0f, float(Window::width)));
        for (uint i = 0; i < rings.length(); i++)
        {
            float age = time - rings[i];
            float a = 1 - age / RingLife;
            float r = 26 + age * 70;
            c.ellipseLine(x, y, r, r * 0.25f, fine, fade(White, 0.6f * a * a));
        }
        c.ellipse(x, y + 12, 40, 10, fade(Black, 0.3f));
        // The rim: silver, lighter above, darker below.
        // The rim: silver, fading softly away at its outside edge.
        c.glow(x, y - 16, 50, fade(Color(0.95f, 0.96f, 0.98f), 0.75f));
        c.glow(x, y - 16, 40, fade(Color(0.95f, 0.96f, 0.98f), 0.7f));
        c.circle(x, y - 16, 31, fade(Color(0.9f, 0.91f, 0.94f), 0.85f));
        c.circle(x, y - 15, 28, Color(0.6f, 0.61f, 0.65f));
        // The orb, lit from above.
        c.circle(x, y - 16, 26, Color(0.18f, 0.5f, 0.08f));
        c.circle(x, y - 18, 23, Color(0.32f, 0.72f, 0.12f));
        c.blend = BlendAdd;
        c.glow(x, y - 10, 22, fade(Color(0.5f, 1, 0.3f), 0.5f));
        c.blend = BlendAlpha;
        // A bold N: two uprights and a slant, slightly rounded at the ends.
        Color w(1, 1, 1, 0.96f);
        c.roundRect(x - 13, y - 30, 7, 27, 2, w);
        c.roundRect(x + 6, y - 30, 7, 27, 2, w);
        array<Vec2> slant = { Vec2(x - 13, y - 30), Vec2(x - 6, y - 30), Vec2(x + 13, y - 3), Vec2(x + 6, y - 3) };
        c.polygon(slant, w);
        // The shine across its top.
        c.ellipse(x - 4, y - 30, 15, 7, fade(White, 0.4f));
    }

    // A card: a picture across its top, lime below it with its words; where, and how large.
    // Four corners, kept, for drawing a part of a card with a colour at its top and another at its bottom.
    array<Vec2> corners(4), cornerUvs(4);
    array<Color> cornerColors(4);
    array<uint> twoTriangles = { 0, 1, 2, 0, 2, 3 };

    void part(Canvas@ c, Texture@ art, float x, float y, float w, float h, const Color &in top, const Color &in bottom, float v0 = 0, float v1 = 1)
    {
        corners[0] = Vec2(x, y); corners[1] = Vec2(x + w, y); corners[2] = Vec2(x + w, y + h); corners[3] = Vec2(x, y + h);
        cornerUvs[0] = Vec2(0, v0); cornerUvs[1] = Vec2(1, v0); cornerUvs[2] = Vec2(1, v1); cornerUvs[3] = Vec2(0, v1);
        cornerColors[0] = top; cornerColors[1] = top; cornerColors[2] = bottom; cornerColors[3] = bottom;
        c.mesh(art, corners, cornerUvs, White, twoTriangles, cornerColors);
    }

    // How solid a card is at a height through it, 0 its top and 1 its bottom, between how solid its top and bottom are.
    float through(float t, float top, float bottom) { return top + (bottom - top) * t; }

    // A card at its size: bright lime, lighter at its top, in a shape with soft round corners; bubbles faint across it as
    // in the sky; a light bevel along its top; its demo's picture in its upper part, and its name at the bottom left.
    void card(Canvas@ c, Card@ k, float x, float y, float s, float top, float bottom, bool words, bool front)
    {
        float w = CardWide * s, h = CardHigh * s;
        part(c, cardShape, x, y, w, h, fade(Color(0.84f, 0.94f, 0.3f), top), fade(Color(0.36f, 0.62f, 0.06f), bottom));
        // Bubbles across it, faint, as light through a pattern.
        c.clip(x + 4 * s, y + 4 * s, w - 8 * s, h - 8 * s);
        for (uint i = 0; i < 14; i++)
        {
            float bx = x + w * ((float(i) * 0.37f + 0.05f) % 1.0f), by = y + h * ((float(i) * 0.61f + 0.2f) % 1.0f);
            float r = (6 + float(i % 5) * 7) * s;
            c.ring(bx, by, r, 1.5f * s, fade(White, 0.13f * top));
            if (i % 3 == 0) c.circle(bx, by, r * 0.5f, fade(White, 0.08f * top));
        }
        c.noClip();
        // A soft bevel: light along the top, a little shade along the bottom.
        c.rect(x + 8 * s, y + 2 * s, w - 16 * s, 2 * s, fade(White, 0.5f * top));
        part(c, cardShape, x, y + h * 0.82f, w, h * 0.18f, fade(Black, 0), fade(Black, 0.18f * bottom));
        // Its picture, set into the upper part.
        float inset = 14 * s, pictureHigh = h * 0.56f;
        if (k.art.width > 0)
        {
            c.rect(x + inset - 2 * s, y + inset - 2 * s, w - inset * 2 + 4 * s, pictureHigh - inset + 4 * s, fade(White, 0.35f * top));
            part(c, k.art, x + inset, y + inset, w - inset * 2, pictureHigh - inset, fade(White, top), fade(White, top), 0.2f, 0.8f);
        }
        if (words && s > 0.5f)
        {
            c.push();
            c.translate(x + 16 * s, y + pictureHigh + 12 * s);
            c.scale(s, s);
            c.text(big, k.title, 0, 0, fade(White, top));
            if (front) c.paragraph(small, k.about, 1, 42, CardWide - 32, fade(White, 0.9f * top));
            c.pop();
        }
    }

    // Where each card stands: the chosen at the front, the rest side by side to its right, each smaller than the one
    // before, all centred on nearly the same line; those before it slide away to the left.
    void slot(float place, float &out x, float &out y, float &out s)
    {
        if (place < 0)
        {
            s = 1;
            x = 96 + place * (CardWide + 40);
            y = 348 - CardHigh * 0.5f;
            return;
        }
        s = 1 / (1 + place * 0.355f);
        x = 96;
        for (float p = 0; p < place; p += 1)
            x += (CardWide / (1 + p * 0.355f) + 3) * min(1.0f, place - p);
        y = 348 - 5 * min(place, 3.0f) - CardHigh * s * 0.5f;
    }

    void row(Canvas@ c, Lane@ ch, float offsetY, float alpha)
    {
        // From the back to the front, so the nearer cover the further.
        for (int i = int(ch.cards.length()) - 1; i >= 0; i--)
        {
            float place = float(i) - ch.at;
            if (place > 4.5f) continue;
            float x, y, s;
            slot(place, x, y, s);
            if (x > 1300) continue;
            float a = alpha * (place < 0 ? max(0.0f, 1 + place * 1.5f) : 1);
            if (a <= 0.01f) continue;
            y += offsetY;
            bool front = abs(place) < 0.5f;
            // Its reflection in the floor: a short grey glow under it, faintly green, gone a third of its height down.
            float bottom = y + CardHigh * s;
            part(c, null, x, bottom + 3, CardWide * s, CardHigh * s * 0.34f, Color(0.82f, 0.86f, 0.78f, 0.42f * a), Color(0.75f, 0.76f, 0.76f, 0));
            card(c, ch.cards[uint(i)], x, y, s, a, a, true, front);
        }
    }

    void draw(Canvas@ c)
    {
        if (!shapesMade) makeShapes(c);
        c.design(1280, 720);
        sky(c);
        floor(c);

        // Channels named at the top left: the one chosen large, those before it above, smaller and fainter.
        for (uint i = 0; i < channels.length(); i++)
        {
            float place = float(i) - channelAt;
            if (place > 0.6f) continue;
            float y = 104 + place * 34 - (place < -0.5f ? 10 : -10 * place);   // a gap between the names above and the chosen
            if (y < -10) continue;
            float near = 1 - min(abs(place), 1.0f);
            if (near > 0.5f) c.text(huge, channels[i].name, 62, y - 12, fade(White, near));
            else c.text(small, channels[i].name, 64, y + 4, fade(White, 0.6f + 0.2f * near));
        }

        // The row of the channel chosen, and the next sliding in or out as the channel changes.
        for (uint i = 0; i < channels.length(); i++)
        {
            float place = float(i) - channelAt;
            if (abs(place) > 1) continue;
            row(c, channels[i], place * 420, 1 - abs(place));
        }

        // The reflections fade into the polish further down; the emblem and its ripples are on top of that.
        ripplesAndEmblem(c);

        Lane@ ch = channels[uint(channel)];
        c.text(small, (ch.focus + 1) + " of " + ch.cards.length(), 98, 512, fade(Color(0.15f, 0.15f, 0.17f), 0.85f));

        // Who is here, at the top right.
        c.text(font, "Player One", 1150, 30, White, AlignRight);
        c.text(small, "12 340", 1150, 60, fade(White, 0.85f), AlignRight);
        c.image(avatar, 1164, 30, 48, 48);
        c.ring(1188, 54, 25, 2, fade(White, 0.75f));

        // What the buttons do.
        c.circle(78, 668, 11, Color(0.3f, 0.75f, 0.15f));
        c.text(tiny, "A", 78, 659, White, AlignCenter);
        c.text(small, "Select", 98, 657, Color(0.2f, 0.2f, 0.25f));
        c.circle(198, 668, 11, Color(0.85f, 0.2f, 0.15f));
        c.text(tiny, "B", 198, 659, White, AlignCenter);
        c.text(small, "Back", 218, 657, Color(0.2f, 0.2f, 0.25f));

        float grow = launching >= 0 ? smooth(min(launching, 1)) : coming > 0 ? smooth(coming) : 0;
        if (grow > 0)
        {
            Vec2 from(96, 348 - CardHigh * 0.5f), size(CardWide, CardHigh);
            Vec2 at = from * (1 - grow);
            Vec2 big = size + (Vec2(1280, 720) - size) * grow;
            if (launchArt !is null && launchArt.width > 0) c.image(launchArt, at.x, at.y, big.x, big.y, White);
            else c.rect(at.x, at.y, big.x, big.y, Color(0.45f, 0.72f, 0.12f));
            c.rect(0, 0, 1280, 720, fade(Black, grow * 0.6f));
        }
    }
}
