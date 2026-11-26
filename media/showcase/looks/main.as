// Colour grading. The same island in ten looks, each a table of what every colour becomes, worked out once and
// looked up on the GPU in one pass. Left of the line is the picture as it was drawn; right of it, graded.

class LooksScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 54);
    array<string> presets = { "warm", "cold", "faded", "noir", "sepia", "dusk", "vivid", "bleach", "night" };
    array<string> names = { "Warm", "Cold", "Faded", "Noir", "Sepia", "Dusk", "Vivid", "Bleach bypass", "Night" };
    Look@ look = Look();
    uint chosen = 0;
    float shownFor = 0, turn = 0, strength = 1;
    // Until the player chooses, one look after another.
    bool chosenByHand = false;
    bool split = true;
    Vec3 middle;

    void onEnter()
    {
        Space::land(9, 128, 2, 22, 0.5f, true);
        Space::water(0, Color(0.12f, 0.36f, 0.5f, 0.8f));
        Space::waterStyle("sea");
        Space::farthest(220);
        Space::shadows(0.6f, 30);
        Space::sky(Color(0.25f, 0.5f, 0.85f), Color(0.75f, 0.86f, 0.94f));
        Space::fog(Color(0.75f, 0.86f, 0.94f), 90, 220);
        Space::sun(Vec3(0.5f, 0.6f, 0.3f), Color(1, 0.94f, 0.82f));
        if (App::platform != "Original Xbox")
            Space::grass(Assets::model("global:model/grass.glb"), 1.5f, 24);

        // Somewhere on the shore, a little above the sea.
        middle = Vec3(0, 3, 0);
        for (float r = 20; r < 128; r += 2)
        {
            float h = Space::height(r, 0);
            if (h > 1.5f && h < 5)
            {
                middle = Vec3(r, h, 0);
                break;
            }
        }
        // Colours to see the looks by: round the wheel, and from white to black.
        for (int i = 0; i < 8; i++)
        {
            float a = float(i) / 8.0f * 6.283f;
            Entity@ e = Space::spawn(Vec3(middle.x + sin(a) * 4, 0, middle.z + cos(a) * 4));
            Vec3 p = e.place;
            p.y = Space::height(p.x, p.z) + 0.8f;
            e.place = p;
            e.shape(i % 2 == 0 ? SolidSphere : SolidBox, hsv(float(i) / 8.0f, 0.75f, 0.95f));
            e.size = Vec3(1.2f, 1.2f, 1.2f);
            e.shine = 0.5f;
        }
        for (int i = 0; i < 5; i++)
        {
            Entity@ e = Space::spawn(Vec3(middle.x - 1.6f + float(i) * 0.8f, 0, middle.z));
            Vec3 p = e.place;
            p.y = Space::height(p.x, p.z) + 0.4f + float(i) * 0.25f;
            e.place = p;
            float v = 1 - float(i) / 4.0f;
            e.shape(SolidBox, Color(v, v, v));
            e.size = Vec3(0.6f, 0.8f + float(i) * 0.5f, 0.6f);
        }
        use(0);
    }

    void use(uint n)
    {
        chosen = n;
        shownFor = 0;
        look.preset(presets[n]);
    }

    void update(float dt)
    {
        shownFor += dt;
        if (Input::pressed("left") || Input::pressed("right") || Input::held("up") || Input::held("down") || Input::pressed("accept"))
            chosenByHand = true;
        if (Input::pressed("right") || (shownFor > 4.5f && !chosenByHand))
            use((chosen + 1) % presets.length());
        else if (Input::pressed("left"))
            use((chosen + presets.length() - 1) % presets.length());
        if (Input::pressed("accept"))
            split = !split;
        if (Input::held("up"))
            strength = min(strength + dt, 1);
        if (Input::held("down"))
            strength = max(strength - dt, 0);
        turn += dt * 0.12f;
        Vec3 at(middle.x + sin(turn) * 11, 0, middle.z + cos(turn) * 11);
        at.y = max(Space::height(at.x, at.z), 0) + 3.5f;
        Space::camera(at, middle + Vec3(0, 0.8f, 0), 60);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.2f, 0.85f);
        // Where the line is: swaying across the middle, so that both sides are seen.
        float w = c.width;
        float line = split ? w * (0.5f + sin(App::time * 0.6f) * 0.18f) : 0;
        c.push();
        c.clip(line, 0, w - line, 720);
        c.grade(look, strength);
        c.pop();
        if (split)
            c.rect(line - 1, 0, 2, 720, Color(1, 1, 1, 0.8f));

        float a = clamp(shownFor * 3, 0, 1) * clamp((4.3f - shownFor) * 2 + 1, 0.4f, 1);
        if (split)
        {
            c.text(font, "As drawn", line - 16, 150, Color(1, 1, 1, 0.85f), AlignRight);
            c.text(font, names[chosen], line + 16, 150, Color(1, 1, 1, 0.85f));
        }
        c.text(big, names[chosen], w - 40, 40, Color(1, 1, 1, a), AlignRight);
        c.text(font, "Strength " + formatInt(int(strength * 100 + 0.5f)) + "%", w - 40, 104, Color(0.9f, 0.93f, 1, 0.8f * a), AlignRight);
        c.text(font, "Left, right: look   Up, down: strength   Accept: " + (split ? "all of it" : "before and after"), 40, 40, Color(0.9f, 0.93f, 1, 0.7f * a));
    }
}
