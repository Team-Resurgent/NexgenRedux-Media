// Particles in space. How each kind looks is in scene.json; a burst throws some, and an emitter keeps on.

class EmbersScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 40);
    Sound@ fire = Assets::sound("global:sound/fire.wav");
    Sound@ boom = Assets::sound("global:sound/boom.wav");
    Sound@ water = Assets::sound("global:sound/waves.wav");
    Model@ campfire = Assets::model("global:model/campfire.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    array<string> names = { "Campfire", "Explosions", "Fountain", "Snow", "Fireworks" };
    array<Entity@> things;
    int kind = 0;
    float at = 0, around = 0, next = 0;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        Mesh@ floor = Mesh();
        floor.plane(60, 60, 40, Color(0.42f, 0.44f, 0.48f));
        Space::spawn(Vec3(0, 0, 0)).mesh(floor);
        Space::ground(0);
        Space::shadows(0.6f, 14);
        build();
    }

    Entity@ add(Entity@ e)
    {
        things.insertLast(e);
        return e;
    }

    void build()
    {
        for (uint i = 0; i < things.length(); i++)
            things[i].destroy();
        things.resize(0);
        next = 0;
        bool dark = kind != 3;
        Space::sky(dark ? Color(0.02f, 0.025f, 0.06f) : Color(0.3f, 0.36f, 0.46f), dark ? Color(0.07f, 0.07f, 0.13f) : Color(0.5f, 0.56f, 0.64f));
        Space::fog(dark ? Color(0.06f, 0.06f, 0.12f) : Color(0.5f, 0.56f, 0.64f), 14, 34);
        Space::sun(Vec3(0.4f, 0.8f, 0.5f), dark ? Color(0.3f, 0.34f, 0.5f) : Color(0.6f, 0.62f, 0.68f));
        Space::ambient(dark ? Color(0.17f, 0.18f, 0.28f) : Color(0.5f, 0.53f, 0.6f), dark ? Color(0.05f, 0.05f, 0.07f) : Color(0.35f, 0.35f, 0.38f));
        if (kind == 0)
        {
            add(Space::spawn(Vec3(0, 0, 0))).model(campfire);
            Entity@ flame = add(Space::spawn(Vec3(0, 0.25f, 0)));
            flame.emit("flame", 60);
            flame.sound(fire, 0.9f, 16);
            add(Space::spawn(Vec3(0, 0.6f, 0))).emit("spark", 14);
            add(Space::spawn(Vec3(0, 1.4f, 0))).emit("smoke", 9);
        }
        else if (kind == 2)
        {
            Entity@ bowl = add(Space::spawn(Vec3(0, 0.25f, 0)));
            bowl.shape(SolidCylinder, Color(0.5f, 0.5f, 0.55f));
            bowl.size = Vec3(3, 0.5f, 3);
            Entity@ jet = add(Space::spawn(Vec3(0, 0.6f, 0)));
            jet.emit("drop", 160);
            jet.sound(water, 0.6f, 18);
            for (int i = 0; i < 6; i++)
            {
                Entity@ side = add(Space::spawn(Vec3(sin(float(i) * 1.047f) * 1.2f, 0.5f, cos(float(i) * 1.047f) * 1.2f)));
                side.angles = Vec3(cos(float(i) * 1.047f) * -24, 0, sin(float(i) * 1.047f) * 24);
                side.emit("jet", 36);
            }
            Entity@ lamp = add(Space::spawn(Vec3(0, 1.4f, 0)));
            lamp.light(Color(0.3f, 0.8f, 1.2f), 9);
        }
        else if (kind == 3)
        {
            for (int x = -2; x <= 2; x++)
                for (int z = -2; z <= 2; z++)
                {
                    Vec3 p(float(x) * 4, 7, float(z) * 4);
                    add(Space::spawn(p)).emit("snow", 14);
                    // It has been falling for some time already.
                    for (int down = 0; down < 6; down++)
                        Space::burst("snow", p - Vec3(0, float(down) * 1.2f, 0), 7);
                }
            for (int i = 0; i < 9; i++)
            {
                Entity@ e = add(Space::spawn(Vec3(sin(float(i) * 2.4f) * (2 + float(i) * 0.6f), 0, cos(float(i) * 2.4f) * (2 + float(i) * 0.6f))));
                e.model(rock);
                e.size = Vec3(1, 1, 1) * (0.5f + float(i % 3) * 0.3f);
                e.color = Color(0.95f, 1, 1.1f);
            }
        }
    }

    void blast()
    {
        Vec3 p(random(-3, 3), random(0.5f, 2.5f), random(-3, 3));
        Space::burst("fireball", p, 34);
        Space::burst("ash", p, 16);
        Space::burst("shrapnel", p, 40);
        boom.playAt(p, 0.7f, 30, random(0.8f, 1.2f));
        Entity@ flash = Space::spawn(p);
        flash.light(Color(2.5f, 1.4f, 0.5f), 12);
        flash.lifetime = 0.12f;
    }

    void rocket()
    {
        Vec3 p(random(-4, 4), random(5, 7.5f), random(-4, 4));
        string colour = "star" + formatInt(randomInt(1, 4));
        Space::burst(colour, p, 130);
        boom.playAt(p, 0.35f, 40, random(1.2f, 1.7f));
    }

    void update(float dt)
    {
        at += dt;
        around += (Input::move.x * 1.4f + 0.12f) * dt;
        int way = (Input::pressed("right") ? 1 : 0) - (Input::pressed("left") ? 1 : 0);
        if (way != 0)
        {
            kind = (kind + way + int(names.length())) % int(names.length());
            build();
        }
        next -= dt;
        if (kind == 1 && (next < 0 || Input::pressed("accept")))
        {
            blast();
            next = random(0.5f, 1.1f);
        }
        if (kind == 4 && (next < 0 || Input::pressed("accept")))
        {
            rocket();
            next = random(0.35f, 0.9f);
        }
        if (kind == 0 && things.length() > 1)
            things[1].light(Color(2.4f, 1.2f, 0.45f), 10 + sin(at * 11) * 0.7f + sin(at * 17.3f) * 0.5f);
        Space::camera(Vec3(sin(around) * 7, 2.6f + (kind == 4 ? 0.5f : 0.0f), cos(around) * 7), Vec3(0, kind == 4 ? 4.0f : 1.4f, 0), 58);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        if (kind != 3)
            c.bloom(0.75f, 0.6f);
        c.text(big, names[uint(kind)], 44, 36);
        c.text(font, formatInt(int(Scene::particles)) + " particles", 46, 90, Color(0.75f, 0.8f, 0.9f));
        c.text(font, "Left, right: another" + (kind == 1 || kind == 4 ? "     Accept: again" : ""), c.width * 0.5f, 668, Color(0.75f, 0.8f, 0.9f), AlignCenter);
    }
}
