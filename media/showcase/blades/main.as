// Curved blades, from images. One that crosses the screen is drawn in strips, so that it bends straight
// and then the other way.

class Page
{
    string title;
    Color light, deep;
    array<string> rows;
    array<string> about;
    int chosen = 0;

    Page(const string &in title_, float hue, float strong, const array<string> &in rows_, const array<string> &in about_)
    {
        title = title_;
        light = hsv(hue, strong * 0.6f, 0.98f);
        deep = hsv(hue, strong, 0.5f);
        rows = rows_;
        about = about_;
    }
}

const float Wide = 90;        // of a blade, on the screen
const float Step = 41;        // from one to the next
const float Bend = 26;        // of its middle, sideways

class BladesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ small = Assets::font("global:freesans.sfn", 20);
    Font@ tab = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Sound@ slide = Assets::sound("global:sound/whoosh.wav");
    Sound@ move = Assets::sound("global:sound/move.wav");
    Texture@ metal = Assets::texture("asset:metal.png");
    Texture@ runnerLeft = Assets::texture("asset:runner-left.png");
    Texture@ runnerRight = Assets::texture("asset:runner-right.png");
    Texture@ header = Assets::texture("asset:header.png");
    array<Texture@> lefts = { Assets::texture("asset:left1.png"), Assets::texture("asset:left2.png"), Assets::texture("asset:left3.png") };
    array<Texture@> rights = { Assets::texture("asset:right1.png"), Assets::texture("asset:right2.png"), Assets::texture("asset:right3.png") };

    array<Page@> pages = {
        Page("market", 0.09f, 0.85f, { "Game store", "New arrivals", "Themes", "Memberships" }, { "Everything there is to play.", "What came in this week.", "Change how all this looks.", "Yours lasts until spring." }),
        Page("live", 0.07f, 0.9f, { "Sign in", "Friends", "Messages", "Players met" }, { "Nobody is signed in.", "Three of them are playing.", "One is unread.", "The last fifty." }),
        Page("games", 0.27f, 0.85f, { "Play disc", "Collection", "Achievements", "Demos" }, { "There is a disc in the tray.", "Forty-four scenes.", "Twelve of thirty.", "Try them for nothing." }),
        Page("media", 0.56f, 0.8f, { "Music", "Pictures", "Videos", "Tray" }, { "From this console, or another.", "Six folders.", "None yet.", "Open it." }),
        Page("system", 0.62f, 0.35f, { "Console", "Family", "Memory", "Network", "Startup" }, { "Screen, sound and language.", "Who may play what.", "", "Not connected.", "Where it begins." })
    };
    int chosen = 2;
    float at = 2;
    float time = 0;
    float rowAt = 0;

    void update(float dt)
    {
        time += dt;
        int before = chosen;
        if (Input::repeated("right") && chosen + 1 < int(pages.length()))
            chosen++;
        if (Input::repeated("left") && chosen > 0)
            chosen--;
        if (chosen != before)
        {
            slide.play(0.5f, 0, 1.3f);
            rowAt = float(pages[uint(chosen)].chosen);
        }
        Page@ page = pages[uint(chosen)];
        int row = page.chosen;
        if (Input::repeated("down") && row + 1 < int(page.rows.length()))
            page.chosen++;
        if (Input::repeated("up") && row > 0)
            page.chosen--;
        if (page.chosen != row)
            move.play(0.5f);
        rowAt += (float(page.chosen) - rowAt) * clamp(dt * 14, 0, 1);
        at += (float(chosen) - at) * clamp(dt * 8, 0, 1);
        if (abs(at - float(chosen)) < 0.003f)
            at = float(chosen);
    }

    float leftOf(float index) { return 26 + index * Step; }
    float rightOf(float index, float width) { return width - 26 - Wide - (float(pages.length()) - 1 - index) * Step; }

    // How far out the middle of a blade is, at some height.
    float bulge(float y) { return (1 - (y * 2 - 1) * (y * 2 - 1)) * Bend; }

    // Crossed: 0 on the left, 1 on the right.
    void blade(Canvas@ c, int index, float crossed, float x)
    {
        Page@ p = pages[uint(index)];
        bool mirrored = crossed > 0.5f;
        bool first = !mirrored && abs(float(index) - at) < 0.5f;
        int size = int(abs(float(index) - at) + 0.5f) - 1;
        size = size < 0 ? 0 : size > 2 ? 2 : size;
        Texture@ image = first ? header : mirrored ? rights[uint(size)] : lefts[uint(size)];
        if (!image.ready)
            return;
        if (crossed <= 0.002f || crossed >= 0.998f)
            c.image(image, x, 0, Wide, 720);
        else
        {
            const int Strips = 36;
            float bent = mirrored ? 1 - crossed : crossed;      // how much of its bend it has lost, up to a half
            float way = mirrored ? 1.0f : -1.0f;
            float high = image.height / float(Strips);
            for (int i = 0; i < Strips; i++)
            {
                float y = (float(i) + 0.5f) / float(Strips);
                c.imagePart(image, x + bulge(y) * bent * 2 * way - Bend * bent * way, float(i) * 720 / float(Strips), Wide, 720 / float(Strips) + 0.6f, 0, float(i) * high, image.width, high);
            }
        }
        c.push();
        c.translate(x + (mirrored ? 27 : 56), 335);
        c.rotate(90);
        c.text(tab, p.title, 0, -tab.measure(p.title).y * 0.5f, first ? White : Color(0.28f, 0.3f, 0.32f), AlignCenter);
        c.pop();
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        float width = c.width;
        float count = float(pages.length());
        // Behind everything, the page's own colour.
        int a = int(floor(at)), b = a + 1 < int(pages.length()) ? a + 1 : a;
        float part = at - float(a);
        Color light = lerp(pages[uint(a)].light, pages[uint(b)].light, part), deep = lerp(pages[uint(a)].deep, pages[uint(b)].deep, part);
        c.gradient(0, 0, width, 720, light, deep);
        for (int i = 0; i < 5; i++)
            c.ring(width * 0.62f + sin(time * 0.17f + float(i) * 1.3f) * 50, 380 + cos(time * 0.13f + float(i)) * 30, 120 + float(i) * 95, 34, Color(1, 1, 1, 0.07f));
        c.glow(width * 0.6f, 120, 420, Color(1, 1, 1, 0.22f));

        // What is on it, sliding with its blade.
        for (int i = a; i <= b; i++)
        {
            float off = float(i) - at;
            float shown = clamp(1 - abs(off) * 1.7f, 0, 1);
            if (shown > 0)
                content(c, i, leftOf(float(i)) + Wide + 44 + off * 520, shown);
        }

        if (runnerLeft.ready && runnerRight.ready)
        {
            c.image(runnerRight, width - 80, 0, 180, 720);
            c.image(runnerLeft, -100, 0, 180, 720);
        }
        // Those still to come, from the outside in; then those that have been passed.
        for (int i = int(pages.length()) - 1; i >= 0; i--)
        {
            float off = clamp(float(i) - at, 0, 1);
            if (off > 0.5f)
                blade(c, i, smooth(off), lerp(leftOf(float(i)), rightOf(float(i), width), smooth(off)));
        }
        for (int i = 0; i < int(pages.length()); i++)
        {
            float off = clamp(float(i) - at, 0, 1);
            if (off <= 0.5f)
                blade(c, i, smooth(off), lerp(leftOf(float(i)), rightOf(float(i), width), smooth(off)));
        }
    }

    void content(Canvas@ c, int index, float x, float shown)
    {
        Page@ p = pages[uint(index)];
        float right = rightOf(float(index) + 1, c.width) - 10;
        c.alpha = shown;
        c.text(big, p.title, x + 22, 74, White);
        c.rect(x + 22, 132, 420, 2, Color(1, 1, 1, 0.5f));
        float mine = index == chosen ? rowAt : float(p.chosen);
        for (uint i = 0; i < p.rows.length(); i++)
        {
            float near = clamp(1 - abs(float(i) - mine), 0, 1);
            float y = 158 + float(i) * 62, w = 400 + near * 26;
            c.roundRect(x + 22, y + 3, w, 52, 10, Color(0, 0, 0, 0.25f));
            c.roundRect(x + 22, y, w, 52, 10, lerp(Color(1, 1, 1, 0.22f), Color(1, 1, 1, 0.95f), near));
            c.text(font, p.rows[i], x + 46, y + 26 - font.measure(p.rows[i]).y * 0.5f, lerp(White, p.deep, near));
        }
        // A panel of brushed metal, with something moving on it.
        float px = x + 490, pw = right - px - 10;
        if (pw > 120)
        {
            c.roundRect(px + 4, 162, pw, 330, 18, Color(0, 0, 0, 0.3f));
            c.roundRect(px, 158, pw, 330, 18, Color(0.93f, 0.95f, 0.96f));
            if (metal.ready)
                c.tile(metal, px + 10, 168, pw - 20, 310, 256, 256, 0, 0, Color(1, 1, 1, 0.55f));
            float mx = px + pw * 0.5f, my = 300;
            for (int i = 0; i < 6; i++)
            {
                float turn = time * 0.9f + float(i) * 1.047f;
                Color tone = fade(p.deep, 0.75f);
                if (index == 0)
                    c.roundRect(mx - 96 + float(i % 3) * 68, my - 70 + float(i / 3) * 70 + sin(turn) * 5, 56, 56, 8, tone);
                else if (index == 1)
                    c.circle(mx + sin(turn) * 70, my + cos(turn) * 70, 18 + sin(turn * 2) * 4, tone);
                else if (index == 2)
                    c.arc(mx, my, 28 + float(i) * 14, 8, turn * 57 * (i % 2 == 0 ? 1.0f : -1.0f), turn * 57 * (i % 2 == 0 ? 1.0f : -1.0f) + 210, tone);
                else if (index == 3)
                    c.roundRect(mx - 102 + float(i) * 36, my + 80 - 40 - (0.5f + 0.5f * sin(turn * 2.3f)) * 110, 26, 40 + (0.5f + 0.5f * sin(turn * 2.3f)) * 110, 6, tone);
                else
                    c.ring(mx, my, 90 - float(i) * 14, 5 + sin(turn * 2) * 3, tone);
            }
            string about = p.about[uint(p.chosen)];
            if (about == "")
                about = formatInt(int(App::freeKilobytes / 1024)) + " MB free.";
            c.text(small, about, mx, 432, p.deep, AlignCenter);
        }
        c.circle(x + 40, 594, 15, Color(0.25f, 0.7f, 0.2f));
        c.text(small, "A", x + 40, 594 - small.measure("A").y * 0.5f, White, AlignCenter);
        c.text(small, "Select", x + 64, 594 - small.measure("A").y * 0.5f, White);
        c.text(small, "Left, right: blades     Up, down: choose", right - 24, 594 - small.measure("A").y * 0.5f, Color(1, 1, 1, 0.8f), AlignRight);
        c.alpha = 1;
    }
}
