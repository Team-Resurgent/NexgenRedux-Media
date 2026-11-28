// A console's home in the modern style. Ribbons of light drift behind everything; a row of square tiles, the one in focus grown large with its name, and cards below; round buttons at the
// top, a clock, and a guide that slides in from the side. The tiles are this showcase's own demos, and choosing one
// opens it, growing to fill the screen as it goes.

class Tile
{
    string id, title, about, kind;
    Texture@ art;
    float lift = 0;     // 0 to 1, as it takes the focus
}

class Card
{
    string title, about, open;
    array<Texture@> art;
    float lift = 0;
}

class Ribbon
{
    float base, spread, speed, phase, thickness;
    Color color;
}

const float Small = 128;      // a tile, as it rests
const float Large = 214;      // the one in focus
const float Gap = 18;
const float RowBottom = 470;  // tiles grow upwards from here
const float CardTop = 494;
const float CardWide = 274;
const float CardHigh = 150;

class HomeScreen : Screen
{
    Font@ huge = Assets::font("global:freesans.sfn", 46);
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ small = Assets::font("global:freesans.sfn", 19);
    Font@ tiny = Assets::font("global:freesans.sfn", 16);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ yes = Assets::sound("global:sound/accept.wav");
    Sound@ back = Assets::sound("global:sound/back.wav");
    Sound@ whoosh = Assets::sound("global:sound/whoosh.wav");
    Texture@ avatar = Assets::texture("asset:avatar.png");
    array<string> ids = { "explore", "lens", "moves", "blocks", "forest", "water", "skim", "topple", "quest", "guards", "machines", "curves", "shooter", "mist", "lights", "solids", "platformer", "cracktro" };
    array<Tile@> tiles;
    array<Card@> cards;
    array<Ribbon@> ribbons;
    array<string> buttons = { "My demos", "New", "Search", "Settings" };
    int row = 0;          // -1 the buttons, 0 the tiles, 1 the cards
    int tile = 0, card = 0, button = 0;
    float scroll = 0;
    float guide = 0;
    bool guideOpen = false;
    int guideRow = 0;
    array<string> guideRows = { "Home", "Every demo", "Settings", "Start again" };
    float launching = -1;
    float coming = 0;
    string launchId;
    Texture@ launchArt;
    Vec2 launchFrom, launchSize;
    float time = 0;

    void onEnter()
    {
        for (uint i = 0; i < ids.length(); i++)
        {
            Tile t;
            t.id = ids[i];
            // Its own name until the demo's screen.json says better: a build without that demo still shows one.
            t.title = ids[i];
            if (t.title[0] >= 97 && t.title[0] <= 122) t.title[0] = t.title[0] - 32;
            t.kind = "Demo";
            @t.art = Assets::texture("asset:" + ids[i] + ".jpg");
            for (uint s = 0; s < Screens::count; s++)
                if (Screens::id(s) == ids[i])
                {
                    t.title = Screens::title(s);
                    t.about = Screens::description(s);
                    t.kind = Screens::category(s);
                }
            tiles.insertLast(t);
        }
        tiles[0].lift = 1;
        addCard("Every demo", Screens::count + " of them, of every kind", "main", { tiles[0].art, tiles[3].art, tiles[8].art, tiles[12].art });
        addCard("Make it yours", "Sound, controls and how it looks", "settings", {});
        addCard("New: Machines", "Wheels, pulleys and gears", "machines", { tiles[10].art });
        addCard("New: Curves", "Fifteen hundred sprites at once", "curves", { tiles[11].art });

        // The ribbons: wide bands of light that sweep down and across, each its own speed.
        for (int i = 0; i < 4; i++)
        {
            Ribbon r;
            r.base = float(i) / 3.0f;
            r.spread = 0.8f + float(i) * 0.12f;
            r.speed = 0.3f + float(i) * 0.06f;
            r.phase = float(i) * 17.3f;
            r.thickness = 150 + float(i % 2) * 90;
            r.color = hsv(0.33f + float(i) * 0.012f, 0.75f, 0.32f + float(i) * 0.06f);
            ribbons.insertLast(r);
        }
        prepareRibbons();
    }

    void addCard(const string &in title, const string &in about, const string &in open, const array<Texture@> &in art)
    {
        Card c;
        c.title = title;
        c.about = about;
        c.open = open;
        c.art = art;
        cards.insertLast(c);
    }

    void onResume()
    {
        launching = -1;
        coming = 1;
    }

    void focusChanged()
    {
        move.play(0.4f);
    }

    // Where a tile's left edge is, along the row as the tiles are now.
    float tileX(int index)
    {
        float x = 64 - scroll;
        for (int i = 0; i < index; i++)
            x += Small + (Large - Small) * tiles[uint(i)].lift + Gap;
        return x;
    }

    void launch(const string &in id, Texture@ art, const Vec2 &in at, const Vec2 &in size)
    {
        yes.play(0.6f);
        Input::rumble(0.25f, 0.12f);
        launchId = id;
        @launchArt = art;
        launchFrom = at;
        launchSize = size;
        launching = 0;
    }

    void update(float dt)
    {
        time += dt;
        guide += ((guideOpen ? 1.0f : 0.0f) - guide) * clamp(dt * 12, 0, 1);
        coming = max(coming - dt * 3, 0);
        for (uint i = 0; i < tiles.length(); i++)
            tiles[i].lift += ((row == 0 && int(i) == tile ? 1.0f : 0.0f) - tiles[i].lift) * clamp(dt * 13, 0, 1);
        for (uint i = 0; i < cards.length(); i++)
            cards[i].lift += ((row == 1 && int(i) == card ? 1.0f : 0.0f) - cards[i].lift) * clamp(dt * 13, 0, 1);
        // Keep the one in focus in sight: from the fifth on, the row slides.
        float want = max(0.0f, float(tile - 3) * (Small + Gap));
        scroll += (want - scroll) * clamp(dt * 9, 0, 1);

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

        if (Input::pressed("menu"))
        {
            guideOpen = !guideOpen;
            whoosh.play(0.35f, -0.6f, guideOpen ? 1.2f : 0.9f);
        }
        if (guideOpen)
        {
            if (Input::repeated("down") && guideRow + 1 < int(guideRows.length())) { guideRow++; move.play(0.4f); }
            if (Input::repeated("up") && guideRow > 0) { guideRow--; move.play(0.4f); }
            if (Input::pressed("cancel") || Input::pressed("left")) { guideOpen = false; back.play(0.4f); }
            if (Input::pressed("accept"))
            {
                yes.play(0.5f);
                guideOpen = false;
                if (guideRow == 1) Screens::home();
                else if (guideRow == 2) Screens::push("settings");
                else if (guideRow == 3) Screens::replace("home");
            }
            return;
        }

        int beforeRow = row, beforeTile = tile, beforeCard = card, beforeButton = button;
        if (Input::repeated("down") && row < 1) row++;
        if (Input::repeated("up") && row > -1) row--;
        int dx = (Input::repeated("right") ? 1 : 0) - (Input::repeated("left") ? 1 : 0);
        if (row == 0) tile = int(clamp(float(tile + dx), 0, float(tiles.length() - 1)));
        else if (row == 1) card = int(clamp(float(card + dx), 0, float(cards.length() - 1)));
        else button = int(clamp(float(button + dx), 0, float(buttons.length() - 1)));
        if (row != beforeRow || tile != beforeTile || card != beforeCard || button != beforeButton) focusChanged();
        if (Input::pressed("cancel")) { back.play(0.4f); Screens::pop(); }

        if (Input::pressed("accept"))
        {
            if (row == 0)
                launch(tiles[uint(tile)].id, tiles[uint(tile)].art, Vec2(tileX(tile), RowBottom - Large), Vec2(Large, Large));
            else if (row == 1)
                launch(cards[uint(card)].open, cards[uint(card)].art.length() == 1 ? cards[uint(card)].art[0] : null, Vec2(64 + float(card) * (CardWide + Gap), CardTop), Vec2(CardWide, CardHigh));
            else if (button == 3)
                launch("settings", null, Vec2(640, 60), Vec2(10, 10));
            else if (button == 1)
                launch("machines", tiles[10].art, Vec2(640, 60), Vec2(10, 10));
            else
                launch("main", null, Vec2(640, 60), Vec2(10, 10));
        }
    }

    // --- Drawing ---

    // Folds of light: each a wide band that sweeps down and across in an S, shaded from its dark side to its lit one,
    // with a fine bright rim where it turns to the light. They drift, slowly, by noise.
    // Kept from frame to frame, so that drawing the ribbons makes nothing new: the points along a ribbon, which way is
    // across it at each, its band's corners, rim and strands, and what never changes, worked out once.
    array<Vec2> along, across, bandPoints, rim, strand, bandUvs;
    array<uint> bandTriangles;
    array<array<Color>> bandColors;
    uint Steps = 24;

    void prepareRibbons()
    {
        along.resize(Steps);
        across.resize(Steps);
        bandPoints.resize(Steps * 2);
        bandUvs.resize(Steps * 2);
        rim.resize(Steps);
        strand.resize(Steps);
        for (uint k = 1; k < Steps; k++)
        {
            uint q = k * 2;
            bandTriangles.insertLast(q - 2); bandTriangles.insertLast(q - 1); bandTriangles.insertLast(q + 1);
            bandTriangles.insertLast(q - 2); bandTriangles.insertLast(q + 1); bandTriangles.insertLast(q);
        }
        for (uint i = 0; i < ribbons.length(); i++)
        {
            Color k = ribbons[i].color;
            array<Color> shade;
            for (uint j = 0; j < Steps; j++)
            {
                shade.insertLast(Color(k.r * 0.45f, k.g * 0.45f, k.b * 0.45f, 0.85f));
                shade.insertLast(Color(min(k.r * 1.5f, 1), min(k.g * 1.5f, 1), min(k.b * 1.5f, 1), 0.85f));
            }
            bandColors.insertLast(shade);
        }
    }

    // Folds of light: each a wide band that sweeps down and across in an S, shaded from its dark side to its lit one,
    // with a fine bright rim where it turns to the light, strands that shimmer beside it, and a light that runs down it.
    void ribbonsBehind(Canvas@ c)
    {
        c.gradient(0, 0, 1280, 720, Color(0.05f, 0.17f, 0.06f), Color(0.02f, 0.08f, 0.03f));
        Curve band;
        for (uint i = 0; i < ribbons.length(); i++)
        {
            Ribbon@ r = ribbons[i];
            float t = time * r.speed + r.phase;
            float x0 = -260 + r.base * 900 + noise(t, 1) * 160 + sin(time * 0.7f + r.phase) * 110;
            band.clear();
            band.add(Vec2(x0, -140));
            band.add(Vec2(x0 + 60 + noise(t, 2) * 220, 330 + noise(t, 3) * 140));
            band.add(Vec2(x0 + 640 * r.spread + noise(t, 4) * 220, 300 + noise(t, 5) * 140));
            band.add(Vec2(x0 + 820 * r.spread + noise(t, 6) * 180, 880));
            for (uint k = 0; k < Steps; k++)
            {
                float u = float(k) / float(Steps - 1);
                along[k] = band.at(u);
                across[k] = band.slope(u).normalized().perpendicular();
                // Wider in the middle of its sweep, as a fold seen side on.
                float half = r.thickness * (0.55f + 0.45f * sin(u * 3.14159f));
                bandPoints[k * 2] = along[k] - across[k] * half;
                rim[k] = along[k] + across[k] * half;
                bandPoints[k * 2 + 1] = rim[k];
            }
            c.mesh(null, bandPoints, bandUvs, White, bandTriangles, bandColors[i]);
            c.blend = BlendAdd;
            c.polyline(rim, 14, fade(Color(0.45f, 1, 0.5f), 0.08f));
            c.polyline(rim, 5, fade(Color(0.6f, 1, 0.65f), 0.18f));
            c.blend = BlendAlpha;
            c.polyline(rim, 2, fade(Color(0.92f, 1, 0.93f), 0.8f));
            // Fine strands beside the rim, each swaying at its own pace, so that the edge shimmers.
            for (int n = 1; n <= 2; n++)
            {
                float pace = time * (1.1f + float(n) * 0.5f) + float(n) * 2;
                for (uint k = 0; k < Steps; k++)
                    strand[k] = rim[k] - across[k] * (float(n) * 18 + sin(float(k) * 0.4f + pace) * 10);
                c.polyline(strand, 1.5f, fade(Color(0.8f, 1, 0.82f), 0.26f - float(n) * 0.07f));
            }
            // A light that runs down its rim, again and again.
            float run = (time * 0.35f + r.phase * 0.13f) % 1.4f - 0.2f;
            c.blend = BlendAdd;
            for (uint k = 0; k < Steps; k++)
            {
                float d = abs(float(k) / float(Steps - 1) - run);
                if (d < 0.12f) c.glow(rim[k].x, rim[k].y, 60, fade(Color(0.75f, 1, 0.8f), 0.4f * (1 - d / 0.12f)));
            }
            c.blend = BlendAlpha;
        }
    }

    void profile(Canvas@ c, float x, float y)
    {
        float r = 26;
        c.circle(x + r, y + r + 2, r + 3, fade(Black, 0.4f));
        c.image(avatar, x, y, r * 2, r * 2);
        c.ring(x + r, y + r, r + 1.5f, 3, Color(0.4f, 0.9f, 0.5f));
        c.text(small, "Player One", x + r * 2 + 14, y + 4, White);
        c.circle(x + r * 2 + 20, y + 40, 4, Color(0.4f, 0.95f, 0.5f));
        c.text(tiny, "12 340", x + r * 2 + 30, y + 31, fade(White, 0.75f));
    }

    void glyph(Canvas@ c, int which, float x, float y, const Color &in k)
    {
        if (which == 0)   // demos: four squares
        {
            for (int i = 0; i < 4; i++)
                c.rect(x - 9 + float(i % 2) * 10, y - 9 + float(i / 2) * 10, 8, 8, k);
        }
        else if (which == 1)   // new: a star
        {
            array<Vec2> star;
            for (int i = 0; i < 10; i++)
                star.insertLast(Vec2(x, y) + Vec2(0, i % 2 == 0 ? -11.0f : -5.0f).rotated(float(i) * 36));
            c.polygon(star, k);
        }
        else if (which == 2)   // search: a lens and its handle
        {
            c.ring(x - 2, y - 2, 7, 2.5f, k);
            c.line(x + 3, y + 3, x + 9, y + 9, 3, k);
        }
        else   // settings: a cog
        {
            c.ring(x, y, 6, 3, k);
            for (int i = 0; i < 8; i++)
            {
                Vec2 a = Vec2(x, y) + Vec2(8, 0).rotated(float(i) * 45);
                Vec2 b = Vec2(x, y) + Vec2(11, 0).rotated(float(i) * 45);
                c.line(a.x, a.y, b.x, b.y, 3, k);
            }
        }
    }

    void topBar(Canvas@ c)
    {
        profile(c, 64, 30);
        // Round buttons in the middle, the one in focus ringed and named.
        for (uint i = 0; i < buttons.length(); i++)
        {
            float x = 640 - 1.5f * 62 + float(i) * 62, y = 56;
            bool on = row == -1 && int(i) == button;
            c.circle(x, y, 23, on ? Color(0.12f, 0.35f, 0.16f, 0.95f) : fade(Black, 0.35f));
            if (on) c.ring(x, y, 25, 3, Color(0.45f, 1, 0.55f));
            glyph(c, int(i), x, y, on ? White : fade(White, 0.75f));
        }
        if (row == -1) c.text(small, buttons[uint(button)], 640, 92, White, AlignCenter);
        // Status and the time, on the right.
        Color k = fade(White, 0.85f);
        string clock = System::clock(true);
        float right = 1216;
        if (clock != "")
        {
            c.text(font, clock, right, 42, White, AlignRight);
            right -= font.measure(clock).x + 22;
        }
        c.roundRect(right - 30, 48, 26, 14, 3, fade(White, 0.12f));
        c.rectLine(right - 30, 48, 26, 14, 2, k);
        c.rect(right - 4, 52, 3, 6, k);
        for (int i = 0; i < 3; i++)
            c.rect(right - 27 + float(i) * 7, 51, 5, 8, k);
    }

    void drawTile(Canvas@ c, Tile@ t, float x)
    {
        float size = Small + (Large - Small) * t.lift;
        float top = RowBottom - size;
        c.roundRect(x + 4, top + 8, size, size, 6, fade(Black, 0.35f));
        // A square from the middle of the picture.
        float sw = t.art.width > 0 ? t.art.height : 1;
        float sx = t.art.width > 0 ? (t.art.width - sw) / 2 : 0;
        c.imagePart(t.art, x, top, size, size, sx, 0, sw, sw, White);
        if (t.lift > 0.05f)
        {
            float band = 46 * t.lift;
            c.rect(x, top + size - band, size, band, fade(Color(0.06f, 0.07f, 0.08f), 0.9f * t.lift));
            c.text(small, t.title, x + 12, top + size - band + 12, fade(White, t.lift));
            c.rectLine(x - 3, top - 3, size + 6, size + 6, 3, fade(Color(0.45f, 1, 0.55f), t.lift));
        }
    }

    void drawCard(Canvas@ c, Card@ k, float x)
    {
        float grow = k.lift * 8;
        float left = x - grow, top = CardTop - grow, w = CardWide + grow * 2, h = CardHigh + grow * 2;
        c.roundRect(left + 4, top + 8, w, h, 6, fade(Black, 0.35f));
        if (k.art.length() == 1)
            c.image(k.art[0], left, top, w, h, White);
        else if (k.art.length() > 1)
        {
            float part = w / float(k.art.length());
            for (uint i = 0; i < k.art.length(); i++)
            {
                Texture@ a = k.art[i];
                if (a.width > 0) c.imagePart(a, left + part * float(i), top, part, h, a.width * 0.35f, 0, a.width * 0.3f, a.height, White);
            }
        }
        else
        {
            c.gradient(left, top, w, h, Color(0.08f, 0.14f, 0.2f), Color(0.04f, 0.06f, 0.1f));
            glyph(c, 3, left + w / 2, top + h / 2 - 14, White);
        }
        c.gradient(left, top + h * 0.45f, w, h * 0.55f, fade(Black, 0), fade(Black, 0.75f));
        c.text(font, k.title, left + 14, top + h - 58, White);
        c.text(tiny, k.about, left + 15, top + h - 28, fade(White, 0.75f));
        if (k.lift > 0.05f)
            c.rectLine(left - 3, top - 3, w + 6, h + 6, 3, fade(Color(0.45f, 1, 0.55f), k.lift));
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        ribbonsBehind(c);

        topBar(c);
        if (row == 0)
        {
            Tile@ t = tiles[uint(tile)];
            c.text(huge, t.title, 62, 168, White);
            c.text(small, t.about == "" ? t.kind : t.about + "  ·  " + t.kind, 65, 224, fade(White, 0.8f));
        }

        c.clip(0, 200, 1280, 290);
        for (uint i = 0; i < tiles.length(); i++)
        {
            float x = tileX(int(i));
            if (x > -Large && x < 1300) drawTile(c, tiles[i], x);
        }
        c.noClip();
        for (uint i = 0; i < cards.length(); i++)
            drawCard(c, cards[i], 64 + float(i) * (CardWide + Gap));

        // Opening one: it grows to fill the screen, or shrinks back on return.
        float grow = launching >= 0 ? smooth(min(launching, 1)) : coming > 0 ? smooth(coming) : 0;
        if (grow > 0)
        {
            Vec2 at = launchFrom + (Vec2(0, 0) - launchFrom) * grow;
            Vec2 size = launchSize + (Vec2(1280, 720) - launchSize) * grow;
            if (launchArt !is null) c.image(launchArt, at.x, at.y, size.x, size.y, White);
            else c.rect(at.x, at.y, size.x, size.y, Color(0.05f, 0.15f, 0.07f));
            c.rect(0, 0, 1280, 720, fade(Black, grow * 0.6f));
        }

        // The guide, over what is behind it, blurred.
        if (guide > 0.01f)
        {
            float w = 400;
            float x = -w + w * smooth(guide);
            c.rect(0, 0, 1280, 720, fade(Black, 0.35f * guide));
            c.clip(0, 0, x + w, 720);
            c.blur(14);
            c.noClip();
            c.rect(x, 0, w, 720, Color(0.06f, 0.08f, 0.07f, 0.9f));
            c.rect(x + w - 2, 0, 2, 720, Color(0.45f, 1, 0.55f, 0.6f));
            profile(c, x + 36, 36);
            for (uint i = 0; i < guideRows.length(); i++)
            {
                float y = 150 + float(i) * 64;
                bool on = int(i) == guideRow;
                if (on) c.roundRect(x + 24, y - 10, w - 48, 52, 6, Color(0.45f, 1, 0.55f, 0.95f));
                string words = guideRows[i] + (i == 1 ? "  (" + Screens::count + ")" : "");
                c.text(font, words, x + 48, y, on ? Black : White);
            }
            c.text(small, "Menu: close    Accept: choose", x + 48, 660, fade(White, 0.5f));
        }
        else
            c.text(tiny, "Accept: open    Menu: guide    Cancel: back", 1216, 690, fade(White, 0.55f), AlignRight);
    }
}
