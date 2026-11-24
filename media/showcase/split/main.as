// Two of them in the same world, each with a view of its own. The second is played by a second gamepad,
// or plays itself.

Sound@ chime = Assets::sound("global:sound/coin.wav");
array<int> scores = { 0, 0 };

class Gem : Behaviour
{
    void update(float dt) { entity.turn(Vec3(0, 1, 0), 90 * dt); }

    void onHit(Entity@ other)
    {
        scores[other.name == "second" ? 1 : 0]++;
        chime.play(0.6f, other.name == "second" ? 0.5f : -0.5f);
        // Somewhere else.
        float x = random(-32, 32), z = random(-32, 32);
        entity.place = Vec3(x, Space::height(x, z) + 0.3f, z);
    }
}

class SplitScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 52);
    Model@ robot = Assets::model("global:model/robot.glb");
    Model@ crystal = Assets::model("global:model/crystal.glb");
    Model@ tree = Assets::model("global:model/oak.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    array<Entity@> robots;
    array<Entity@> gems;
    array<float> yaws = { 0.6f, 3.4f };
    array<Vec3> looks(2);
    float left = 60;

    void onEnter()
    {
        scores = { 0, 0 };
        Space::land(3, 64, 1.5f, 10, 0.3f);
        Space::landColors(Color(0.4f, 0.5f, 0.26f), Color(0.36f, 0.5f, 0.24f), Color(0.5f, 0.52f, 0.4f), Color(0.45f, 0.4f, 0.33f), -10, 12);
        Space::sky(Color(0.3f, 0.5f, 0.85f), Color(0.8f, 0.87f, 0.95f));
        Space::fog(Color(0.8f, 0.87f, 0.95f), 35, 90);
        Space::sun(Vec3(0.5f, 0.8f, 0.3f), Color(0.95f, 0.9f, 0.8f));
        Space::shadows(0.6f, 18);
        for (int i = 0; i < 46; i++)
        {
            float x = random(-42, 42), z = random(-42, 42);
            if (x * x + z * z < 60)
                continue;
            Entity@ e = Space::spawn(Vec3(x, Space::height(x, z), z));
            e.model(i % 3 == 0 ? rock : tree);
            float size = random(0.6f, 1.2f);
            e.size = Vec3(size, size, size);
            e.angles = Vec3(0, random(0, 360), 0);
            if (i % 3 == 0)
                e.sphere(0.85f, 2);
            else
                e.capsule(0.3f, 4, 2);
            e.colliderAt = Vec3(0, i % 3 == 0 ? 0.2f : 2.0f, 0);
            e.wall = true;
        }
        for (int i = 0; i < 14; i++)
        {
            float x = random(-30, 30), z = random(-30, 30);
            Entity@ e = Space::spawn(Vec3(x, Space::height(x, z) + 0.3f, z));
            e.model(crystal);
            e.size = Vec3(0.8f, 0.8f, 0.8f);
            e.sphere(0.9f, 3, 1 << 1);
            e.colliderAt = Vec3(0, 0.6f, 0);
            e.add(Gem());
            gems.insertLast(e);
        }
        for (int i = 0; i < 2; i++)
        {
            float x = i == 0 ? -2 : 2;
            Entity@ e = Space::spawn(Vec3(x, Space::height(x, 0), 0));
            e.model(robot);
            e.name = i == 0 ? "first" : "second";
            if (i == 1)
                e.color = Color(0.55f, 0.75f, 1);
            e.capsule(0.35f, 1.6f, 1);
            e.colliderAt = Vec3(0, 0.8f, 0);
            e.walker = true;
            e.shine = 0.4f;
            robots.insertLast(e);
            looks[uint(i)] = e.place;
        }
    }

    void update(float dt)
    {
        left -= dt;
        if (left < 0)
        {
            if (left < -5)
            {
                left = 60;
                scores = { 0, 0 };
            }
        }
        for (uint i = 0; i < 2; i++)
        {
            Vec2 stick = Input::move;
            bool jump = Input::pressed("accept");
            Vec3 side(cos(yaws[i]), 0, -sin(yaws[i]));
            Vec3 ahead(-sin(yaws[i]), 0, -cos(yaws[i]));
            Vec3 way = side * stick.x - ahead * stick.y;
            if (i == 1)
            {
                jump = false;
                way = Vec3(0, 0, 0);
                if (Input::padConnected(1))
                {
                    Vec2 pad = Input::padLeft(1);
                    way = side * pad.x + ahead * pad.y;
                    jump = Input::padButton(1, 8);
                }
                else
                {
                    // To the nearest, round what is in the way.
                    float nearest = 1000;
                    for (uint n = 0; n < gems.length(); n++)
                    {
                        Vec3 d = gems[n].place - robots[1].place;
                        d.y = 0;
                        if (d.length() < nearest)
                        {
                            nearest = d.length();
                            way = d.normalized();
                        }
                    }
                    Vec3 hit;
                    Vec3 normal;
                    Vec3 chest = robots[1].place + Vec3(0, 0.8f, 0);
                    if (Space::raycast(chest, chest + way * 2.5f, hit, normal, 1 << 2))
                        way = (way + Vec3(-way.z, 0, way.x) * 1.4f).normalized();
                    way = way * 0.72f;
                }
            }
            if (left < 0)
                way = Vec3(0, 0, 0);
            Vec3 motion = robots[i].motion;
            motion.x += (way.x * 7 - motion.x) * clamp(10 * dt, 0, 1);
            motion.z += (way.z * 7 - motion.z) * clamp(10 * dt, 0, 1);
            if (jump && robots[i].onGround)
                motion.y = 6;
            robots[i].motion = motion;
            float going = Vec3(motion.x, 0, motion.z).length();
            if (way.length() > 0.1f)
                robots[i].face(way, clamp(10 * dt, 0, 1));
            bool won = left < 0 && scores[i] >= scores[1 - i];
            robots[i].animate(won ? "dance" : !robots[i].onGround && abs(motion.y) > 2 ? "jump" : going > 4 ? "run" : going > 0.5f ? "walk" : "idle");
            yaws[i] -= clamp(motion.dot(side) * 0.16f, -1.4f, 1.4f) * dt;
            looks[i] = lerp(looks[i], robots[i].place + Vec3(0, 1.4f, 0), clamp(9 * dt, 0, 1));
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        for (uint i = 0; i < 2; i++)
        {
            Vec3 from = looks[i] + Vec3(sin(yaws[i]) * 6, 2.2f, cos(yaws[i]) * 6);
            float least = Space::height(from.x, from.z) + 0.5f;
            from.y = from.y < least ? least : from.y;
            Space::camera(from, looks[i], 62);
            Space::draw(c, float(i) * 642, 0, 638, 720);
            c.roundRect(float(i) * 642 + 20, 20, 170, 84, 16, Color(0, 0, 0, 0.45f));
            c.text(big, formatInt(scores[i]), float(i) * 642 + 105, 30, i == 0 ? Color(1, 0.8f, 0.5f) : Color(0.6f, 0.8f, 1), AlignCenter);
        }
        c.rect(638, 0, 4, 720, Black);
        c.circle(640, 60, 40, Color(0, 0, 0, 0.8f));
        c.text(font, formatInt(left > 0 ? int(left) + 1 : 0), 640, 44, left < 10 ? Red : White, AlignCenter);
        if (left < 0)
            c.text(big, scores[0] > scores[1] ? "Orange wins!" : scores[0] < scores[1] ? "Blue wins!" : "A draw!", 640, 300, Yellow, AlignCenter);
    }
}
