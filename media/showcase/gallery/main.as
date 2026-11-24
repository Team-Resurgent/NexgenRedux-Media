// Models from glTF files, turning on a stand.

class GalleryScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 40);
    Sound@ click = Assets::sound("global:sound/move.wav");
    array<string> names = { "robot", "house", "well", "lantern", "pine", "oak", "bush", "rock", "crystal", "mushroom" };
    array<Model@> models;
    uint chosen = 0;
    uint animation = 0;
    Entity@ shown;
    float away = 1;
    float arrive = 0;

    GalleryScreen()
    {
        for (uint i = 0; i < names.length(); i++)
            models.insertLast(Assets::model("global:model/" + names[i] + ".glb"));
    }

    void onEnter()
    {
        Entity@ stand = Space::spawn(Vec3(0, -0.26f, 0));
        stand.shape(SolidCylinder, Color(0.32f, 0.34f, 0.42f));
        stand.size = Vec3(5, 0.5f, 5);
        stand.shine = 0.6f;
        stand.shadow = false;
        Entity@ rim = Space::spawn(Vec3(0, -0.1f, 0));
        rim.shape(SolidCylinder, Color(0.35f, 0.75f, 1));
        rim.size = Vec3(5.12f, 0.06f, 5.12f);
        rim.glowing = 1;
        Space::ground(0);
        Space::sky(Color(0.06f, 0.07f, 0.13f), Color(0.2f, 0.23f, 0.34f));
        Space::sun(Vec3(0.5f, 0.8f, 0.7f), Color(0.95f, 0.92f, 0.86f));
        Space::ambient(Color(0.36f, 0.4f, 0.5f), Color(0.22f, 0.2f, 0.2f));
        Space::shadows(0.6f, 8);
        show();
    }

    void show()
    {
        if (shown !is null)
            shown.destroy();
        @shown = Space::spawn(Vec3(0, 0, 0));
        shown.model(models[chosen]);
        shown.shine = 0.3f;
        animation = 0;
        arrive = 0;
    }

    void update(float dt)
    {
        uint before = chosen;
        if (Input::repeated("right"))
            chosen = (chosen + 1) % names.length();
        if (Input::repeated("left"))
            chosen = (chosen + names.length() - 1) % names.length();
        if (chosen != before)
        {
            click.play(0.6f);
            show();
        }
        uint count = models[chosen].animations;
        if (count > 0)
        {
            if (Input::repeated("up"))
                animation = (animation + 1) % count;
            if (Input::repeated("down"))
                animation = (animation + count - 1) % count;
            shown.animate(models[chosen].animation(animation));
        }
        // Held, it goes away, and simpler versions are drawn.
        float wanted = Input::held("fire") || Input::held("accept") ? 14 : 1;
        away += (wanted - away) * clamp(dt * 2, 0, 1);
        arrive = clamp(arrive + dt * 2.5f, 0, 1);
        float radius = models[chosen].radius;
        float size = radius > 0 ? 1.45f / radius * smooth(arrive) : 0.01f;
        shown.size = Vec3(size, size, size);
        shown.turn(Vec3(0, 1, 0), dt * 30);
        Space::camera(Vec3(0, 1.9f, 5) * away, Vec3(0, 1.2f, 0), 45);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.text(big, names[chosen], 48, 40);
        c.text(font, formatInt(int(models[chosen].triangles)) + " triangles, shown at level " + formatInt(int(shown.detail)), 50, 96, Color(0.7f, 0.8f, 0.95f));
        for (uint i = 0; i < models[chosen].animations; i++)
            c.text(font, models[chosen].animation(i), 50, 140 + float(i) * 30, i == animation ? Yellow : Color(0.6f, 0.65f, 0.75f));
        for (uint i = 0; i < names.length(); i++)
            c.circle(c.width * 0.5f + (float(i) - float(names.length() - 1) * 0.5f) * 26, 640, i == chosen ? 8 : 5, i == chosen ? White : Color(1, 1, 1, 0.35f));
        c.text(font, "Left, right: another model     Up, down: animation     Hold accept: farther away", c.width * 0.5f, 668, Color(0.75f, 0.8f, 0.9f), AlignCenter);
    }
}
