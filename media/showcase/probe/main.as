// What a script can ask of the scene. Shapes that touch each other are told so, and change colour.

class Shape : Behaviour
{
    int touching = 0;
    Color own = hsv(random(), 0.45f, 0.75f);

    void start() { entity.color = own; }
    void onHit(Entity@ other) { touching++; }
    void onLeave(Entity@ other) { touching--; }
    void update(float dt) { entity.color = touching > 0 ? Color(1, 0.5f, 0.35f) : own; }
}

class ProbeScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Vec2 at(640, 360);
    Vec2 lastMouse;
    float turn = 0;

    void onEnter()
    {
        wall(640, -50, 1480, 100);
        wall(640, 770, 1480, 100);
        wall(-50, 360, 100, 920);
        wall(1330, 360, 100, 920);
        for (int i = 0; i < 26; i++)
        {
            Entity@ e = Scene::spawn(Vec2(random(80, 1200), random(80, 640)));
            if (i % 2 == 0)
            {
                float r = random(16, 46);
                e.disc(r, White);
                e.circle(r, 1, 1 << 1);
            }
            else
            {
                float w = random(30, 110), h = random(24, 70);
                e.rect(w, h, White);
                e.box(w, h, 1, 1 << 1);
            }
            e.velocity = Vec2(random(-60, 60), random(-60, 60));
            e.spin = random(-40, 40);
            e.solid = true;
            e.bounce = 1;
            e.add(Shape());
        }
    }

    void wall(float x, float y, float w, float h)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.box(w, h, 2);
        e.wall = true;
    }

    void update(float dt)
    {
        turn += dt * 0.6f;
        at += Input::move() * 420 * dt;
        Vec2 mouse = Input::mouse();
        if (Input::hasMouse() && mouse != lastMouse) at = mouse;
        lastMouse = mouse;
        at = Vec2(clamp(at.x, 20, 1260), clamp(at.y, 20, 700));
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.06f, 0.07f, 0.11f));
        Scene::draw(c);

        for (int i = 0; i < 24; i++)
        {
            float a = turn + float(i) * 0.2618f;
            Vec2 hit;
            Entity@ e = Scene::raycast(at, at + Vec2(cos(a), sin(a)) * 1500, hit, 1 << 1 | 1 << 2);
            c.line(at.x, at.y, hit.x, hit.y, 1.5f, Color(0.4f, 0.8f, 1, 0.4f));
            if (e !is null && e.group == 1) c.circle(hit.x, hit.y, 5, Yellow);
        }
        array<Entity@>@ near = Scene::within(at, 150, 1 << 1);
        c.ring(at.x, at.y, 150, 2, Color(0.5f, 1, 0.6f, 0.7f));
        for (uint i = 0; i < near.length(); i++) c.ring(near[i].x, near[i].y, 10, 3, Green);
        Entity@ nearest = Scene::nearest(at, 2000, 1 << 1);
        if (nearest !is null)
        {
            c.line(at.x, at.y, nearest.x, nearest.y, 4, White);
            c.ring(nearest.x, nearest.y, 18, 4, White);
        }
        c.circle(at.x, at.y, 8, White);
        c.text(font, formatInt(near.length()) + " within the circle", 40, 24, Green);
        c.text(font, "Move with the arrows, stick or mouse", 1240, 684, Yellow, AlignRight);
    }
}
