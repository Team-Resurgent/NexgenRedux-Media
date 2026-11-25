// Shaders, written once and compiled for whichever GPU there is. Left and right change the picture's;
// up and down the robot's. Where there are none, everything is drawn as it is.

class ShadersScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 36);
    Model@ robot = Assets::model("global:model/robot.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    array<string> pictureNames = { "nothing", "grade", "ink", "tube", "pixels", "ripple", "glitch" };
    array<string> surfaceNames = { "nothing", "hologram", "dissolve", "lava" };
    array<Effect@> pictures;
    array<Effect@> surfaces;
    Effect@ flag = Assets::effect("global:effect/flag.fx");
    Effect@ lava = Assets::effect("global:effect/lava.fx");
    uint picture = 0, surface = 0;
    bool spill = true;
    Entity@ hero;
    float at = 0, since = 0;

    ShadersScreen()
    {
        for (uint i = 1; i < pictureNames.length(); i++)
            pictures.insertLast(Assets::effect("global:effect/" + pictureNames[i] + ".fx"));
        for (uint i = 1; i < surfaceNames.length(); i++)
            surfaces.insertLast(Assets::effect("global:effect/" + surfaceNames[i] + ".fx"));
    }

    void onEnter()
    {
        Mesh@ floor = Mesh();
        floor.plane(40, 40, 30, Color(0.4f, 0.42f, 0.48f));
        Space::spawn(Vec3(0, 0, 0)).mesh(floor);
        Entity@ stand = Space::spawn(Vec3(0, 0.1f, 0));
        stand.shape(SolidCylinder, Color(0.25f, 0.27f, 0.34f));
        stand.size = Vec3(3, 0.2f, 3);
        @hero = Space::spawn(Vec3(0, 0.2f, 0));
        hero.model(robot);
        hero.size = Vec3(1.4f, 1.4f, 1.4f);
        hero.shine = 0.5f;
        // A flag: a sheet of squares for the shader to move.
        Mesh@ cloth = Mesh();
        for (int y = 0; y <= 8; y++)
            for (int x = 0; x <= 14; x++)
                cloth.vertex(Vec3(float(x) * 0.14f, float(y) * 0.14f, 0), Vec3(0, 0, 1), White, float(x) / 14, float(y) / 8);
        for (int y = 0; y < 8; y++)
            for (int x = 0; x < 14; x++)
            {
                uint a = uint(y * 15 + x);
                cloth.triangle(a, a + 1, a + 16);
                cloth.triangle(a, a + 16, a + 15);
            }
        for (int i = 0; i < 2; i++)
        {
            float x = i == 0 ? -3.4f : 2.2f;
            Entity@ pole = Space::spawn(Vec3(x, 1.7f, -1));
            pole.shape(SolidCylinder, Color(0.75f, 0.75f, 0.8f));
            pole.size = Vec3(0.08f, 3.4f, 0.08f);
            Entity@ e = Space::spawn(Vec3(x + 0.04f, 2.25f, -1));
            e.mesh(cloth, i == 0 ? Color(0.9f, 0.25f, 0.2f) : Color(0.2f, 0.45f, 0.9f));
            e.twoSided = true;
            e.effect(flag);
        }
        flag.set(0, 1);
        flag.set(4, 0.95f); flag.set(5, 0.93f); flag.set(6, 0.88f);
        lava.set(0, 1);
        for (int i = 0; i < 5; i++)
        {
            Entity@ e = Space::spawn(Vec3(-4.5f + float(i) * 2.25f, 0, -3.4f - float(i % 2)));
            e.model(rock);
            e.size = Vec3(1.2f, 1.6f, 1.2f);
            if (i % 2 == 0)
                e.effect(lava);
        }
        Space::sky(Color(0.12f, 0.16f, 0.3f), Color(0.5f, 0.42f, 0.45f));
        Space::sun(Vec3(0.5f, 0.6f, 0.6f), Color(0.6f, 0.53f, 0.47f));
        Space::ambient(Color(0.26f, 0.28f, 0.36f), Color(0.2f, 0.18f, 0.2f));
        Space::fog(Color(0.5f, 0.42f, 0.45f), 14, 30);
        Space::shadows(0.6f, 12);
        for (int i = 0; i < 2; i++)
        {
            Entity@ lamp = Space::spawn(Vec3(i == 0 ? -2.4f : 2.4f, 1.2f, 1.4f));
            lamp.glow(0.6f, i == 0 ? Color(1, 0.6f, 0.3f) : Color(0.4f, 0.7f, 1));
            lamp.light(i == 0 ? Color(1.1f, 0.6f, 0.3f) : Color(0.4f, 0.7f, 1.2f), 5);
        }
    }

    void update(float dt)
    {
        at += dt;
        uint count = pictureNames.length();
        if (Input::repeated("right")) picture = (picture + 1) % count;
        if (Input::repeated("left")) picture = (picture + count - 1) % count;
        uint before = surface;
        count = surfaceNames.length();
        if (Input::repeated("down")) surface = (surface + 1) % count;
        if (Input::repeated("up")) surface = (surface + count - 1) % count;
        if (Input::pressed("accept")) spill = !spill;
        since += dt;
        if (surface != before)
        {
            since = 0;
            hero.effect(surface == 0 ? null : surfaces[surface - 1]);
            hero.blend = surface == 1 ? BlendAdd : BlendNone;
            if (surface == 3)
                surfaces[2].set(0, 1);
        }
        hero.animate(surface == 0 ? "wave" : surface == 1 ? "idle" : "dance");
        hero.turn(Vec3(0, 1, 0), dt * 24);
        // Values are told to a shader as they change.
        surfaces[0].set(0, 0.12f); surfaces[0].set(1, 0.42f); surfaces[0].set(2, 0.55f);
        surfaces[1].set(0, clamp(0.5f - cos(since * 1.6f) * 0.55f, 0, 1));
        surfaces[1].set(4, 1); surfaces[1].set(5, 0.5f); surfaces[1].set(6, 0.15f);
        pictures[0].set(0, 1); pictures[0].set(1, 0.6f);
        pictures[2].set(0, 1);
        pictures[3].set(0, 220); pictures[3].set(1, 6);
        pictures[4].set(0, 1.4f);
        pictures[5].set(0, 1);
        Space::camera(Vec3(sin(at * 0.2f) * 2, 2.4f, 7.4f), Vec3(0, 1.4f, 0), 52);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        bool blooms = !spill || c.bloom(0.7f, 0.72f);
        bool shows = picture == 0 || c.effect(pictures[picture - 1]);
        bool worn = surface == 0 || surfaces[surface - 1].works;
        string no = "   (not on this GPU)";
        c.roundRect(24, 22, 400, 108, 16, Color(0, 0, 0, 0.45f));
        c.text(font, "Over the picture: " + pictureNames[picture] + (shows ? "" : no), 44, 34);
        c.text(font, "On the robot: " + surfaceNames[surface] + (worn ? "" : no), 44, 62);
        c.text(font, "Bloom: " + (spill ? "on" : "off") + (blooms ? "" : no), 44, 90);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Left, right: the picture's     Up, down: the robot's     Accept: bloom", 40, 668);
    }
}
