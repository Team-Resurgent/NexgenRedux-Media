// How a view is finished: corners darkened by ambient occlusion, a wet floor reflecting, depth of field with bokeh, the
// eye adjusting to the light, and god rays from a shader of our own. Paint thrown with fire stays as decals, and the
// panel is frosted glass. The first five need a GPU that sees depth; decals and blur are everywhere.

class LensScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ small = Assets::font("global:freesans.sfn", 18);
    Model@ column = Assets::model("global:model/column.glb");
    Model@ robot = Assets::model("global:model/robot.glb");
    Model@ lantern = Assets::model("global:model/lantern.glb");
    Texture@ splash = Assets::texture("global:picture/decal-splash.png");
    Texture@ scorch = Assets::texture("global:picture/decal-scorch.png");
    Effect@ rays;
    array<string> names = { "Ambient occlusion", "Reflections", "Depth of field", "Auto exposure", "God rays" };
    array<bool> on = { true, true, false, false, true };
    uint row = 0;
    float around = 0.6f;
    bool depth = false;
    uint thrown = 0;
    Entity@ dancer;

    void onEnter()
    {
        depth = Space::depthEffects;
        // Our own shader for god rays needs to see how far away things are.
        if (depth)
            @rays = Assets::effect("global:effect/rays.fx");
        // A dark, polished floor, in tiles.
        Mesh@ floor = Mesh();
        for (int z = -10; z < 10; z++)
            for (int x = -10; x < 10; x++)
            {
                float a = float(x) * 2, b = float(z) * 2;
                float shade = (x + z) % 2 == 0 ? 0.22f : 0.17f;
                floor.quad(Vec3(a, 0, b + 2), Vec3(a + 2, 0, b + 2), Vec3(a + 2, 0, b), Vec3(a, 0, b), Color(shade, shade * 1.05f, shade * 1.15f));
            }
        Entity@ ground = Space::spawn(Vec3());
        ground.mesh(floor);
        ground.shine = 0.9f;
        Space::ground(0);
        // A ring of columns, crates between them, and lanterns.
        for (int i = 0; i < 10; i++)
        {
            float a = float(i) / 10 * 6.283185f;
            Entity@ c = Space::spawn(Vec3(cos(a) * 8.5f, 0, sin(a) * 8.5f));
            c.model(column);
            c.size = Vec3(1.2f, 1.6f, 1.2f);
            if (i % 2 == 0)
            {
                Entity@ box = Space::spawn(Vec3(cos(a + 0.31f) * 7.5f, 0.45f, sin(a + 0.31f) * 7.5f));
                box.shape(SolidBox, Color(0.62f, 0.45f, 0.28f));
                box.size = Vec3(0.9f, 0.9f, 0.9f);
                box.angles = Vec3(0, a * 57.3f + 20, 0);
            }
            else
            {
                Entity@ l = Space::spawn(Vec3(cos(a + 0.31f) * 7.5f, 0, sin(a + 0.31f) * 7.5f));
                l.model(lantern);
                l.light(Color(1, 0.7f, 0.35f), 6);
            }
        }
        // Bright points far off, for the bokeh to show.
        for (int i = 0; i < 24; i++)
        {
            float a = float(i) / 24 * 6.283185f;
            Entity@ b = Space::spawn(Vec3(cos(a) * 16, 1 + float(i % 3) * 1.4f, sin(a) * 16));
            b.shape(SolidSphere, hsv(float(i) / 24, 0.5f, 1));
            b.size = Vec3(0.25f, 0.25f, 0.25f);
            b.glowing = 1;
            b.shadow = false;
        }
        @dancer = Space::spawn(Vec3(0, 0, 0));
        dancer.model(robot);
        dancer.animate("dance");
        Space::sky(Color(0.18f, 0.3f, 0.55f), Color(0.95f, 0.78f, 0.55f));
        Space::sun(Vec3(-0.9f, 0.22f, -0.4f), Color(1, 0.85f, 0.65f));
        Space::ambient(Color(0.35f, 0.38f, 0.45f), Color(0.2f, 0.18f, 0.16f));
        Space::fog(Color(0.95f, 0.78f, 0.55f), 20, 45);
        Space::shadows(0.6f, 20);
        Space::decals = 40;
        if (rays !is null)
        {
            rays.set(0, 1.4f);
            rays.set(1, 0.85f);
            rays.set(4, 1);
            rays.set(5, 0.85f);
            rays.set(6, 0.6f);
        }
        apply();
    }

    void apply()
    {
        Space::occlusion(on[0] ? 1.0f : 0.0f, 0.7f);
        Space::reflections(on[1] ? 0.55f : 0.0f);
        // Sharp on the robot, wherever the camera is.
        Space::focus(on[2] ? 5.0f : 0.0f, 0.8f, 14, 5, 1.5f);
        Space::autoExposure(on[3] ? 0.4f : 0.0f);
    }

    void update(float dt)
    {
        if (Input::pressed("up"))
            row = (row + names.length() - 1) % names.length();
        if (Input::pressed("down"))
            row = (row + 1) % names.length();
        if (Input::pressed("accept"))
        {
            on[row] = !on[row];
            apply();
        }
        around += dt * 0.12f;
        Vec3 eye(cos(around) * 5, 1.9f + sin(around * 0.7f) * 0.5f, sin(around) * 5);
        Space::camera(eye, Vec3(0, 1.1f, 0), 55);
        // Paint where the middle of the view lands, or at the floor near the robot.
        if (Input::pressed("fire"))
        {
            Vec3 hit, normal;
            Vec3 way = Space::ray(Vec2(640 + random(-300, 300), 450 + random(-60, 200)));
            if (Space::raycast(eye, eye + way * 40, hit, normal))
            {
                bool burn = thrown % 4 == 3;
                Space::decal(burn ? scorch : splash, hit, normal, random(0.8f, 1.6f), random(0, 360), burn ? White : hsv(random(0, 1), 0.75f, 0.95f));
                thrown++;
            }
        }
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        if (on[4] && rays !is null)
            c.effect(rays);
        // Frosted glass behind the panel.
        c.clip(24, 22, 440, 210);
        c.blur(12);
        c.noClip();
        c.roundRect(24, 22, 440, 210, 16, Color(0.05f, 0.07f, 0.12f, 0.45f));
        for (uint i = 0; i < names.length(); i++)
        {
            float y = 34 + float(i) * 36;
            if (i == row)
                c.roundRect(32, y - 4, 424, 34, 10, Color(1, 1, 1, 0.18f));
            c.text(font, names[i], 48, y);
            string state = depth ? (on[i] ? "on" : "off") : "not on this GPU";
            c.text(small, state, 450 - small.measure(state).x, y + 3, on[i] && depth ? Color(0.6f, 1, 0.7f) : Color(1, 1, 1, 0.6f));
        }
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Up, down: choose     Accept: on or off     Fire: throw paint (" + formatInt(int(thrown)) + ")", 40, 668);
    }
}
