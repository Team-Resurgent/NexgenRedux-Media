// Two thousand trees. What can't be seen isn't drawn, and what is far away is drawn more simply.

class ForestScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Model@ pine = Assets::model("global:model/pine.glb");
    Model@ oak = Assets::model("global:model/oak.glb");
    Vec3 eye(0, 14, 60);
    float yaw = 0;
    float speed = 12;
    bool above = false;
    float height = 0;
    uint trees = 0;

    void onEnter()
    {
        Space::land(5, 256, 1.6f, 30, 0.4f);
        Space::landColors(Color(0.3f, 0.42f, 0.2f), Color(0.3f, 0.45f, 0.2f), Color(0.5f, 0.5f, 0.45f), Color(0.42f, 0.38f, 0.33f), -10, 24);
        trees = App::platform == "Original Xbox" ? 500 : 2000;
        for (uint i = 0; i < trees; i++)
        {
            float x = random(-190, 190), z = random(-190, 190);
            Entity@ e = Space::spawn(Vec3(x, Space::height(x, z), z));
            e.model(random(0, 1) < 0.65f ? pine : oak);
            e.sway = 0.02f;
            float size = random(0.8f, 1.7f);
            e.size = Vec3(size, size * random(0.9f, 1.2f), size);
            e.angles = Vec3(0, random(0, 360), 0);
        }
        Space::sky(Color(0.3f, 0.5f, 0.8f), Color(0.85f, 0.88f, 0.85f));
        Space::fog(Color(0.85f, 0.88f, 0.85f), 60, 190);
        Space::sun(Vec3(0.6f, 0.6f, 0.4f), Color(1, 0.93f, 0.78f));
        Space::farthest(200);
        Space::shadows(0.6f, 40);
    }

    void update(float dt)
    {
        yaw -= Input::move.x * 1.2f * dt + sin(App::time * 0.2f) * 0.1f * dt;
        speed += (12 - Input::move.y * 14 - speed) * clamp(dt * 2, 0, 1);
        if (Input::pressed("accept"))
            above = !above;
        eye += Vec3(-sin(yaw), 0, -cos(yaw)) * speed * dt;
        // Round again before the edge.
        if (eye.x > 160 || eye.x < -160 || eye.z > 160 || eye.z < -160)
            yaw += dt * 1.5f;
        eye = Vec3(clamp(eye.x, -185, 185), eye.y, clamp(eye.z, -185, 185));
        float wanted = Space::height(eye.x, eye.z) + (above ? 45.0f : 8.0f);
        eye.y += (wanted - eye.y) * clamp(dt * 1.5f, 0, 1);
        float least = Space::height(eye.x, eye.z) + 2.5f;
        eye.y = eye.y < least ? least : eye.y;
        Space::camera(eye, eye + Vec3(-sin(yaw), above ? -0.6f : -0.12f, -cos(yaw)), 62);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.roundRect(24, 22, 330, 172, 16, Color(0, 0, 0, 0.45f));
        c.text(font, formatInt(int(trees)) + " trees", 44, 32);
        c.text(font, formatInt(int(Space::drawn)) + " drawn, " + formatInt(int(Space::hidden)) + " out of sight", 44, 60);
        c.text(font, formatInt(int(Space::triangles)) + " triangles", 44, 88);
        for (uint i = 0; i < 3; i++)
        {
            float part = Space::drawn > 0 ? float(Space::drawnAt(i)) / float(Space::drawn) : 0.0f;
            c.text(font, "level " + formatInt(int(i)), 44, 118 + float(i) * 23);
            c.roundRect(130, 126 + float(i) * 23, 4 + 200 * part, 12, 4, hsv(0.33f - float(i) * 0.14f, 0.7f, 0.95f));
        }
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Left, right: turn     Up, down: faster, slower     Accept: " + (above ? "fly low" : "fly high"), 40, 668);
    }
}
