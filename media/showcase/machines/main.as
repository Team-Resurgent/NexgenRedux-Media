// More joints: a buggy on sprung wheels, which a balloon follows; a lift of two platforms on a pulley, which rocks
// weigh down; and a train of gears, the first turned by a motor, each of the others by the one before.

class Gear
{
    Entity@ body;
    float radius;
    int teeth;
    Color color;
}

class MachinesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ title = Assets::font("global:font/chunky.fnt", 36);
    Sound@ pop = Assets::sound("global:sound/pop.wav");
    array<Vec2> ground;
    Entity@ buggy;
    Entity@ back;
    Entity@ front;
    Entity@ balloon;
    Entity@ left;
    Entity@ right;
    Entity@ held;
    array<Gear@> gears;
    array<Entity@> rocks;
    array<array<Vec2>> rockShapes;
    Vec2 cursor(640, 200);
    Vec2 lastMouse;
    float motor = 60;

    void onEnter()
    {
        Scene::gravity = Vec2(0, 1000);

        // Bumpy ground, walled at each end.
        ground.insertLast(Vec2(0, 100));
        for (int i = 0; i <= 40; i++)
        {
            float x = float(i) * 20;
            float bumps = i > 3 && i < 37 ? (i % 6 < 2 ? -10 : 0) + sin(x * 0.05f) * 6 : 0;
            ground.insertLast(Vec2(x, 640 + bumps));
        }
        ground.insertLast(Vec2(1280, 640));
        ground.insertLast(Vec2(1280, 100));
        Entity@ land = Scene::spawn(Vec2(0, 0));
        land.chain(ground);

        // The buggy: a light body on two wheels, each sprung on an upright line through it.
        @buggy = Scene::spawn(Vec2(200, 560));
        array<Vec2> shell = { Vec2(-55, 6), Vec2(-50, -10), Vec2(-14, -12), Vec2(0, -28), Vec2(30, -28), Vec2(44, -10), Vec2(58, -4), Vec2(58, 6) };
        buggy.polygon(shell);
        buggy.gravity = 1;
        buggy.mass = 2;
        @back = wheel(200 - 38, 598);
        @front = wheel(200 + 40, 598);
        Scene::wheel(back, buggy, Vec2(0, 1), 3.5f, 0.5f);
        Scene::wheel(front, buggy, Vec2(0, 1), 3.5f, 0.5f);

        // A balloon that floats where it is now, above the buggy, wherever it goes.
        @balloon = Scene::spawn(Vec2(190, 420));
        balloon.circle(22);
        balloon.mass = 0.2f;
        balloon.gravity = 0;
        Scene::follow(buggy, balloon, 3, 0.2f);

        // The lift: two platforms on a pulley, each kept upright on its line.
        @left = platform(900, 400);
        @right = platform(1130, 400);
        Scene::pulley(left, right, Vec2(900, 90), Vec2(1130, 90), left.position, right.position, 1);

        // The gears, each the size its teeth make it, meshing with the last.
        gear(470, 230, 18, Color(0.85f, 0.65f, 0.3f));
        gear(0, 0, 12, Color(0.6f, 0.75f, 0.85f));
        gear(0, 0, 8, Color(0.85f, 0.45f, 0.4f));
        gear(0, 0, 14, Color(0.6f, 0.8f, 0.5f));
        Scene::hinge(gears[0].body, null, gears[0].body.position, 0, 0, motor, 1e6f);
    }

    Entity@ wheel(float x, float y)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.circle(16);
        e.gravity = 1;
        e.mass = 0.5f;
        e.friction = 1.3f;
        return e;
    }

    Entity@ platform(float x, float y)
    {
        Entity@ p = Scene::spawn(Vec2(x, y));
        p.box(150, 14);
        p.gravity = 1;
        p.mass = 2;
        p.friction = 0.9f;
        Scene::slider(p, null, p.position, Vec2(0, 1), -260, 200);
        return p;
    }

    void gear(float x, float y, int teeth, const Color &in color)
    {
        // 14 units from one tooth to the next, along the circle where they mesh.
        float radius = float(teeth) * 14 / 6.28318f;
        if (gears.length() > 0)
        {
            Gear@ last = gears[gears.length() - 1];
            float turn = gears.length() % 2 == 1 ? 0.0f : 75.0f;
            Vec2 way = Vec2(1, 0).rotated(turn - 20);
            Vec2 at = last.body.position + way * (last.radius + radius);
            x = at.x;
            y = at.y;
        }
        Gear g;
        @g.body = Scene::spawn(Vec2(x, y));
        g.body.circle(radius - 6);
        g.body.mass = 1;
        g.body.gravity = 0;
        g.radius = radius;
        g.teeth = teeth;
        g.color = color;
        if (gears.length() > 0)
        {
            Gear@ last = gears[gears.length() - 1];
            Scene::hinge(g.body, null, g.body.position);
            // Turned the other way, as many times as fewer teeth it has; half a tooth round, so the teeth meet gaps.
            g.body.rotation = 180.0f / float(teeth);
            Scene::gear(last.body, g.body, float(last.teeth) / float(teeth));
        }
        gears.insertLast(g);
    }

    void drop(const Vec2 &in at)
    {
        array<Vec2> corners;
        int count = randomInt(4, 6);
        float size = random(14, 22);
        for (int i = 0; i < count; i++)
        {
            float a = float(i) * 6.28318f / float(count) + random(-0.2f, 0.2f);
            corners.insertLast(Vec2(cos(a), sin(a)) * size * random(0.8f, 1.15f));
        }
        Entity@ rock = Scene::spawn(at);
        rock.polygon(corners);
        rock.gravity = 1;
        rock.mass = 1;
        rock.friction = 0.8f;
        rocks.insertLast(rock);
        rockShapes.insertLast(corners);
    }

    void update(float dt)
    {
        cursor += Input::move * 600 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != lastMouse) cursor = mouse;
        lastMouse = mouse;
        cursor = Vec2(clamp(cursor.x, 20, 1260), clamp(cursor.y, 20, 700));

        float drive = held is null ? Input::move.x : 0;
        Scene::motor(back, drive * 900, drive != 0 ? 2e4f : 4e3f);
        Scene::motor(front, drive * 900, drive != 0 ? 2e4f : 4e3f);

        // Up and down speed the gears up and slow them.
        if (Input::repeated("up")) motor = min(motor + 30, 240);
        if (Input::repeated("down")) motor = max(motor - 30, -240);
        Scene::motor(gears[0].body, motor, 1e6f);

        if (Input::repeated("accept") && rocks.length() < 40)
        {
            pop.play(0.4f, (cursor.x - 640) / 640, random(0.8f, 1.3f));
            drop(cursor);
        }

        if (Input::pressed("fire") || (Input::hasMouse && Input::mouseDown(0) && held is null))
        {
            array<Entity@>@ under = Scene::within(cursor, 4);
            for (uint i = 0; i < under.length() && held is null; i++)
                if (rocks.findByRef(under[i]) >= 0)
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

        if (Input::pressed("cancel")) Screens::replace("machines");
        bool shapes = Input::padTriggers(0).x > 0.5f || Input::key("C");
        if (shapes && !wasShapes) Scene::showShapes = !Scene::showShapes;
        wasShapes = shapes;
    }
    bool wasShapes = false;

    void drawGear(Canvas@ c, Gear@ g)
    {
        array<Vec2> outline;
        for (int i = 0; i < g.teeth; i++)
        {
            float a = 360.0f * float(i) / float(g.teeth);
            float step = 360.0f / float(g.teeth);
            outline.insertLast(Vec2(g.radius - 5, 0).rotated(a));
            outline.insertLast(Vec2(g.radius + 5, 0).rotated(a + step * 0.2f));
            outline.insertLast(Vec2(g.radius + 5, 0).rotated(a + step * 0.45f));
            outline.insertLast(Vec2(g.radius - 5, 0).rotated(a + step * 0.65f));
        }
        c.push();
        c.translate(g.body.position.x, g.body.position.y);
        c.rotate(g.body.rotation);
        c.polygon(outline, g.color);
        c.polygonLine(outline, 2, Color(g.color.r * 0.5f, g.color.g * 0.5f, g.color.b * 0.5f));
        c.circle(0, 0, g.radius * 0.45f, Color(g.color.r * 0.75f, g.color.g * 0.75f, g.color.b * 0.75f));
        c.line(-g.radius * 0.45f, 0, g.radius * 0.45f, 0, 4, Color(g.color.r * 0.5f, g.color.g * 0.5f, g.color.b * 0.5f));
        c.circle(0, 0, 5, Gray);
        c.pop();
    }

    void drawWheel(Canvas@ c, Entity@ w)
    {
        // Its spring, from the body above it.
        Vec2 top = Vec2(w.position.x, buggy.position.y - 6);
        c.line(top.x, top.y, w.position.x, w.position.y, 5, Color(0.55f, 0.55f, 0.6f));
        c.push();
        c.translate(w.position.x, w.position.y);
        c.rotate(w.rotation);
        c.circle(0, 0, 16, Color(0.13f, 0.13f, 0.16f));
        c.circle(0, 0, 8, Color(0.55f, 0.55f, 0.6f));
        c.rect(-2, -14, 4, 28, Color(0.35f, 0.35f, 0.4f));
        c.pop();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.2f, 0.18f, 0.3f), Color(0.08f, 0.07f, 0.12f));

        array<Vec2> land;
        for (uint i = 1; i + 1 < ground.length(); i++)
            land.insertLast(ground[i]);
        land.insertLast(Vec2(1280, 720));
        land.insertLast(Vec2(0, 720));
        c.polygon(land, Color(0.28f, 0.22f, 0.2f));
        c.polyline(land, 4, Color(0.5f, 0.38f, 0.3f));

        for (uint i = 0; i < gears.length(); i++)
            drawGear(c, gears[i]);

        // The lift's ropes over its two wheels, and the beam they hang from.
        c.rect(860, 70, 310, 10, Color(0.4f, 0.4f, 0.48f));
        c.line(900, 90, 1130, 90, 2, Color(0.8f, 0.75f, 0.6f));
        c.line(900, 90, left.position.x, left.position.y, 2, Color(0.8f, 0.75f, 0.6f));
        c.line(1130, 90, right.position.x, right.position.y, 2, Color(0.8f, 0.75f, 0.6f));
        c.circle(900, 90, 10, Gray);
        c.circle(1130, 90, 10, Gray);
        c.rect(left.position.x - 75, left.position.y - 7, 150, 14, Color(0.45f, 0.6f, 0.8f));
        c.rect(right.position.x - 75, right.position.y - 7, 150, 14, Color(0.45f, 0.6f, 0.8f));

        // The balloon on its string.
        c.line(buggy.position.x - 10, buggy.position.y - 20, balloon.position.x, balloon.position.y + 22, 1.5f, fade(White, 0.6f));
        c.ellipse(balloon.position.x, balloon.position.y, 20, 24, Color(0.95f, 0.35f, 0.45f));
        c.ellipse(balloon.position.x - 6, balloon.position.y - 8, 5, 7, fade(White, 0.5f));

        drawWheel(c, back);
        drawWheel(c, front);
        c.push();
        c.translate(buggy.position.x, buggy.position.y);
        c.rotate(buggy.rotation);
        array<Vec2> shell = { Vec2(-55, 6), Vec2(-50, -10), Vec2(-14, -12), Vec2(0, -28), Vec2(30, -28), Vec2(44, -10), Vec2(58, -4), Vec2(58, 6) };
        c.polygon(shell, Color(0.95f, 0.7f, 0.2f));
        array<Vec2> window = { Vec2(3, -12), Vec2(3, -24), Vec2(27, -24), Vec2(38, -12) };
        c.polygon(window, Color(0.6f, 0.8f, 0.95f, 0.85f));
        c.pop();

        for (uint i = 0; i < rocks.length(); i++)
        {
            c.push();
            c.translate(rocks[i].position.x, rocks[i].position.y);
            c.rotate(rocks[i].rotation);
            c.polygon(rockShapes[i], Color(0.6f, 0.58f, 0.55f));
            c.polygonLine(rockShapes[i], 2, Color(0.35f, 0.33f, 0.32f));
            c.pop();
        }
        Scene::draw(c);

        c.filter = FilterNearest;
        c.text(title, "MACHINES", 40, 30, White);
        c.filter = FilterLinear;
        c.text(font, "Gears: " + int(motor) + " degrees a second", 40, 82, fade(White, 0.7f));
        c.ring(cursor.x, cursor.y, held is null ? 12 : 8, 3, held is null ? White : Yellow);
        c.text(font, "Left, right: drive    Up, down: gears    Accept: rock    Fire: pick up    Cancel: again", 640, 690, Yellow, AlignCenter);
    }
}
