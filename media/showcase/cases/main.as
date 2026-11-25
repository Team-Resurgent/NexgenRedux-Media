// Records to flip through. Covers are asked for as they come near and let go of as they leave; each case
// is on a spring, and opens to show what is in it. Alternate gets the covers from the web instead.

class Case
{
    Entity@ root;        // turns
    Entity@ lid;         // opens
    Entity@ cover;
    Entity@ disc;
    Entity@ inside;      // the back of the booklet
    Entity@ shade;       // the reflection
    Texture@ art;
    string title, who;
    Vec3 at;
    float angle = 0, spin = 0;      // of the spring
    float wobble = 0, wobbling = 0;
    float shown = 0;                // as the cover arrives
}

class CasesScreen : Screen
{
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Sound@ flick = Assets::sound("global:sound/case.wav");
    Sound@ open = Assets::sound("global:sound/whoosh.wav");
    array<Case@> cases;
    Mesh@ face = Mesh();
    Mesh@ label = Mesh();
    Mesh@ below = Mesh();
    int chosen = 4;
    float at = 4;
    float lid = 0;
    bool opened = false;
    bool web = false;
    float time = 0;
    Vec2 mouseWas;
    array<string> titles = { "Slow Comet", "Paper Moons", "Glass Garden", "Night Ferry", "Copper Sky", "Small Hours", "Tidal", "Signal Fires", "Static Bloom", "Long Division", "Kite Weather", "Saltwater",
        "Half Light", "Mainframe", "Red Shift", "Soft Machines", "Northern Line", "Echo Park", "Feather", "Ironwood", "Lantern", "Overcast", "Prism", "Home Again" };
    array<string> makers = { "The Orbits", "Ada Verne", "Field Echo", "Harbour Light", "The Wiremen", "Nine to Noon", "Low Country", "Beacon Hill", "Violet Hum", "Primes", "Open Field", "Pier Nine",
        "Dusk Radio", "Punch Card", "Far Arms", "Clockwork Sea", "Last Stop", "The Returns", "Weightless", "Forest Press", "Moth Club", "Grey Area", "Split Beam", "The Orbits" };

    void onEnter()
    {
        // A square with a picture on it, and a disc.
        face.vertex(Vec3(-0.5f, -0.5f, 0), Vec3(0, 0, 1), White, 0, 1);
        face.vertex(Vec3(0.5f, -0.5f, 0), Vec3(0, 0, 1), White, 1, 1);
        face.vertex(Vec3(0.5f, 0.5f, 0), Vec3(0, 0, 1), White, 1, 0);
        face.vertex(Vec3(-0.5f, 0.5f, 0), Vec3(0, 0, 1), White, 0, 0);
        face.triangle(0, 1, 2);
        face.triangle(0, 2, 3);
        // Upside down, and fading as it goes.
        Color gone(1, 1, 1, 0), there(1, 1, 1, 0.34f);
        below.vertex(Vec3(-0.5f, -0.5f, 0), Vec3(0, 0, 1), gone, 0, 0.35f);
        below.vertex(Vec3(0.5f, -0.5f, 0), Vec3(0, 0, 1), gone, 1, 0.35f);
        below.vertex(Vec3(0.5f, 0.5f, 0), Vec3(0, 0, 1), there, 1, 1);
        below.vertex(Vec3(-0.5f, 0.5f, 0), Vec3(0, 0, 1), there, 0, 1);
        below.triangle(0, 1, 2);
        below.triangle(0, 2, 3);
        // The disc: a bright hub, the print, and the rim.
        array<float> rings = { 0.07f, 0.15f, 0.16f, 0.455f, 0.46f, 0.48f };
        for (int k = 0; k < 3; k++)
            for (int i = 0; i <= 40; i++)
            {
                float a = float(i) / 40 * 6.28319f;
                Color tint = k == 1 ? White : hsv(abs(float(i % 20) / 20.0f - 0.5f) + 0.45f, 0.3f, 0.75f);
                for (int e = 0; e < 2; e++)
                {
                    float r = rings[uint(k * 2 + e)];
                    float u = cos(a) * r, v = sin(a) * r;
                    label.vertex(Vec3(u, v, 0), Vec3(0, 0, 1), tint, k == 1 ? 0.5f + u : 0.02f, k == 1 ? 0.5f - v : 0.98f);
                }
                if (i > 0)
                {
                    uint n = uint(k * 82 + i * 2);
                    label.triangle(n - 2, n - 1, n + 1);
                    label.triangle(n - 2, n + 1, n);
                }
            }
        for (uint i = 0; i < titles.length(); i++)
        {
            Case@ c = Case();
            c.title = titles[i];
            c.who = makers[i];
            @c.root = Space::spawn(Vec3(float(i) * 2, 0, -2));
            c.at = c.root.place;
            Entity@ back = Space::spawn(Vec3(0, 0, -0.03f));
            back.attach(c.root);
            back.shape(SolidBox, Color(0.13f, 0.13f, 0.15f));
            back.size = Vec3(1.42f, 1.25f, 0.05f);
            back.shine = 0.7f;
            @c.disc = Space::spawn(Vec3(0.06f, 0, 0.005f));
            c.disc.attach(c.root);
            c.disc.mesh(label);
            c.disc.twoSided = true;
            c.disc.shine = 0.3f;
            c.disc.size = Vec3(1.2f, 1.2f, 1.2f);
            // The lid turns about its left edge.
            @c.lid = Space::spawn(Vec3(-0.71f, 0, 0.02f));
            c.lid.attach(c.root);
            Entity@ front = Space::spawn(Vec3(0.71f, 0, 0.012f));
            front.attach(c.lid);
            front.shape(SolidBox, Color(0.2f, 0.2f, 0.22f));
            front.size = Vec3(1.42f, 1.25f, 0.025f);
            front.shine = 0.9f;
            @c.cover = Space::spawn(Vec3(0.79f, 0, 0.028f));
            c.cover.attach(c.lid);
            c.cover.mesh(face, Color(0.16f, 0.16f, 0.19f));
            c.cover.size = Vec3(1.22f, 1.22f, 1);
            c.cover.shine = 0.8f;
            @c.inside = Space::spawn(Vec3(0.79f, 0, -0.003f));
            c.inside.attach(c.lid);
            c.inside.mesh(face, Color(0.3f, 0.3f, 0.33f));
            c.inside.angles = Vec3(0, 180, 0);
            c.inside.size = Vec3(1.2f, 1.2f, 1);
            Entity@ spine = Space::spawn(Vec3(0.085f, 0, 0.026f));
            spine.attach(c.lid);
            spine.shape(SolidBox, Color(0.07f, 0.07f, 0.08f));
            spine.size = Vec3(0.15f, 1.24f, 0.012f);
            // The shiny floor has it too.
            @c.shade = Space::spawn(c.at);
            c.shade.mesh(below, Color(0.1f, 0.1f, 0.12f));
            c.shade.size = Vec3(1.22f, 0.8f, 1);
            c.shade.blend = BlendAlpha;
            c.shade.shadow = false;
            c.shade.twoSided = true;
            cases.insertLast(c);
        }
        Space::sky(Color(0.03f, 0.03f, 0.05f), Color(0.1f, 0.1f, 0.14f));
        Space::fog(Color(0.06f, 0.06f, 0.09f), 7, 15);
        Space::sun(Vec3(0.2f, 0.6f, 1), Color(0.75f, 0.75f, 0.8f));
        Space::ambient(Color(0.72f, 0.72f, 0.78f), Color(0.6f, 0.6f, 0.62f));
        Space::shadows(0);
        Entity@ lamp = Space::spawn(Vec3(0, 2.4f, 2));
        lamp.light(Color(0.8f, 0.75f, 0.7f), 7);
    }

    string cover(int i)
    {
        string name = "cover" + (i < 10 ? "0" : "") + formatInt(i) + ".jpg";
        return web ? "https://raw.githubusercontent.com/Team-Resurgent/NexgenRedux-Media/main/media/showcase/cases/asset/" + name : "asset:" + name;
    }

    void update(float dt)
    {
        time += dt;
        int before = chosen;
        if (Input::repeated("right") && chosen + 1 < int(cases.length())) chosen++;
        if (Input::repeated("left") && chosen > 0) chosen--;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && Input::mouseDown(0) && mouse.x != mouseWas.x)
            at = clamp(at - (mouse.x - mouseWas.x) * 0.006f, 0, float(cases.length() - 1));
        if (Input::hasMouse && Input::mouseDown(0))
            chosen = int(at + 0.5f);
        mouseWas = mouse;
        if (chosen != before)
        {
            opened = false;
            flick.play(0.4f, 0, random(0.92f, 1.08f));
            // The one that lands wobbles, and those beside it are brushed.
            for (int i = -2; i <= 2; i++)
                if (chosen + i >= 0 && chosen + i < int(cases.length()))
                    cases[uint(chosen + i)].wobbling += (chosen > before ? 260 : -260) / (1 + abs(float(i)) * 1.6f);
        }
        if (Input::pressed("accept"))
        {
            opened = !opened;
            open.play(0.4f, 0, opened ? 1.3f : 1.0f);
            cases[uint(chosen)].wobbling += 140;
        }
        if (Input::pressed("alternate"))
        {
            web = !web;
            for (uint i = 0; i < cases.length(); i++)
                letGo(cases[i]);
        }
        at += (float(chosen) - at) * clamp(dt * 7, 0, 1);
        lid += ((opened ? 1.0f : 0.0f) - lid) * clamp(dt * 5, 0, 1);
        for (uint i = 0; i < cases.length(); i++)
            move(cases[i], int(i), dt);
        Space::camera(Vec3(sin(time * 0.25f) * 0.25f, 0.5f, 4.4f + lid * 1.1f), Vec3(0, -0.3f + lid * 0.05f, 0), 48);
    }

    void letGo(Case@ c)
    {
        @c.art = null;
        c.shown = 0;
        c.cover.skin(null);
        c.shade.skin(null);
        c.inside.skin(null);
        c.disc.skin(null);
    }

    void move(Case@ c, int index, float dt)
    {
        float off = float(index) - at;
        float near = clamp(1 - abs(off), 0, 1);
        bool here = abs(off) < 8;
        c.root.visible = here;
        c.shade.visible = here;
        // Asked for within six, and kept to nine, so that it isn't let go of and wanted again at once.
        if (abs(off) < 6 && c.art is null)
            @c.art = Assets::texture(cover(index));
        else if (abs(off) > 9 && c.art !is null)
            letGo(c);
        if (c.art !is null && c.art.ready && !c.art.failed)
        {
            if (c.shown == 0)
            {
                c.cover.skin(c.art);
                c.shade.skin(c.art);
                c.inside.skin(c.art);
                c.disc.skin(c.art);
            }
            c.shown = clamp(c.shown + dt * 2.5f, 0.01f, 1);
        }
        if (!here)
            return;
        float side = off < 0 ? -1.0f : 1.0f;
        float apart = clamp(abs(off), 0, 1);
        Vec3 wanted(side * (apart * 1.35f + clamp(abs(off) - 1, 0, 9) * 0.52f), near * 0.06f, near * 1.25f - abs(off) * 0.16f);
        c.at = lerp(c.at, wanted, clamp(dt * 14, 0, 1));
        // Springs: one for the way it faces, and one that wobbles.
        c.spin += ((-side * apart * 66) - c.angle) * 90 * dt;
        c.spin *= clamp(1 - dt * 11, 0, 1);
        c.angle += c.spin * dt;
        c.wobbling += (0 - c.wobble) * 170 * dt;
        c.wobbling *= clamp(1 - dt * 4.2f, 0, 1);
        c.wobble += c.wobbling * dt;
        float breathe = near * sin(time * 1.3f) * 2.5f;
        float turned = c.angle + c.wobble + breathe - near * lid * 14;
        c.root.place = c.at + Vec3(near * lid * 0.2f, near * (0.03f + sin(time * 1.6f) * 0.02f), near * lid * 0.5f);
        c.root.angles = Vec3(c.wobble * 0.25f, turned, c.wobble * 0.12f);
        c.lid.angles = Vec3(0, -near * lid * 132, 0);
        c.disc.place = Vec3(0.06f + near * lid * 0.42f, 0, 0.005f + near * lid * 0.2f);
        c.disc.angles = Vec3(0, 0, -time * 160 * near * lid);
        float bright = 0.68f + near * 0.32f;
        float lit = c.shown * bright + (1 - c.shown) * 0.14f;
        c.cover.color = Color(lit, lit, lit);
        c.inside.color = Color(lit * 0.5f, lit * 0.5f, lit * 0.5f);
        c.disc.color = Color(0.75f, 0.75f, 0.75f);
        c.disc.visible = near * lid > 0.02f;
        c.shade.place = Vec3(c.root.place.x + 0.06f, -1.06f - c.root.place.y, c.root.place.z);
        c.shade.angles = Vec3(0, turned, 0);
        float dim = lit * (1 - near * lid);
        c.shade.color = Color(dim, dim, dim);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.45f, 0.8f);
        // The floor fades into the dark.
        c.gradient(0, 520, c.width, 200, Color(0.03f, 0.03f, 0.05f, 0), Color(0.03f, 0.03f, 0.05f, 0.9f));
        Case@ now = cases[uint(chosen)];
        c.text(big, now.title, c.width * 0.5f, 548, White, AlignCenter);
        c.text(font, now.who, c.width * 0.5f, 604, Color(0.65f, 0.7f, 0.8f), AlignCenter);
        int held = 0, waiting = 0;
        for (uint i = 0; i < cases.length(); i++)
        {
            held += cases[i].art !is null ? 1 : 0;
            waiting += cases[i].art !is null && !cases[i].art.ready ? 1 : 0;
        }
        c.text(font, formatInt(held) + " covers held" + (waiting > 0 ? ", " + formatInt(waiting) + " on their way" : "") + (web ? ", from the web" : ""), 40, 28, Color(0.6f, 0.65f, 0.75f));
        float w = c.width * 0.4f, x = c.width * 0.3f;
        c.roundRect(x, 648, w, 6, 3, Color(1, 1, 1, 0.14f));
        c.roundRect(x + at / float(cases.length() - 1) * (w - 40), 646, 40, 10, 5, Color(1, 1, 1, 0.7f));
        c.text(font, "Left, right: flip     Accept: open     Alternate: " + (web ? "from the disc" : "from the web"), c.width * 0.5f, 672, Color(0.6f, 0.65f, 0.75f), AlignCenter);
    }
}
