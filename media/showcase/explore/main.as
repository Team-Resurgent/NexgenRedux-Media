// A world to walk about in: land, water, trees, houses, a day that passes, and someone to be.

Sound@ chime = Assets::sound("global:sound/coin.wav");
int found = 0;
float darkness = 0;

// Turns, bobs, and is picked up by whoever touches it.
class Crystal : Behaviour
{
    Vec3 home;
    float at = 0;

    void start()
    {
        home = entity.place;
        at = random(0, 6);
    }

    void update(float dt)
    {
        at += dt;
        entity.place = home + Vec3(0, 0.25f + sin(at * 2) * 0.15f, 0);
        entity.turn(Vec3(0, 1, 0), 70 * dt);
    }

    void onHit(Entity@ other)
    {
        found++;
        chime.play(0.7f);
        for (int i = 0; i < 10; i++)
        {
            Entity@ spark = Space::spawn(entity.place + Vec3(0, 0.7f, 0));
            spark.glow(random(0.2f, 0.5f), Color(0.4f, 0.9f, 1));
            spark.motion = Vec3(random(-3, 3), random(1, 5), random(-3, 3));
            spark.gravity = 0.8f;
            spark.lifetime = random(0.4f, 0.9f);
        }
        entity.destroy();
    }
}

// Wanders about in the dark.
class Firefly : Behaviour
{
    Vec3 home;
    float at = 0;

    void start()
    {
        home = entity.place;
        at = random(0, 100);
    }

    void update(float dt)
    {
        at += dt;
        entity.place = home + Vec3(sin(at * 0.7f) * 2.5f, 1.2f + sin(at * 1.3f) * 0.7f, cos(at * 0.9f) * 2.5f);
        entity.visible = darkness > 0.3f && sin(at * 3) > -0.5f;
    }
}

class ExploreScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Sound@ jump = Assets::sound("global:sound/whoosh.wav");
    Model@ robot = Assets::model("global:model/robot.glb");
    array<Model@> trees = { Assets::model("global:model/pine.glb"), Assets::model("global:model/oak.glb") };
    Model@ bush = Assets::model("global:model/bush.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    Model@ house = Assets::model("global:model/house.glb");
    Model@ lantern = Assets::model("global:model/lantern.glb");
    Model@ well = Assets::model("global:model/well.glb");
    Model@ crystal = Assets::model("global:model/crystal.glb");
    Model@ mushroom = Assets::model("global:model/mushroom.glb");

    Entity@ hero;
    array<Entity@> lamps;
    float yaw = 0.5f;           // of the camera, round the robot
    float lean = 0.28f;
    float away = 7;
    Vec3 look;
    float hour = 8.5f;          // of the day
    float waving = 2;
    float shown = 0;
    bool wasDown = false;
    Vec2 mouseWas;
    Vec3 safe;
    int total = 0;

    // Groups: 1 is the robot, 2 what can be walked into, 3 crystals.

    void onEnter()
    {
        found = 0;
        Space::land(21, 192, 1.5f, 34, 0.45f, true);
        Space::landColors(Color(0.8f, 0.73f, 0.52f), Color(0.36f, 0.53f, 0.24f), Color(0.55f, 0.53f, 0.48f), Color(0.45f, 0.4f, 0.35f), 0.6f, 17);
        Space::water(0, Color(0.16f, 0.42f, 0.55f, 0.78f));
        Space::flatten(0, 0, 44, 3);
        Space::farthest(320);
        Space::shadows(0.65f, 32);

        // A village, round a well.
        float y = Space::height(0, 0);
        place(well, Vec3(0, y, 0), 0, 1);
        wall(Vec3(0, y, 0), Vec3(2, 1.6f, 2), 0);
        for (int i = 0; i < 5; i++)
        {
            float a = float(i) * 1.2566f + 0.3f;
            Vec3 p(sin(a) * 15, 0, cos(a) * 15);
            p.y = Space::height(p.x, p.z);
            float turn = a * 57.3f + 180;
            place(house, p, turn, 1);
            wall(p, Vec3(6.3f, 8, 5.3f), turn);
        }
        for (int i = 0; i < 5; i++)
        {
            float a = float(i) * 1.2566f + 0.93f;
            Vec3 p(sin(a) * 8, 0, cos(a) * 8);
            p.y = Space::height(p.x, p.z);
            Entity@ post = place(lantern, p, 0, 1);
            post.capsule(0.2f, 3, 2);
            post.colliderAt = Vec3(0, 1.5f, 0);
            post.wall = true;
            Entity@ lamp = Space::spawn(p + Vec3(0, 2.9f, 0));
            lamp.glow(2.2f, Color(1, 0.75f, 0.35f, 0.6f));
            lamps.insertLast(lamp);
        }
        // Crates to push over.
        for (int i = 0; i < 10; i++)
        {
            int row = i < 4 ? 0 : i < 7 ? 1 : i < 9 ? 2 : 3;
            int along = i - (row == 0 ? 0 : row == 1 ? 4 : row == 2 ? 7 : 9);
            Entity@ crate = Space::spawn(Vec3(5, y + 0.45f + float(row) * 0.91f, -3.4f + float(along) * 0.95f + float(row) * 0.47f));
            crate.shape(SolidBox, Color(0.72f, 0.5f, 0.28f));
            crate.size = Vec3(0.9f, 0.9f, 0.9f);
            crate.cube(Vec3(1, 1, 1), 2);
            crate.mass = 6;
            crate.gravity = 1;
            crate.friction = 0.5f;
        }

        // What grows. Fewer where there is less memory.
        int many = App::platform() == "Original Xbox" ? 1 : 3;
        for (int i = 0; i < 130 * many; i++)
        {
            Vec3 p;
            if (spot(p, 1.2f, 14, 0.8f, 26))
            {
                bool high = p.y > 7 + random(-2, 2);
                Entity@ tree = place(trees[high ? 0 : 1], p, random(0, 360), random(0.8f, 1.5f));
                tree.capsule(0.3f, 4, 2);
                tree.colliderAt = Vec3(0, 2, 0);
                tree.wall = true;
            }
            if (i % 2 == 0 && spot(p, 0.8f, 16, 0.75f, 20))
                place(bush, p, random(0, 360), random(0.6f, 1.2f));
            if (i % 4 == 0 && spot(p, -1, 25, 0.5f, 20))
            {
                Entity@ stone = place(rock, p, random(0, 360), random(0.4f, 1.6f));
                stone.sphere(0.85f, 2);
                stone.colliderAt = Vec3(0, 0.2f, 0);
                stone.wall = true;
            }
            if (i % 5 == 0 && spot(p, 1, 12, 0.85f, 18))
                place(mushroom, p, random(0, 360), random(0.5f, 1.1f));
            if (i % 12 == 0 && spot(p, 1, 12, 0.8f, 10))
            {
                Entity@ fly = Space::spawn(p);
                fly.glow(0.22f, Color(0.8f, 1, 0.4f));
                fly.add(Firefly());
            }
        }
        for (int i = 0; i < 16; i++)
        {
            Vec3 p;
            if (!spot(p, 1, 22, 0.7f, 8, i < 5 ? 40 : 110))
                continue;
            Entity@ e = place(crystal, p, 0, 0.8f);
            e.sphere(0.9f, 3, 1 << 1);
            e.colliderAt = Vec3(0, 0.6f, 0);
            e.add(Crystal());
            Entity@ shine = Space::spawn(Vec3(0, 0.6f, 0));
            shine.glow(2.4f, Color(0.2f, 0.6f, 0.8f, 0.6f));
            shine.attach(e);
            total++;
        }

        @hero = place(robot, Vec3(2.5f, y + 0.1f, 4), 180, 1);
        hero.capsule(0.35f, 1.6f, 1);
        hero.colliderAt = Vec3(0, 0.8f, 0);
        hero.walker = true;
        hero.mass = 60;
        hero.shine = 0.5f;
        safe = hero.place;
        look = hero.place + Vec3(0, 1.4f, 0);
    }

    Entity@ place(Model@ model, const Vec3 &in at, float turn, float size)
    {
        Entity@ e = Space::spawn(at);
        e.model(model);
        e.angles = Vec3(0, turn, 0);
        e.size = Vec3(size, size, size);
        return e;
    }

    void wall(const Vec3 &in at, const Vec3 &in size, float turn)
    {
        Entity@ e = Space::spawn(at);
        e.angles = Vec3(0, turn, 0);
        e.cube(size, 2);
        e.wall = true;
    }

    // Somewhere between two heights, not too steep, away from the village.
    bool spot(Vec3 &out p, float low, float high, float flat, float clear, float within = 130)
    {
        for (int tries = 0; tries < 12; tries++)
        {
            float x = random(-within, within), z = random(-within, within);
            float y = Space::height(x, z);
            if (y > low && y < high && x * x + z * z > clear * clear && Space::normal(x, z).y > flat)
            {
                p = Vec3(x, y, z);
                return true;
            }
        }
        return false;
    }

    void update(float dt)
    {
        shown += dt;
        walk(dt);
        follow(dt);
        daylight(dt);
    }

    void walk(float dt)
    {
        Vec2 stick = Input::move();
        Vec3 ahead(-sin(yaw), 0, -cos(yaw));
        Vec3 side(cos(yaw), 0, -sin(yaw));
        Vec3 way = side * stick.x - ahead * stick.y;
        Vec3 wanted = way * (Input::held("alternate") ? 2.4f : 6);

        Vec3 motion = hero.motion;
        float grip = hero.onGround ? 12 * dt : 3 * dt;
        motion.x += (wanted.x - motion.x) * clamp(grip, 0, 1);
        motion.z += (wanted.z - motion.z) * clamp(grip, 0, 1);

        bool swimming = hero.place.y < -0.75f;
        if (swimming)
        {
            motion.y += (clamp((-0.8f - hero.place.y) * 3, -1, 2) - motion.y) * clamp(8 * dt, 0, 1);
            motion.x *= 0.95f;
            motion.z *= 0.95f;
        }
        if (Input::pressed("accept") && (hero.onGround || swimming))
        {
            motion.y = 6.2f;
            jump.play(0.4f);
        }
        hero.motion = motion;

        float going = Vec3(motion.x, 0, motion.z).length();
        if (way.length() > 0.1f)
        {
            hero.face(way, clamp(12 * dt, 0, 1));
            waving = 0;
        }
        if (Input::pressed("fire") && !Input::pressed("accept"))
            waving = 1.6f;
        waving -= dt;
        if (!hero.onGround && !swimming && abs(motion.y) > 1.5f)
            hero.animate("jump", true, 0.15f);
        else if (going > 4)
            hero.animate("run");
        else if (going > 0.5f || swimming)
            hero.animate("walk");
        else if (waving > 0)
            hero.animate("wave");
        else
            hero.animate("idle");
        hero.animationSpeed = going > 4 ? going / 6 : going > 0.5f ? going / 2.4f : 1;
        if (hero.place.y < -15)
            hero.place = safe;
    }

    void follow(float dt)
    {
        // The right stick, or the mouse while its right button is down.
        Vec2 turn = Input::padRight(0);
        yaw -= turn.x * 2.4f * dt;
        lean = clamp(lean - turn.y * 1.4f * dt, -0.1f, 1.1f);
        Vec2 mouse = Input::mouse();
        if (Input::mouseDown(1) && wasDown)
        {
            yaw -= (mouse.x - mouseWas.x) * 0.006f;
            lean = clamp(lean + (mouse.y - mouseWas.y) * 0.004f, -0.1f, 1.1f);
        }
        wasDown = Input::mouseDown(1);
        mouseWas = mouse;

        // It swings round behind as you walk.
        Vec3 side(cos(yaw), 0, -sin(yaw));
        yaw -= clamp(hero.motion.dot(side) * 0.1f, -1, 1) * dt * 1.5f;

        look = lerp(look, hero.place + Vec3(0, 1.4f, 0), clamp(9 * dt, 0, 1));
        Vec3 back(sin(yaw) * cos(lean), sin(lean), cos(yaw) * cos(lean));
        Vec3 from = look + back * away;
        // Not through a wall or a hill.
        Vec3 hit;
        Vec3 normal;
        if (Space::raycast(look, look + back * (away + 0.4f), hit, normal, (1 << 0) | (1 << 2), hero))
            from = look + back * clamp((hit - look).length() - 0.4f, 1, away);
        float least = Space::height(from.x, from.z) + 0.5f;
        from.y = from.y < least ? least : from.y < 0.4f ? 0.4f : from.y;
        Space::camera(from, look + Vec3(0, 0.3f, 0), 62);
    }

    void daylight(float dt)
    {
        hour += dt * 0.14f;
        if (hour >= 24)
            hour -= 24;
        float a = (hour - 6) / 12 * 3.14159f;       // the sun rises at 6
        float high = sin(a);
        float day = clamp(high * 2.5f + 0.35f, 0, 1);
        float dusk = clamp(1 - abs(high) * 3.2f, 0, 1);
        darkness = 1 - day;

        Color top = lerp(Color(0.015f, 0.025f, 0.08f), Color(0.2f, 0.45f, 0.85f), day);
        Color rim = lerp(Color(0.05f, 0.07f, 0.14f), Color(0.72f, 0.84f, 0.93f), day);
        rim = lerp(rim, Color(1, 0.55f, 0.3f), dusk * 0.75f);
        top = lerp(top, Color(0.35f, 0.3f, 0.5f), dusk * 0.4f);
        Space::sky(top, rim);
        Space::fog(rim, 70, 260);
        Vec3 up(cos(a) * 0.8f, high > 0.1f ? high : 0.1f, 0.42f);
        Color light = lerp(Color(0.16f, 0.2f, 0.34f), Color(0.95f, 0.9f, 0.78f), day);
        light = lerp(light, Color(1, 0.6f, 0.35f), dusk * 0.6f);
        if (high < -0.05f)
            up = Vec3(-cos(a) * 0.6f, 0.8f, 0.3f);   // the moon
        Space::sun(up, light);
        Space::ambient(lerp(Color(0.1f, 0.13f, 0.22f), Color(0.42f, 0.48f, 0.56f), day), lerp(Color(0.05f, 0.05f, 0.08f), Color(0.26f, 0.24f, 0.2f), day));
        for (uint i = 0; i < lamps.length(); i++)
        {
            float glow = darkness * (0.93f + sin(App::time() * 9 + float(i) * 2) * 0.07f);
            lamps[i].color = Color(1, 0.75f, 0.35f, glow * 0.7f);
            lamps[i].light(Color(1.5f * glow, 1.0f * glow, 0.5f * glow), 11);
        }
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);

        c.roundRect(24, 22, 236, 62, 16, Color(0, 0, 0, 0.4f));
        c.circle(54, 53, 12, Color(0.35f, 0.9f, 1));
        c.text(font, formatInt(found) + " of " + formatInt(total) + " crystals", 78, 40);

        // A clock: the sun or the moon crossing the sky.
        float a = (hour - 6) / 12 * 3.14159f;
        c.arc(c.width - 90, 92, 56, 3, 180, 360, Color(1, 1, 1, 0.35f));
        bool isDay = hour >= 6 && hour < 18;
        float b = isDay ? a : a - 3.14159f;
        c.circle(c.width - 90 - cos(b) * 56, 92 - sin(b) * 56, 11, isDay ? Color(1, 0.85f, 0.3f) : Color(0.8f, 0.85f, 1));
        int minutes = int(hour * 6) % 6 * 10;
        c.text(font, formatInt(int(hour)) + ":" + (minutes < 10 ? "0" : "") + formatInt(minutes), c.width - 90, 64, White, AlignCenter);

        if (total > 0 && found == total)
            c.text(big, "You found them all!", c.width * 0.5f, 120, Color(1, 0.9f, 0.4f), AlignCenter);
        float help = clamp(7 - shown, 0, 1);
        if (help > 0)
        {
            c.setAlpha(help);
            c.roundRect(c.width * 0.5f - 400, 640, 800, 48, 14, Color(0, 0, 0, 0.45f));
            c.text(font, Input::usingPad() ? "Left stick: walk    Right stick: look    A: jump    X: go slowly" : "Arrows: walk    Right button: look    Space: jump    Shift: go slowly", c.width * 0.5f, 650, White, AlignCenter);
            c.setAlpha(1);
        }
    }
}
