// Rigid bodies: give a collider some mass, and the engine does the rest.

class TumbleScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Sound@ throwing = Assets::sound("global:sound/whoosh.wav");
    Sound@ hit = Assets::sound("global:sound/wall.wav");
    Vec2 aim(0, 0.12f);
    float around = 0;
    int kind = 0;
    array<string> kinds = { "Wall", "Tower", "Dominoes", "Rain" };
    array<Entity@> things;
    float rain = 0;
    uint dropped = 0;
    Vec2 mouseWas;
    bool mouseDown = false;

    void onEnter()
    {
        Mesh@ floor = Mesh();
        for (int z = -10; z < 10; z++)
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
        build();
    }

    Entity@ block(const Vec3 &in at, const Vec3 &in size, const Color &in color, float mass = 1)
    {
        Entity@ e = Space::spawn(at);
        e.shape(SolidBox, color);
        e.size = size;
        e.cube(Vec3(1, 1, 1));
        e.mass = mass;
        e.gravity = 1;
        e.friction = 0.6f;
        e.shine = 0.15f;
        things.insertLast(e);
        return e;
    }

    void build()
    {
        for (uint i = 0; i < things.length(); i++)
            things[i].destroy();
        things.resize(0);
        rain = 0;
        dropped = 0;
        if (kind == 0)
        {
            for (int y = 0; y < 7; y++)
                for (int x = 0; x < 6; x++)
                    block(Vec3((float(x) - 2.5f + (y % 2 == 0 ? -0.2f : 0.2f)) * 1.02f, 0.3f + float(y) * 0.601f, 0), Vec3(1, 0.6f, 0.6f), hsv(0.02f + float((x * 7 + y * 3) % 5) * 0.012f, 0.55f, 0.75f + float((x + y * 2) % 3) * 0.06f));
        }
        else if (kind == 1)
        {
            for (int y = 0; y < 9; y++)
                for (int i = 0; i < 3; i++)
                {
                    float off = (float(i) - 1) * 0.7f;
                    Entity@ e = block(Vec3(y % 2 == 0 ? off : 0.0f, 0.25f + float(y) * 0.501f, y % 2 == 0 ? 0.0f : off), Vec3(2.1f, 0.5f, 0.66f), hsv(0.08f + float(y) * 0.01f, 0.4f, 0.9f));
                    e.angles = Vec3(0, y % 2 == 0 ? 90 : 0, 0);
                }
        }
        else if (kind == 2)
        {
            for (int i = 0; i < 26; i++)
            {
                float a = float(i) * 0.21f;
                float r = 1.6f + float(i) * 0.14f;
                Entity@ e = block(Vec3(sin(a) * r, 0.7f, cos(a) * r - 1), Vec3(0.75f, 1.4f, 0.18f), hsv(float(i) / 26.0f, 0.6f, 0.95f), 0.6f);
                e.angles = Vec3(0, a * 57.3f + 90, 0);
                if (i == 25)
                    e.push(Vec3(-cos(a) * 1.5f, 0, sin(a) * 1.5f), e.place + Vec3(0, 0.6f, 0));
            }
        }
    }

    void update(float dt)
    {
        aim += Vec2(Input::move.x, -Input::move.y) * dt * 0.6f;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != mouseWas)
            aim = Vec2((mouse.x - 640) / 640 * 0.6f, (400 - mouse.y) / 400 * 0.4f);
        mouseWas = mouse;
        aim = Vec2(clamp(aim.x, -0.6f, 0.6f), clamp(aim.y, -0.1f, 0.5f));
        if (Input::pressed("alternate"))
        {
            kind = (kind + 1) % 4;
            build();
        }
        else if (Input::pressed("cancel"))
            build();
        bool clicked = Input::pressed("fire") || Input::pressed("accept");
        if (clicked)
        {
            Entity@ ball = Space::spawn(eye() + Vec3(0, -0.4f, -0.8f));
            ball.shape(SolidSphere, hsv(random(0, 1), 0.7f, 1));
            ball.size = Vec3(0.8f, 0.8f, 0.8f);
            ball.sphere(0.5f, 1);
            ball.mass = 4;
            ball.gravity = 1;
            ball.bounce = 0.3f;
            ball.shine = 0.9f;
            ball.motion = direction() * 20;
            ball.lifetime = 12;
            throwing.play(0.5f);
        }
        if (kind == 3)
        {
            rain -= dt;
            if (rain <= 0 && dropped < 90)
            {
                rain = 0.12f;
                dropped++;
                int which = randomInt(0, 2);
                Vec3 at(random(-1.6f, 1.6f), 9, random(-1.6f, 1.6f));
                Color color = hsv(float(dropped) * 0.03f, 0.6f, 0.95f);
                if (which == 0)
                    block(at, Vec3(random(0.5f, 1), random(0.5f, 1), random(0.5f, 1)), color).angles = Vec3(random(0, 360), random(0, 360), 0);
                else
                {
                    Entity@ e = Space::spawn(at);
                    e.shape(which == 1 ? SolidSphere : SolidCapsule, color);
                    float size = random(0.6f, 0.9f);
                    e.size = Vec3(size, size * (which == 1 ? 1.0f : 0.8f), size);
                    if (which == 1)
                        e.sphere(0.5f);
                    else
                        e.capsule(0.5f, 2);
                    e.mass = 1;
                    e.gravity = 1;
                    e.bounce = 0.2f;
                    e.shine = 0.5f;
                    e.turning = Vec3(random(-90, 90), 0, random(-90, 90));
                    things.insertLast(e);
                }
            }
        }
        around = sin(App::time * 0.15f) * 0.25f;
        Space::camera(eye(), Vec3(0, 1.6f, 0), 55);
    }

    Vec3 eye() { return Vec3(sin(around) * 11, 3.2f, cos(around) * 11); }

    Vec3 direction()
    {
        Vec3 ahead = (Vec3(0, 1.6f, 0) - eye()).normalized();
        Vec3 side(-ahead.z, 0, ahead.x);
        return (ahead + side.normalized() * aim.x + Vec3(0, 1, 0) * aim.y).normalized();
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        Vec2 at;
        if (Space::toScreen(eye() + direction() * 10, at))
        {
            c.ring(at.x, at.y, 16, 3, Color(1, 1, 1, 0.8f));
            c.circle(at.x, at.y, 3, White);
        }
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Fire: throw     Alternate: next (" + kinds[kind] + ")     Cancel: build it again", 40, 668);
        c.text(font, formatInt(int(Space::contacts)) + " contacts", c.width - 40, 668, White, AlignRight);
    }
}
