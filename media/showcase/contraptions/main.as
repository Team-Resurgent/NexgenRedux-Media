// Polygons, ground of chains, platforms that are solid only from above, and joints of every kind: a car whose
// wheels are driven by hinges' motors, a lamp on a spring, a weight on a rope, a block on a rail, a swinging door.

class Rock
{
    Entity@ body;
    array<Vec2> corners;
    Color color;
}

class ContraptionsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Sound@ pop = Assets::sound("global:sound/pop.wav");
    Sound@ knock = Assets::sound("global:sound/hit.wav");
    array<Vec2> hills;
    array<Rock@> rocks;
    Entity@ car;
    Entity@ back;
    Entity@ front;
    Entity@ lamp;
    Entity@ weight;
    Entity@ held;
    Vec2 cursor(640, 200);
    Vec2 lastMouse;
    array<Entity@> platforms;
    float fountain = 0;
    float sinceKnock = 0;

    void onEnter()
    {
        Scene::gravity = Vec2(0, 1000);

        // Rolling ground, as a chain of lines.
        for (int i = 0; i <= 64; i++)
        {
            float x = float(i) * 20;
            hills.insertLast(Vec2(x, 610 + sin(x * 0.012f) * 40 + sin(x * 0.031f + 1) * 18));
        }
        hills.insertLast(Vec2(1280, 200));
        hills.insertAt(0, Vec2(0, 200));
        Entity@ ground = Scene::spawn(Vec2(0, 0));
        ground.chain(hills);

        // Two platforms that balls come up through and land on.
        platform(1010, 330, 220);
        platform(1010, 440, 220);

        // The car: a polygon body, and two wheels on hinges that drive.
        array<Vec2> shell = { Vec2(-62, 8), Vec2(-58, -12), Vec2(-24, -16), Vec2(-8, -36), Vec2(34, -36), Vec2(52, -14), Vec2(64, -8), Vec2(64, 8) };
        @car = rock(160, 450, shell, 4, Color(0.85f, 0.3f, 0.25f)).body;
        @back = wheel(160 - 40, 470);
        @front = wheel(160 + 42, 470);
        Scene::hinge(back, car, back.position, 0, 0, 0, 0);
        Scene::hinge(front, car, front.position, 0, 0, 0, 0);

        // A lamp on a spring, and a weight on a rope, from the sky.
        @lamp = Scene::spawn(Vec2(470, 230));
        lamp.disc(18, Yellow);
        lamp.circle(18);
        lamp.gravity = 1;
        lamp.mass = 1;
        Scene::spring(lamp, null, lamp.position, Vec2(470, 60), 1.5f, 0.1f, 120);
        @weight = Scene::spawn(Vec2(640, 260));
        weight.rect(40, 40, Color(0.5f, 0.55f, 0.65f));
        weight.box(40, 40);
        weight.gravity = 1;
        weight.mass = 3;
        Scene::rope(weight, null, weight.position + Vec2(0, -20), Vec2(700, 60), 230);

        // A block on a rail, and a door that swings between two angles.
        Entity@ rail = Scene::spawn(Vec2(790, 170));
        rail.rect(300, 4, Color(0.4f, 0.42f, 0.5f));
        Entity@ slider = Scene::spawn(Vec2(790, 160));
        slider.rect(50, 24, Color(0.3f, 0.65f, 0.9f));
        slider.box(50, 24);
        slider.gravity = 1;
        slider.mass = 1;
        Scene::slider(slider, null, slider.position, Vec2(1, 0), -125, 125);
        Entity@ door = Scene::spawn(Vec2(330, 380));
        door.rect(10, 120, Color(0.75f, 0.6f, 0.4f));
        door.box(10, 120);
        door.gravity = 1;
        door.mass = 1;
        Scene::hinge(door, null, Vec2(330, 320), -80, 80);

        for (int i = 0; i < 6; i++)
            drop(Vec2(560 + float(i) * 40, 80 - float(i) * 30));
    }

    void platform(float x, float y, float w)
    {
        Entity@ p = Scene::spawn(Vec2(x, y));
        p.rect(w, 8, Color(0.55f, 0.6f, 0.75f, 0.8f));
        p.box(w, 8);
        p.wall = true;
        p.oneWay = true;
        platforms.insertLast(p);
    }

    Entity@ wheel(float x, float y)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.disc(17, Color(0.15f, 0.15f, 0.18f));
        e.circle(17);
        e.gravity = 1;
        e.mass = 1;
        e.friction = 1.2f;
        Entity@ hub = Scene::spawn(Vec2(8, 0));
        hub.disc(4, Gray);
        hub.attach(e);
        hub.layer = 1;
        return e;
    }

    Rock@ rock(float x, float y, const array<Vec2> &in corners, float mass, const Color &in color)
    {
        Rock r;
        @r.body = Scene::spawn(Vec2(x, y));
        r.body.polygon(corners);
        r.body.gravity = 1;
        r.body.mass = mass;
        r.body.friction = 0.7f;
        r.corners = corners;
        r.color = color;
        rocks.insertLast(r);
        return r;
    }

    void drop(const Vec2 &in at)
    {
        // A rock of from three to seven corners, roughly round.
        array<Vec2> corners;
        int count = randomInt(3, 7);
        float size = random(16, 34);
        for (int i = 0; i < count; i++)
        {
            float a = float(i) * 6.28318f / float(count) + random(-0.2f, 0.2f);
            float r = size * random(0.75f, 1.2f);
            corners.insertLast(Vec2(cos(a) * r, sin(a) * r));
        }
        rock(at.x, at.y, corners, 1, hsv(random(0.05f, 0.15f), random(0.3f, 0.6f), random(0.6f, 0.9f)));
    }

    void update(float dt)
    {
        cursor += Input::move * 600 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != lastMouse) cursor = mouse;
        lastMouse = mouse;
        cursor = Vec2(clamp(cursor.x, 20, 1260), clamp(cursor.y, 20, 700));

        // Left and right drive the car, unless something is held.
        float drive = held is null ? Input::move.x : 0;
        Scene::motor(back, drive * 700, drive != 0 ? 4e4f : 1e4f);
        Scene::motor(front, drive * 700, drive != 0 ? 4e4f : 1e4f);

        if (Input::repeated("accept") && rocks.length() < 80)
        {
            pop.play(0.4f, (cursor.x - 640) / 640, random(0.8f, 1.3f));
            drop(cursor);
        }

        // Fire picks up whatever is under the pointer, and lets go of it.
        if (Input::pressed("fire") || (Input::hasMouse && Input::mouseDown(0) && held is null))
        {
            array<Entity@>@ under = Scene::within(cursor, 4);
            for (uint i = 0; i < under.length() && held is null; i++)
                if (under[i].mass > 0 && under[i] !is car && under[i] !is back && under[i] !is front)
                {
                    @held = under[i];
                    Scene::drag(held, cursor, 8);
                }
        }
        else if (held !is null && (Input::released("fire") || (Input::hasMouse && !Input::mouseDown(0) && !Input::held("fire"))))
        {
            Scene::unjoin(held);
            @held = null;
        }
        if (held !is null) Scene::dragTo(held, cursor);

        // Balls come up through the platforms and land on them.
        fountain -= dt;
        if (fountain <= 0)
        {
            fountain = 1.2f;
            Entity@ ball = Scene::spawn(Vec2(random(930, 1090), 560));
            ball.disc(10, hsv(random(), 0.6f, 1));
            ball.circle(10);
            ball.gravity = 1;
            ball.mass = 0.3f;
            ball.bounce = 0.3f;
            ball.velocity = Vec2(random(-30, 30), -900);
            ball.lifetime = 12;
        }

        // A knock when the weight hits something hard.
        sinceKnock += dt;
        Vec2 at, normal;
        float impulse;
        for (uint i = 0; i < rocks.length(); i++)
            if (sinceKnock > 0.15f && Scene::contact(weight, rocks[i].body, at, normal, impulse) && impulse > 400)
            {
                knock.play(0.3f, (at.x - 640) / 640);
                sinceKnock = 0;
            }

        if (Input::pressed("cancel")) Screens::replace("contraptions");
        bool shapes = Input::padTriggers(0).x > 0.5f || Input::key("C");
        if (shapes && !wasShapes) Scene::showShapes = !Scene::showShapes;
        wasShapes = shapes;
    }
    bool wasShapes = false;

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.16f, 0.22f, 0.34f), Color(0.07f, 0.08f, 0.13f));

        // The ground, filled down from the chain.
        array<Vec2> land;
        for (uint i = 1; i + 1 < hills.length(); i++)
            land.insertLast(hills[i]);
        land.insertLast(Vec2(1280, 720));
        land.insertLast(Vec2(0, 720));
        c.polygon(land, Color(0.2f, 0.3f, 0.22f));
        c.polyline(land, 4, Color(0.35f, 0.55f, 0.3f));

        // What holds the lamp, the weight and the door.
        c.line(470, 60, lamp.position.x, lamp.position.y, 2, fade(White, 0.4f));
        c.circle(470, 60, 5, Gray);
        Vec2 top = weight.position + Vec2(sin(-weight.rotation * 3.14159f / 180) * 20, -cos(weight.rotation * 3.14159f / 180) * 20);
        c.line(700, 60, top.x, top.y, 2, Color(0.75f, 0.7f, 0.55f));
        c.circle(700, 60, 5, Gray);
        c.circle(330, 320, 6, Gray);

        Scene::draw(c);
        for (uint i = 0; i < rocks.length(); i++)
        {
            Rock@ r = rocks[i];
            c.push();
            c.translate(r.body.position.x, r.body.position.y);
            c.rotate(r.body.rotation);
            c.polygon(r.corners, r.color);
            c.polygonLine(r.corners, 2, Color(r.color.r * 0.6f, r.color.g * 0.6f, r.color.b * 0.6f));
            c.pop();
        }
        // The car's windows, over its body.
        c.push();
        c.translate(car.position.x, car.position.y);
        c.rotate(car.rotation);
        array<Vec2> window = { Vec2(-4, -14), Vec2(-4, -31), Vec2(30, -31), Vec2(44, -14) };
        c.polygon(window, Color(0.6f, 0.8f, 0.95f, 0.8f));
        c.pop();

        c.ring(cursor.x, cursor.y, held is null ? 12 : 8, 3, held is null ? White : Yellow);
        c.text(font, "Left, right: drive    Accept: rock    Fire: pick up    Cancel: again    C: shapes", 640, 16, Yellow, AlignCenter);
    }
}
