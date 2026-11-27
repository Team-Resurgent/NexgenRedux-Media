// Animation beyond one at a time: idle, walk and run mixed by speed, a stride that carries the robot along,
// a wave over the top half while walking on, heads that follow a buzzing drone and hands that reach for it. The drone
// is heard higher coming and lower going: Doppler.

class MovesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Model@ robot = Assets::model("global:model/robot.glb");
    Entity@ mixer;
    Entity@ strider;
    Entity@ waver;
    Entity@ ball;
    float speed = 0;
    float wanted = 1.5f;
    float mixerAround = 0;
    float waverAround = 0;
    bool waving = true;
    bool looking = true;
    bool reaching = false;
    array<string> names = { "idle", "walk", "run" };
    array<float> points = { 0, 1.5f, 4 };

    void onEnter()
    {
        Mesh@ floor = Mesh();
        for (int z = -8; z < 8; z++)
            for (int x = -12; x < 12; x++)
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

        @mixer = robotAt(Vec3(-7, 0, 0));
        @strider = robotAt(Vec3(0, 0, -5));
        // Where the stride carries its hips, the whole robot goes, so its feet don't slide.
        strider.rootMotion = true;
        @waver = robotAt(Vec3(7, 0, 0));

        @ball = Space::spawn(Vec3(0, 1.5f, 3));
        ball.shape(SolidSphere, Color(1, 0.62f, 0.25f));
        ball.size = Vec3(0.3f, 0.3f, 0.3f);
        ball.glowing = 1;
        ball.shadow = false;
        ball.light(Color(1, 0.6f, 0.3f), 5);
        // Heard from where it is, and bent by how fast it comes and goes: a little more than life, to be plain.
        ball.sound(Assets::sound("global:sound/engine.wav"), 0.6f, 30, true);
        Space::doppler = 2.5f;
    }

    Entity@ robotAt(const Vec3 &in at)
    {
        Entity@ e = Space::spawn(at);
        e.model(robot);
        return e;
    }

    void update(float dt)
    {
        // Speed is the point along idle, walk and run.
        if (Input::move.y < -0.3f || Input::move.y > 0.3f)
            wanted = clamp(wanted - Input::move.y * 2.5f * dt, 0, 4);
        speed += (wanted - speed) * clamp(dt * 3, 0, 1);
        mixer.animateBlend(names, points);
        mixer.blendBy = speed;
        mixerAround += speed / 3.5f * dt;
        mixer.place = Vec3(-7 + sin(mixerAround) * 3.5f, 0, cos(mixerAround) * 3.5f);
        mixer.face(Vec3(cos(mixerAround), 0, -sin(mixerAround)));

        // The stride moves it; at either end it turns round.
        strider.animate("stride");
        if (strider.place.z > 4.5f)
            strider.face(Vec3(0, 0, -1));
        else if (strider.place.z < -4.5f)
            strider.face(Vec3(0, 0, 1));

        if (Input::pressed("accept"))
            waving = !waving;
        waver.animate("walk");
        if (waving)
            waver.animateLayer("wave", "chest");
        else
            waver.stopLayer(0.4f);
        waverAround += 1.4f / 3 * dt;
        waver.place = Vec3(7 + sin(waverAround) * 3, 0, cos(waverAround) * 3);
        waver.face(Vec3(cos(waverAround), 0, -sin(waverAround)));

        // The ball wanders; the heads follow it, or the stick moves it.
        if (Input::pressed("alternate"))
            looking = !looking;
        Vec3 at = Vec3(sin(App::time * 1.1f) * 10, 1.4f + sin(App::time * 1.3f) * 0.8f, 3 + cos(App::time * 0.55f) * 4);
        if (abs(Input::move.x) > 0.3f)
            at.x = ball.place.x + Input::move.x * 6 * dt;
        ball.place = at;
        if (Input::pressed("fire"))
            reaching = !reaching;
        array<Entity@> heads = { mixer, strider, waver };
        for (uint i = 0; i < heads.length(); i++)
        {
            if (looking)
                heads[i].lookAt("head", ball.place);
            else
                heads[i].lookAway();
            // The right hand toward it, as far as the arm goes, over whatever it is doing.
            heads[i].reach("hand.r", ball.place, reaching ? 1.0f : 0.0f);
        }
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        // Further back on a narrower screen, so all three are seen.
        float narrower = max(0.0f, 16.0f / 9 - c.width / c.height);
        Space::camera(Vec3(0, 4.2f + narrower * 4, 10.5f + narrower * 11), Vec3(0, 1.1f, 0), 52);
        Space::draw(c);
        // How much of each animation the mixing robot is.
        float walk = speed < 1.5f ? speed / 1.5f : 1 - (speed - 1.5f) / 2.5f;
        float idle = speed < 1.5f ? 1 - walk : 0;
        float run = speed > 1.5f ? 1 - walk : 0;
        c.roundRect(24, 22, 360, 132, 16, Color(0, 0, 0, 0.45f));
        c.text(font, "Speed " + formatFloat(speed, "", 0, 1) + " metres a second", 44, 32);
        array<string> labels = { "idle", "walk", "run" };
        array<float> parts = { idle, walk, run };
        for (uint i = 0; i < 3; i++)
        {
            c.text(font, labels[i], 44, 64 + float(i) * 27);
            c.roundRect(110, 72 + float(i) * 27, 4 + 240 * parts[i], 12, 4, hsv(0.55f - float(i) * 0.2f, 0.7f, 0.95f));
        }
        Vec2 p;
        if (Space::toScreen(mixer.worldPlace + Vec3(0, 2.4f, 0), p))
            label(c, "mixed by speed", p);
        if (Space::toScreen(strider.worldPlace + Vec3(0, 2.4f, 0), p))
            label(c, "root motion", p);
        if (Space::toScreen(waver.worldPlace + Vec3(0, 2.4f, 0), p))
            label(c, waving ? "waving over walking" : "walking", p);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Up, down: speed   Accept: " + (waving ? "stop waving" : "wave") + "   Alternate: " + (looking ? "stop looking" : "look") + "   Fire: " + (reaching ? "stop reaching" : "reach for it"), 40, 668);
    }

    void label(Canvas@ c, const string &in text, const Vec2 &in at)
    {
        float w = font.measure(text).x;
        c.roundRect(at.x - w / 2 - 10, at.y - 30, w + 20, 32, 10, Color(0, 0, 0, 0.45f));
        c.text(font, text, at.x - w / 2, at.y - 27);
    }
}
