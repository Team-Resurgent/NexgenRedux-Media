// Ragdolls: robots knocked over go limp, a body for each limb pinned where they meet, and fall off what they stand
// on; a few seconds later they get up again from wherever they lie.

class ToppleScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Model@ robot = Assets::model("global:model/robot.glb");
    array<Entity@> robots;
    array<float> down;
    array<string> doing = { "idle", "wave", "dance", "idle", "run" };
    uint next = 0;
    Vec3 eye(0, 7, 11);

    void onEnter()
    {
        Mesh@ floor = Mesh();
        for (int z = -8; z < 8; z++)
            for (int x = -10; x < 10; x++)
            {
                float a = float(x) * 2, b = float(z) * 2;
                floor.quad(Vec3(a, 0, b + 2), Vec3(a + 2, 0, b + 2), Vec3(a + 2, 0, b), Vec3(a, 0, b), (x + z) % 2 == 0 ? Color(0.36f, 0.42f, 0.4f) : Color(0.3f, 0.36f, 0.34f));
            }
        Space::spawn(Vec3(0, 0, 0)).mesh(floor);
        Space::ground(0);
        Space::sky(Color(0.25f, 0.4f, 0.65f), Color(0.8f, 0.84f, 0.85f));
        Space::fog(Color(0.8f, 0.84f, 0.85f), 25, 60);
        Space::sun(Vec3(0.5f, 0.9f, 0.5f), Color(0.95f, 0.9f, 0.8f));
        Space::shadows(0.65f, 18);

        // A ledge to fall from, and crates to fall over.
        block(Vec3(0, 0.6f, -2.5f), Vec3(9, 1.2f, 3), Color(0.55f, 0.5f, 0.45f), 0);
        for (int i = 0; i < 4; i++)
            block(Vec3(-4.5f + float(i) * 3, 0.35f, 1.6f), Vec3(0.7f, 0.7f, 0.7f), Color(0.75f, 0.55f, 0.3f), 8);

        for (uint i = 0; i < 5; i++)
        {
            Vec3 at = i < 3 ? Vec3(-3 + float(i) * 3, 1.2f, -2.2f) : Vec3(i == 3 ? -6.5f : 6.5f, 0, 0.5f);
            Entity@ e = Space::spawn(at);
            e.model(robot);
            e.capsule(0.35f, 1.6f, 1);
            e.colliderAt = Vec3(0, 0.8f, 0);
            e.walker = true;
            e.mass = 60;
            robots.insertLast(e);
            down.insertLast(0);
        }
    }

    Entity@ block(const Vec3 &in at, const Vec3 &in size, const Color &in color, float mass)
    {
        Entity@ e = Space::spawn(at);
        e.shape(SolidBox, color);
        e.size = size;
        e.cube(Vec3(1, 1, 1));
        e.mass = mass;
        e.gravity = mass > 0 ? 1 : 0;
        e.wall = mass <= 0;   // what walkers stand on
        e.friction = 0.6f;
        e.shine = 0.15f;
        return e;
    }

    // Toward where we look from, off the ledge, and up a little.
    void knock(uint i)
    {
        Entity@ e = robots[i];
        if (e.ragdolled)
            return;
        Vec3 toward = eye - e.place;
        toward.y = 0;
        e.ragdoll(true, toward.normalized() * 3.5f + Vec3(0, 1.5f, 0));
        down[i] = 3.5f;
    }

    void update(float dt)
    {
        if (Input::pressed("accept"))
        {
            knock(next);
            next = (next + 1) % robots.length();
        }
        if (Input::pressed("alternate"))
            for (uint i = 0; i < robots.length(); i++)
                knock(i);
        for (uint i = 0; i < robots.length(); i++)
        {
            Entity@ e = robots[i];
            if (e.ragdolled)
            {
                down[i] -= dt;
                // Up again where it lies, facing the way we look.
                if (down[i] <= 0)
                {
                    e.ragdoll(false);
                    e.face(eye - e.place);
                }
                continue;
            }
            e.animate(doing[i]);
            e.motion = Vec3();
        }
        Space::camera(eye, Vec3(0, 0.8f, -1), 55);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        float narrower = max(0.0f, 16.0f / 9 - c.width / c.height);
        eye = Vec3(0, 7 + narrower * 4, 11 + narrower * 10);
        Space::draw(c);
        uint lying = 0;
        for (uint i = 0; i < robots.length(); i++)
            lying += robots[i].ragdolled ? 1 : 0;
        c.roundRect(24, 22, 300, 44, 14, Color(0, 0, 0, 0.45f));
        c.text(font, formatInt(int(lying)) + " of " + formatInt(int(robots.length())) + " lying down", 44, 31);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Accept: knock one over     Alternate: knock them all over", 40, 668);
    }
}
