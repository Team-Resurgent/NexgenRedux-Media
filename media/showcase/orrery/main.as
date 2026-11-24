// Every planet is a child of an arm that turns, and every moon of a planet. Nothing here works out
// where anything is: turning the parent is enough.

class OrreryScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    array<Entity@> arms;
    array<float> speeds;
    Entity@ sun;
    Entity@ crane;
    array<Entity@> joints;
    float speed = 1;

    void onEnter()
    {
        @sun = Scene::spawn(Vec2(430, 360));
        sun.disc(46, Color(1, 0.85f, 0.4f));
        sun.layer = 5;
        planet(sun, 90, 9, 1.6f, Color(0.8f, 0.7f, 0.6f), 0);
        planet(sun, 140, 15, 1.1f, Color(0.95f, 0.7f, 0.4f), 0);
        planet(sun, 205, 17, 0.8f, Color(0.4f, 0.65f, 1), 1);
        planet(sun, 290, 28, 0.45f, Color(0.9f, 0.6f, 0.45f), 4);

        // A crane: each arm is a child of the one before.
        Entity@ base = Scene::spawn(Vec2(1010, 640));
        base.rect(140, 50, Color(0.35f, 0.4f, 0.5f));
        Entity@ from = base;
        for (int i = 0; i < 4; i++)
        {
            Entity@ joint = Scene::spawn(i == 0 ? Vec2(0, -25) : Vec2(0, -130));
            joint.disc(16, Color(0.9f, 0.75f, 0.2f));
            joint.layer = 3;
            joint.attach(from);
            Entity@ arm = Scene::spawn(Vec2(0, -65));
            arm.rect(22 - float(i) * 3, 120, hsv(0.13f, 0.7f, 0.95f - float(i) * 0.1f));
            arm.layer = 2;
            arm.attach(joint);
            joints.insertLast(joint);
            @from = joint;
        }
        Entity@ hook = Scene::spawn(Vec2(0, -140));
        hook.disc(13, Red);
        hook.layer = 4;
        hook.attach(from);
    }

    void planet(Entity@ around, float distance, float size, float turn, const Color &in color, int moons)
    {
        Entity@ arm = Scene::spawn(Vec2());
        arm.attach(around);
        arm.rotation = random(0, 360);
        arms.insertLast(arm);
        speeds.insertLast(turn * 60);
        Entity@ e = Scene::spawn(Vec2(distance, 0));
        e.disc(size, color);
        e.layer = 4;
        e.attach(arm);
        for (int i = 0; i < moons; i++)
            planet(e, size + 10 + float(i) * 8, 4, 2.5f - float(i) * 0.4f, Color(0.8f, 0.82f, 0.88f), 0);
    }

    void update(float dt)
    {
        speed = clamp(speed + Input::move().x * dt * 2, -3, 4);
        for (uint i = 0; i < arms.length(); i++) arms[i].rotation += speeds[i] * speed * dt;
        float t = App::time();
        for (uint i = 0; i < joints.length(); i++) joints[i].rotation = sin(t * (0.5f + float(i) * 0.3f) + float(i)) * 38;
        sun.scale = Vec2(1 + sin(t * 2) * 0.04f, 1 + sin(t * 2) * 0.04f);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.03f, 0.04f, 0.1f), Color(0.06f, 0.05f, 0.12f));
        c.setBlend(BlendAdd);
        c.glow(430, 360, 240, Color(1, 0.7f, 0.3f, 0.35f));
        c.setBlend(BlendAlpha);
        array<float> rings = { 90, 140, 205, 290 };
        for (uint i = 0; i < rings.length(); i++) c.ring(430, 360, rings[i], 1.5f, Color(1, 1, 1, 0.12f));
        Scene::draw(c);
        c.text(font, formatInt(Scene::count()) + " entities", 30, 24, Gray);
        c.text(font, "Left and right: speed", 1250, 684, Yellow, AlignRight);
    }
}
