// Water in five styles round an island: waves that lean and sharpen as they grow, clear in the shallows and dark
// where it is deep, the sky in it at a low angle, and foam on the shore and on crests.

class WaterScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 54);
    array<string> styles = { "calm", "sea", "choppy", "storm", "cartoon" };
    array<string> names = { "Calm", "Sea", "Choppy", "Storm", "Cartoon" };
    uint style = 1;
    float t = 0, shownFor = 0, turn = 0.6f;

    void onEnter()
    {
        Space::land(9, 128, 2, 22, 0.5f, true);
        Space::water(0, Color(0.12f, 0.36f, 0.5f, 0.8f));
        Space::farthest(260);
        Space::shadows(0.6f, 40);
        Space::grass(Assets::model("global:model/grass.glb"), App::platform == "Original Xbox" ? 0.5f : 2, 30);
        use(1);
    }

    void use(uint n)
    {
        style = n;
        shownFor = 0;
        Space::waterStyle(styles[n]);
        bool stormy = n == 3;
        // A sky to suit.
        Space::sky(stormy ? Color(0.22f, 0.25f, 0.3f) : Color(0.25f, 0.5f, 0.85f), stormy ? Color(0.5f, 0.53f, 0.56f) : Color(0.75f, 0.86f, 0.94f));
        Space::fog(stormy ? Color(0.5f, 0.53f, 0.56f) : Color(0.75f, 0.86f, 0.94f), stormy ? 40 : 90, stormy ? 160 : 250);
        Space::sun(Vec3(0.5f, stormy ? 0.4f : 0.7f, 0.3f), stormy ? Color(0.45f, 0.47f, 0.5f) : Color(1, 0.94f, 0.82f));
        Space::wind = stormy ? Vec3(3, 0, 1.2f) : Vec3(0.94f, 0, 0.34f);
    }

    void update(float dt)
    {
        t += dt;
        shownFor += dt;
        if (Input::pressed("right") || (shownFor > 4.8f && !Input::usingPad && !Input::hasMouse))
            use((style + 1) % styles.length());
        else if (Input::pressed("left"))
            use((style + styles.length() - 1) % styles.length());
        // Round the island, low over the shore.
        turn += dt * 0.08f;
        // Out at sea, looking back at the beach, and down a little at the waves.
        float r = 128;
        Vec3 at(sin(turn) * r, 0, cos(turn) * r);
        at.y = max(Space::height(at.x, at.z), 0) + (style == 3 ? 7 : 5);
        Vec3 look(sin(turn + 0.5f) * 82, 0, cos(turn + 0.5f) * 82);
        Space::camera(at, look, 60);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.25f, 0.85f);
        float a = clamp(shownFor * 3, 0, 1) * clamp((4.6f - shownFor) * 2 + 1, 0.35f, 1);
        c.text(big, names[style], 60, 40, Color(1, 1, 1, a));
        c.text(font, Input::usingPad ? "Left and right: another" : "Left and right: another style", 62, 104, Color(0.85f, 0.9f, 1, 0.8f * a));
    }
}
