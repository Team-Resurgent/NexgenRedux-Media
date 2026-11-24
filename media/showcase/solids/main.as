// The shapes that are always there, with different materials, under a sun and three moving lights.

class SolidsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    array<Entity@> things;
    array<Entity@> lamps;
    float around = 0.4f;
    float lean = 0.35f;
    bool night = false;

    void onEnter()
    {
        // Something to stand them on: a mesh made by the script.
        Mesh@ floor = Mesh();
        for (int z = -8; z < 8; z++)
            for (int x = -8; x < 8; x++)
            {
                float a = float(x) * 1.5f, b = float(z) * 1.5f;
                Color tile = (x + z) % 2 == 0 ? Color(0.42f, 0.45f, 0.52f) : Color(0.3f, 0.33f, 0.4f);
                floor.quad(Vec3(a, 0, b + 1.5f), Vec3(a + 1.5f, 0, b + 1.5f), Vec3(a + 1.5f, 0, b), Vec3(a, 0, b), tile);
            }
        Entity@ ground = Space::spawn(Vec3(0, 0, 0));
        ground.mesh(floor);
        ground.shine = 0.4f;

        array<Solid> kinds = { SolidBox, SolidSphere, SolidCylinder, SolidCone, SolidTorus, SolidCapsule };
        for (uint i = 0; i < kinds.length(); i++)
        {
            float a = float(i) / float(kinds.length()) * 6.283f;
            Entity@ e = Space::spawn(Vec3(sin(a) * 4, 1.2f, cos(a) * 4));
            e.shape(kinds[i], hsv(float(i) / 6.0f, 0.65f, 0.95f));
            e.size = Vec3(1.4f, 1.4f, 1.4f);
            e.shine = float(i) / 5.0f;
            things.insertLast(e);
        }
        // The middle one is made of several, moving together.
        Entity@ middle = Space::spawn(Vec3(0, 2, 0));
        middle.shape(SolidSphere, Color(0.95f, 0.95f, 1));
        middle.shine = 1;
        things.insertLast(middle);
        for (int i = 0; i < 3; i++)
        {
            Entity@ ring = Space::spawn(Vec3(0, 0, 0));
            ring.attach(middle);
            ring.shape(SolidTorus, hsv(float(i) * 0.33f, 0.5f, 1));
            ring.size = Vec3(2.2f, 1, 2.2f) * (1 + float(i) * 0.35f);
            ring.shine = 1;
            things.insertLast(ring);
        }
        for (int i = 0; i < 3; i++)
        {
            Entity@ lamp = Space::spawn(Vec3(0, 2, 0));
            lamp.glow(0.9f, hsv(float(i) * 0.33f, 0.6f, 1));
            lamp.light(hsv(float(i) * 0.33f, 0.6f, 1.2f), 6);
            lamps.insertLast(lamp);
        }
        Space::shadows(0.7f, 14);
    }

    void update(float dt)
    {
        around += (Input::move.x * 1.6f + 0.15f) * dt;
        lean = clamp(lean - Input::move.y * dt, 0.1f, 1.2f);
        if (Input::pressed("accept"))
            night = !night;

        float t = App::time;
        for (uint i = 0; i < things.length(); i++)
        {
            if (i <= 6)
                things[i].turn(Vec3(0.3f, 1, 0.2f), dt * (i == 6 ? 20 : 40));
            if (i < 6)
            {
                Vec3 p = things[i].place;
                p.y = 1.3f + sin(t * 1.3f + float(i)) * 0.3f;
                things[i].place = p;
            }
            else if (i > 6)
                things[i].angles = Vec3(t * 40 + float(i) * 60, t * 25, float(i) * 60);
        }
        for (uint i = 0; i < lamps.length(); i++)
        {
            float a = t * 0.8f + float(i) * 2.09f;
            lamps[i].place = Vec3(sin(a) * 2.6f, 0.9f + sin(t * 1.7f + a) * 0.5f, cos(a) * 2.6f);
        }
        if (night)
        {
            Space::sun(Vec3(-0.4f, 0.8f, 0.3f), Color(0.12f, 0.14f, 0.25f));
            Space::ambient(Color(0.07f, 0.08f, 0.14f), Color(0.04f, 0.04f, 0.06f));
            Space::sky(Color(0.01f, 0.015f, 0.05f), Color(0.06f, 0.07f, 0.14f));
        }
        else
        {
            Space::sun(Vec3(sin(t * 0.1f + 0.6f), 0.9f, 0.5f), Color(0.95f, 0.9f, 0.8f));
            Space::ambient(Color(0.3f, 0.34f, 0.42f), Color(0.2f, 0.19f, 0.18f));
            Space::sky(Color(0.2f, 0.42f, 0.8f), Color(0.72f, 0.82f, 0.92f));
        }
        Space::camera(Vec3(sin(around) * 10 * cos(lean), 1 + sin(lean) * 10, cos(around) * 10 * cos(lean)), Vec3(0, 1.2f, 0), 55);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Look around with the stick or arrows. Accept: " + (night ? "day" : "night"), 40, 668);
        c.text(font, formatInt(int(Space::triangles)) + " triangles", c.width - 40, 668, White, AlignRight);
    }
}
