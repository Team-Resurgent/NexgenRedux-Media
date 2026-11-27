// Rigid bodies: give a collider some mass and the engine does the rest.

class PhysicsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Sound@ pop = Assets::sound("global:sound/pop.wav");
    Sound@ boom = Assets::sound("global:sound/boom.wav");
    Vec2 cursor(640, 180);
    Vec2 lastMouse;
    Entity@ ball;

    void onEnter()
    {
        Scene::gravity = Vec2(0, 1400);
        block(640, 700, 1280, 40, 0, Color(0.2f, 0.24f, 0.32f)).wall = true;
        block(-10, 360, 40, 760, 0, Color(0.2f, 0.24f, 0.32f)).wall = true;
        block(1290, 360, 40, 760, 0, Color(0.2f, 0.24f, 0.32f)).wall = true;

        // A pyramid.
        for (int row = 0; row < 7; row++)
            for (int i = 0; i < 7 - row; i++)
                block(800 + float(i) * 54 + float(row) * 27, 656 - float(row) * 48, 50, 46, 1, hsv(0.05f + float(row) * 0.05f, 0.6f, 0.95f));

        // A wrecking ball on a chain.
        Entity@ before = null;
        for (int i = 0; i < 12; i++)
        {
            Entity@ link = block(583 - float(i) * 34, 70, 34, 10, 1.5f, Color(0.6f, 0.64f, 0.7f));
            Scene::join(link, before, Vec2(600 - float(i) * 34, 70));
            @before = link;
        }
        @ball = round(600 - 12 * 34 - 32, 70, 36, 12, Color(0.35f, 0.37f, 0.42f));
        ball.bounce = 0.1f;
        Scene::join(ball, before, Vec2(600 - 12 * 34, 70));

        // A seesaw with something on each end.
        Entity@ post = block(250, 655, 24, 50, 0, Color(0.4f, 0.34f, 0.3f));
        post.wall = true;
        Entity@ plank = block(250, 622, 300, 14, 2, Color(0.75f, 0.6f, 0.4f));
        Scene::join(plank, null, Vec2(250, 622));
        block(130, 590, 44, 44, 1, Green);
        block(370, 590, 30, 30, 0.6f, Blue);
    }

    Entity@ block(float x, float y, float w, float h, float mass, const Color &in color)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.rect(w, h, color);
        e.box(w, h);
        if (mass > 0)
        {
            e.gravity = 1;
            e.mass = mass;
            e.friction = 0.6f;
        }
        return e;
    }

    Entity@ round(float x, float y, float r, float mass, const Color &in color)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.disc(r, color);
        e.circle(r);
        e.gravity = 1;
        e.mass = mass;
        e.bounce = 0.4f;
        Entity@ spot = Scene::spawn(Vec2(r * 0.5f, 0));   // so that turning shows
        spot.disc(r * 0.18f, White);
        spot.attach(e);
        spot.layer = 1;
        return e;
    }

    void update(float dt)
    {
        cursor += Input::move * 600 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != lastMouse) cursor = mouse;
        lastMouse = mouse;
        cursor = Vec2(clamp(cursor.x, 40, 1240), clamp(cursor.y, 20, 660));
        if (Input::repeated("accept") && Scene::count < 260)
        {
            pop.play(0.4f, (cursor.x - 640) / 640, random(0.8f, 1.3f));
            if (random() < 0.5f) round(cursor.x, cursor.y, random(14, 30), 1, hsv(random(), 0.6f, 1));
            else block(cursor.x, cursor.y, random(26, 64), random(26, 64), 1, hsv(random(), 0.5f, 0.95f)).rotation = random(0, 90);
        }
        if (Input::pressed("alternate"))
        {
            boom.play(0.8f, (cursor.x - 640) / 640);
            array<Entity@>@ near = Scene::within(cursor, 260);
            for (uint i = 0; i < near.length(); i++)
            {
                Vec2 away = near[i].position - cursor;
                float far = sqrt(away.x * away.x + away.y * away.y) + 1;
                if (near[i].mass > 0) near[i].push(away / far * (1 - far / 400) * 900 * near[i].mass, near[i].position + Vec2(random(-8, 8), random(-8, 8)));
            }
        }
        if (Input::pressed("cancel")) Screens::replace("physics");
        // Not an action of its own, as the others are taken: the left trigger, or C.
        bool shapes = Input::padTriggers(0).x > 0.5f || Input::key("C");
        if (shapes && !wasShapes) Scene::showShapes = !Scene::showShapes;
        wasShapes = shapes;
    }
    bool wasShapes = false;

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.1f, 0.13f, 0.2f), Color(0.05f, 0.06f, 0.1f));
        c.circle(600, 70, 9, Gray);
        Scene::draw(c);
        c.ring(cursor.x, cursor.y, 14, 3, White);
        c.text(font, formatInt(Scene::count) + " bodies, " + formatInt(Scene::contacts) + " contacts", 40, 20, Gray);
        c.text(font, "Accept: drop    Alternate: blast    Cancel: start again    Left trigger, C: shapes", 1240, 20, Yellow, AlignRight);
    }
}
