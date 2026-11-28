// A console's home of a later generation: deep blue, with smoke that drifts and curls behind everything, slow waves of
// light and sparks that rise. A row of square tiles, the one in focus grown large with its name beside it; small icons
// above; and below, what the one in focus is, and a button to start it. The tiles are this showcase's own demos.

class Tile
{
    string id, title, about, kind;
    Texture@ art;
    float lift = 0;     // 0 to 1, as it takes the focus
}

class Puff
{
    Vec2 at;
    float radius, seed, speed;
    Color color;
}

class Spark
{
    Vec2 at;
    float speed, seed, size;
}

const float Small = 146;
const float Large = 236;      // and its strip below that
const float Strip = 48;
const float Gap = 4;
const float RowTop = 124;

// A wave of fine strands, as silk or smoke drawn out: where it runs, how wide, and the dust along it.
class Strands
{
    array<Vec2> through;
    float width, speed, phase, strength;
    int count;
}

class Dust
{
    float along, across, speed, seed, size;
}

class Wave
{
    array<Vec2> through;
    float width, speed, phase;
}

class HubScreen : Screen
{
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ small = Assets::font("global:freesans.sfn", 19);
    Font@ tiny = Assets::font("global:freesans.sfn", 16);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ yes = Assets::sound("global:sound/accept.wav");
    Sound@ back = Assets::sound("global:sound/back.wav");
    Texture@ avatar = Assets::texture("global:picture/avatar.png");
    array<string> ids = { "explore", "lens", "moves", "blocks", "forest", "water", "skim", "topple", "quest", "guards", "machines", "curves", "shooter", "mist", "lights", "solids", "platformer", "cracktro" };
    array<string> icons = { "Store", "News", "Friends", "Trophies", "Settings", "Power" };
    array<string> actions = { "Start", "Every demo", "Settings" };
    array<Tile@> tiles;
    array<Puff@> puffs;
    array<Spark@> sparks;
    array<Wave@> waves;
    array<Strands@> bundles;
    array<Dust@> dust;
    array<Vec2> middle, sideways, strand;
    // A strand drawn as a thin band, so that it can fade towards its ends; and the soft body under a wave of them.
    array<Vec2> fibre, fibreUvs, body;
    array<Color> fibreColors, bodyColors;
    array<uint> fibreTriangles;
    // Kept from frame to frame: a wave's sheet, three points across at each step, and its highlight.
    array<Vec2> sheet, sheetUvs, highlight;
    array<Color> sheetColors;
    array<uint> sheetTriangles;
    uint WaveSteps = 28;
    int row = 0;          // -1 the icons, 0 the tiles, 1 what is below
    int tile = 0, icon = 0, action = 0;
    float scroll = 0;
    float iconsShown = 0; // the icons are dim until the focus goes up to them
    float below = 0;
    float belowShown = 0; // 1 while the focus is down there      // how far what is below has come up, for the one in focus
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
            t.title = ids[i];
            if (t.title[0] >= 97 && t.title[0] <= 122) t.title[0] = t.title[0] - 32;
            t.kind = "Demo";
            @t.art = Assets::texture("global:picture/demos/" + ids[i] + ".jpg");
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
        Random r(7);
        // The smoke: soft puffs of light, large and faint, each drifting on its own way.
        for (int i = 0; i < 14; i++)
        {
            Puff p;
            p.at = Vec2(r.random(-100, 1380), r.random(-60, 780));
            p.radius = r.random(140, 340);
            p.seed = r.random(0, 100);
            p.speed = r.random(0.04f, 0.1f);
            p.color = hsv(r.random(0.58f, 0.64f), r.random(0.3f, 0.6f), 1);
            puffs.insertLast(p);
        }
        // The waves: broad sheets of light, crisp along one edge and soft along the other. One falls from the top right and
        // curls away below; one comes in from the left; two lie long and low.
        addWave({ Vec2(1500, -160), Vec2(900, 260), Vec2(1150, 560), Vec2(700, 900) }, 230, 0.21f, 0);
        addWave({ Vec2(-300, 640), Vec2(400, 520), Vec2(800, 760), Vec2(1500, 560) }, 260, 0.14f, 4);
        addStrands({ Vec2(-260, 600), Vec2(350, 400), Vec2(950, 460), Vec2(1560, 540) }, 130, 0.22f, 1, 9, 1);
        addWave({ Vec2(-260, 600), Vec2(350, 400), Vec2(950, 460), Vec2(1560, 540) }, 170, 0.22f, 1);
        for (int i = 0; i < 70; i++)
        {
            Dust d;
            d.along = r.random(0, 1) * r.random(0, 1) * 0.45f;   // most of it towards the left end
            d.across = r.random(-1, 1);
            d.speed = r.random(0.01f, 0.04f);
            d.seed = r.random(0, 100);
            d.size = r.random(1, 3.5f);
            dust.insertLast(d);
        }
        fibre.resize(WaveSteps * 2);
        fibreUvs.resize(WaveSteps * 2);
        fibreColors.resize(WaveSteps * 2);
        body.resize(WaveSteps * 3);
        for (uint k = 0; k < WaveSteps; k++)
        {
            float u = float(k) / float(WaveSteps - 1);
            float soft = sin(u * 3.14159f);
            bodyColors.insertLast(Color(0.5f, 0.7f, 1, 0));
            bodyColors.insertLast(Color(0.55f, 0.75f, 1, 0.13f * soft));
            bodyColors.insertLast(Color(0.5f, 0.7f, 1, 0));
            if (k > 0)
            {
                uint q = k * 2;
                fibreTriangles.insertLast(q - 2); fibreTriangles.insertLast(q - 1); fibreTriangles.insertLast(q + 1);
                fibreTriangles.insertLast(q - 2); fibreTriangles.insertLast(q + 1); fibreTriangles.insertLast(q);
            }
        }
        middle.resize(WaveSteps);
        sideways.resize(WaveSteps);
        strand.resize(WaveSteps);
        sheet.resize(WaveSteps * 3);
        sheetUvs.resize(WaveSteps * 3);
        highlight.resize(WaveSteps);
        for (uint k = 0; k < WaveSteps; k++)
        {
            sheetColors.insertLast(Color(0.55f, 0.75f, 1, 0));
            sheetColors.insertLast(Color(0.62f, 0.82f, 1, 0.16f));
            sheetColors.insertLast(Color(0.7f, 0.88f, 1, 0.3f));
            if (k > 0)
            {
                uint q = k * 3;
                for (uint e = 0; e < 2; e++)
                {
                    sheetTriangles.insertLast(q - 3 + e); sheetTriangles.insertLast(q - 2 + e); sheetTriangles.insertLast(q + 1 + e);
                    sheetTriangles.insertLast(q - 3 + e); sheetTriangles.insertLast(q + 1 + e); sheetTriangles.insertLast(q + e);
                }
            }
        }
        for (int i = 0; i < 24; i++)
        {
            Spark s;
            s.at = Vec2(r.random(0, 1280), r.random(0, 720));
            s.speed = r.random(6, 22);
            s.seed = r.random(0, 100);
            s.size = r.random(1, 2.6f);
            sparks.insertLast(s);
        }
    }

    void addStrands(const array<Vec2> &in through, float width, float speed, float phase, int count, float strength)
    {
        Strands b;
        b.through = through;
        b.width = width;
        b.speed = speed;
        b.phase = phase;
        b.count = count;
        b.strength = strength;
        bundles.insertLast(b);
    }

    void addWave(const array<Vec2> &in through, float width, float speed, float phase)
    {
        Wave w;
        w.through = through;
        w.width = width;
        w.speed = speed;
        w.phase = phase;
        waves.insertLast(w);
    }

    void onResume()
    {
        launching = -1;
        coming = 1;
    }

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
        coming = max(coming - dt * 3, 0);
        iconsShown += ((row == -1 ? 1.0f : 0.0f) - iconsShown) * clamp(dt * 10, 0, 1);
        below = min(below + dt * 4, 1);
        for (uint i = 0; i < tiles.length(); i++)
            tiles[i].lift += ((row >= 0 && int(i) == tile ? 1.0f : 0.0f) - tiles[i].lift) * clamp(dt * 12, 0, 1);
        // The one in focus stays second from the left, once there are tiles before it to slide away.
        float want = max(0.0f, float(tile - 1) * (Small + Gap));
        scroll += (want - scroll) * clamp(dt * 9, 0, 1);
        for (uint i = 0; i < sparks.length(); i++)
        {
            Spark@ s = sparks[i];
            s.at.y -= s.speed * dt;
            s.at.x += sin(time * 0.5f + s.seed) * 6 * dt;
            if (s.at.y < -10) s.at = Vec2(random(0, 1280), 730);
        }

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

        int beforeRow = row, beforeTile = tile, beforeIcon = icon, beforeAction = action;
        if (Input::repeated("down") && row < 1) row++;
        if (Input::repeated("up") && row > -1) row--;
        int dx = (Input::repeated("right") ? 1 : 0) - (Input::repeated("left") ? 1 : 0);
        if (row == 0) tile = int(clamp(float(tile + dx), 0, float(tiles.length() - 1)));
        else if (row == 1) action = int(clamp(float(action + dx), 0, float(actions.length() - 1)));
        else icon = int(clamp(float(icon + dx), 0, float(icons.length() - 1)));
        if (tile != beforeTile) below = 0;
        if (row != beforeRow || tile != beforeTile || icon != beforeIcon || action != beforeAction) move.play(0.4f);
        if (Input::pressed("cancel")) { back.play(0.4f); Screens::pop(); }

        if (Input::pressed("accept"))
        {
            Tile@ t = tiles[uint(tile)];
            if (row == 0 || (row == 1 && action == 0))
                launch(t.id, t.art, Vec2(tileX(tile), RowTop), Vec2(Large, Large));
            else if (row == 1 && action == 1)
                launch("main", null, Vec2(640, 520), Vec2(10, 10));
            else if (row == 1 || icon == 4)
                launch("settings", null, Vec2(640, 520), Vec2(10, 10));
            else if (icon == 5)
                Screens::home();
        }
    }

    // --- Drawing ---

    // Royal blue, lighter towards the top left; sheets of light that sweep across in slow waves, soft at their edges
    // as smoke is, each with a fine highlight; a little smoke and a few sparks over them.
    void smoke(Canvas@ c)
    {
        c.gradient(0, 0, 1280, 720, Color(0.11f, 0.2f, 0.62f), Color(0.15f, 0.3f, 0.82f));
        c.blend = BlendAdd;
        c.glow(200, 60, 900, fade(Color(0.35f, 0.55f, 1), 0.22f));
        Curve path;
        for (uint i = 0; i < waves.length(); i++)
        {
            Wave@ w = waves[i];
            float t = time * w.speed + w.phase;
            path.clear();
            for (uint j = 0; j < w.through.length(); j++)
                path.add(w.through[j] + Vec2(sin(t * (0.8f + float(j) * 0.3f) + float(j)) * 70, cos(t * (0.7f + float(j) * 0.25f) + float(j) * 2) * 60));
            for (uint k = 0; k < WaveSteps; k++)
            {
                float u = float(k) / float(WaveSteps - 1);
                Vec2 at = path.at(u);
                Vec2 across = path.slope(u).normalized().perpendicular();
                float half = w.width * (0.55f + 0.45f * sin(u * 3.14159f + t * 0.6f));
                sheet[k * 3] = at - across * half;
                sheet[k * 3 + 1] = at;
                sheet[k * 3 + 2] = at + across * half;
                highlight[k] = at + across * half;
            }
            c.mesh(null, sheet, sheetUvs, White, sheetTriangles, sheetColors);
            c.polyline(highlight, 10, fade(Color(0.6f, 0.8f, 1), 0.07f));
            c.polyline(highlight, 2, fade(Color(0.88f, 0.95f, 1), 0.55f));
        }
        for (uint i = 0; i < bundles.length(); i++)
            drawStrands(c, bundles[i], i == 0);
        for (uint i = 0; i < puffs.length(); i++)
        {
            Puff@ p = puffs[i];
            float t = time * p.speed + p.seed;
            Vec2 at = p.at + Vec2(noise(t, 0.5f) * 260 + time * 9, noise(t, 7.5f) * 160);
            at.x = (at.x + 400) % 2080 - 400;
            float swell = 0.75f + 0.35f * noise(t * 1.7f, 3.3f);
            c.glow(at.x, at.y, p.radius * swell, fade(p.color, 0.03f + 0.02f * noise(t * 2, 9.1f)));
        }
        for (uint i = 0; i < sparks.length(); i++)
        {
            Spark@ s = sparks[i];
            float twinkle = 0.5f + 0.5f * sin(time * 2 + s.seed * 3);
            c.glow(s.at.x, s.at.y, s.size * 4, fade(Color(0.8f, 0.9f, 1), 0.4f * twinkle));
        }
        c.blend = BlendAlpha;
    }

    // Dust that glitters along the left end of a wave, drifting along it.
    void drawStrands(Canvas@ c, Strands@ b, bool dusty)
    {
        float t = time * b.speed + b.phase;
        Curve path;
        for (uint j = 0; j < b.through.length(); j++)
            path.add(b.through[j] + Vec2(sin(t * (0.9f + float(j) * 0.3f) + float(j)) * 60, cos(t * (0.8f + float(j) * 0.2f) + float(j) * 2) * 70));
        for (uint k = 0; k < WaveSteps; k++)
        {
            float u = float(k) / float(WaveSteps - 1);
            middle[k] = path.at(u);
            sideways[k] = path.slope(u).normalized().perpendicular();
        }
        if (!dusty) return;
        for (uint i = 0; i < dust.length(); i++)
        {
            Dust@ d = dust[i];
            float u = (d.along + time * d.speed) % 0.5f;
            float spot = u * float(WaveSteps - 1);
            uint k = uint(spot);
            if (k + 1 >= WaveSteps) continue;
            Vec2 at = middle[k] + (middle[k + 1] - middle[k]) * (spot - float(k));
            at += sideways[k] * (d.across * b.width * 0.5f + sin(time + d.seed) * 6);
            float twinkle = 0.5f + 0.5f * sin(time * 3 + d.seed * 5);
            c.glow(at.x, at.y, d.size * 4, fade(Color(0.85f, 0.93f, 1), (0.25f + 0.45f * twinkle) * (1 - u * 2)));
        }
    }

    void topBar(Canvas@ c)
    {
        for (uint i = 0; i < icons.length(); i++)
        {
            float x = 84 + float(i) * 58, y = 48;
            bool on = row == -1 && int(i) == icon;
            float a = 0.55f + 0.3f * iconsShown + (on ? 0.15f : 0);
            if (on) c.roundRect(x - 22, y - 22, 44, 44, 6, fade(White, 0.2f));
            iconGlyph(c, int(i), x, y, fade(White, a));
            if (on) c.text(tiny, icons[i], x, 92, White, AlignCenter);   // below the line, clear of it
        }
        string clock = System::clock(true);
        float right = 1216;
        if (clock != "")
        {
            c.text(small, clock, right, 38, White, AlignRight);
            right -= small.measure(clock).x + 28;
        }
        c.image(avatar, right - 190, 30, 34, 34);
        c.text(small, "Player One", right - 148, 38, White);
        c.rect(64, 82, 1152, 1, fade(White, 0.35f));
    }

    void iconGlyph(Canvas@ c, int which, float x, float y, const Color &in k)
    {
        if (which == 0)   // store: a bag
        {
            c.rectLine(x - 10, y - 4, 20, 16, 2, k);
            c.arc(x, y - 4, 6, 2, 180, 360, k);
        }
        else if (which == 1)   // news: lines
        {
            for (int i = 0; i < 3; i++) c.rect(x - 11, y - 8 + float(i) * 7, 22 - float(i) * 6, 3, k);
        }
        else if (which == 2)   // friends: two heads
        {
            c.circle(x - 5, y - 5, 5, k);
            c.circle(x + 7, y - 3, 4, k);
            c.ellipse(x - 5, y + 9, 9, 5, k);
            c.ellipse(x + 8, y + 9, 6, 4, k);
        }
        else if (which == 3)   // trophies: a cup with handles, on a stem and a foot
        {
            array<Vec2> cup = { Vec2(x - 9, y - 11), Vec2(x + 9, y - 11), Vec2(x + 6, y - 1), Vec2(x + 2, y + 2), Vec2(x - 2, y + 2), Vec2(x - 6, y - 1) };
            c.polygon(cup, k);
            c.arc(x - 9, y - 6, 4, 2, 90, 270, k);
            c.arc(x + 9, y - 6, 4, 2, -90, 90, k);
            c.rect(x - 1.5f, y + 2, 3, 5, k);
            c.rect(x - 7, y + 7, 14, 3, k);
        }
        else if (which == 4)   // settings: a toolbox
        {
            c.rectLine(x - 11, y - 6, 22, 15, 2, k);
            c.rect(x - 5, y - 10, 10, 3, k);
            c.rect(x - 11, y, 22, 2, k);
        }
        else   // power: a ring with a gap and a line
        {
            c.arc(x, y + 1, 10, 2.5f, -60, 240, k);
            c.rect(x - 1.5f, y - 12, 3, 12, k);
        }
    }

    void drawTile(Canvas@ c, Tile@ t, float x)
    {
        float size = Small + (Large - Small) * t.lift;
        float top = RowTop + (1 - t.lift) * 32;
        float strip = Strip * t.lift;
        c.rect(x + 3, top + 6, size, size + strip, fade(Black, 0.22f));
        float sw = t.art.width > 0 ? t.art.height : 1;
        float sx = t.art.width > 0 ? (t.art.width - sw) / 2 : 0;
        c.imagePart(t.art, x, top, size, size, sx, 0, sw, sw, White);
        if (t.lift > 0.05f)
        {
            c.rect(x, top + size, size, strip, fade(Color(0.02f, 0.04f, 0.1f), 0.92f * t.lift));
            array<Vec2> arrow = { Vec2(x + size / 2 - 7, top + size + strip * 0.4f), Vec2(x + size / 2 + 7, top + size + strip * 0.4f), Vec2(x + size / 2, top + size + strip * 0.68f) };
            c.polygon(arrow, fade(White, t.lift));
            c.rect(x + size / 2 - 2, top + size + strip * 0.22f, 4, strip * 0.2f, fade(White, t.lift));
            c.blend = BlendAdd;
            c.glow(x + size / 2, top + (size + strip) / 2, size * 0.85f, fade(Color(0.3f, 0.7f, 1), 0.3f * t.lift));
            c.blend = BlendAlpha;
            c.rectLine(x - 3, top - 3, size + 6, size + strip + 6, 3, fade(Color(0.5f, 0.9f, 1), t.lift));
            c.text(big, t.title, x + size + 24, RowTop + Small + 64, fade(White, t.lift));
        }
    }

    void drawBelow(Canvas@ c)
    {
        Tile@ t = tiles[uint(tile)];
        float shown = row == 1 ? 1.0f : 0.0f;
        belowShown += (shown - belowShown) * 0.15f;
        if (belowShown < 0.01f) return;
        float rise = (1 - smooth(below)) * 24 + (1 - belowShown) * 40;
        float a = smooth(below) * belowShown;
        float y = 420 + rise;
        // What to do: start it, see every demo, or the settings.
        for (uint i = 0; i < actions.length(); i++)
        {
            float x = 64 + float(i) * 196, w = 180;
            bool on = row == 1 && int(i) == action;
            c.roundRect(x, y, w, 46, 23, on ? fade(White, 0.95f * a) : fade(White, 0.12f * a));
            c.text(small, actions[i], x + w / 2, y + 12, on ? fade(Color(0.05f, 0.1f, 0.25f), a) : fade(White, 0.9f * a), AlignCenter);
        }
        // What it is.
        c.roundRect(64, y + 70, 560, 150, 6, fade(Black, 0.3f * a));
        c.text(tiny, "About", 84, y + 84, fade(White, 0.6f * a));
        c.paragraph(font, t.about == "" ? "One of this showcase's demos." : t.about, 84, y + 110, 520, fade(White, a));
        c.roundRect(644, y + 70, 572, 150, 6, fade(Black, 0.3f * a));
        c.imagePart(t.art, 644, y + 70, 220, 150, t.art.width * 0.2f, t.art.height * 0.1f, t.art.width * 0.6f, t.art.height * 0.8f, fade(White, a));
        c.text(tiny, "Kind", 884, y + 84, fade(White, 0.6f * a));
        c.text(font, t.kind, 884, y + 110, fade(White, a));
        c.text(tiny, "On every platform, 60 frames a second", 884, y + 150, fade(White, 0.7f * a));
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        smoke(c);
        topBar(c);
        for (uint i = 0; i < tiles.length(); i++)
        {
            float x = tileX(int(i));
            if (x > -Large && x < 1300) drawTile(c, tiles[i], x);
        }
        drawBelow(c);

        float grow = launching >= 0 ? smooth(min(launching, 1)) : coming > 0 ? smooth(coming) : 0;
        if (grow > 0)
        {
            Vec2 at = launchFrom + (Vec2(0, 0) - launchFrom) * grow;
            Vec2 size = launchSize + (Vec2(1280, 720) - launchSize) * grow;
            if (launchArt !is null) c.image(launchArt, at.x, at.y, size.x, size.y, White);
            else c.rect(at.x, at.y, size.x, size.y, Color(0.03f, 0.08f, 0.22f));
            c.rect(0, 0, 1280, 720, fade(Black, grow * 0.6f));
        }
        c.text(tiny, "Accept: open    Cancel: back", 1216, 690, fade(White, 0.5f), AlignRight);
    }
}
