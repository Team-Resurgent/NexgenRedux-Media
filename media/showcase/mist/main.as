// Mist that can be walked into: a bank of it lying in the valley, a column of smoke and the glow of a fire. Each is a
// box of billowing 3D noise, drifting with the wind and soft at its edges; the camera goes down into the bank and out.

class MistScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Model@ pine = Assets::model("global:model/pine.glb");
    Model@ oak = Assets::model("global:model/oak.glb");
    Model@ campfire = Assets::model("global:model/campfire.glb");
    float t = 0;
    Vec3 fire;

    void onEnter()
    {
        Space::land(4, 128, 2, 26, 0.45f);
        Space::water(-1, Color(0.12f, 0.3f, 0.38f, 0.85f));
        Space::waterStyle("calm");
        Space::landColors(Color(0.42f, 0.4f, 0.3f), Color(0.3f, 0.42f, 0.24f), Color(0.5f, 0.52f, 0.48f), Color(0.4f, 0.38f, 0.34f), 2, 16);
        // Dawn: low sun, a cool sky, and the haze it makes.
        Space::sky(Color(0.32f, 0.42f, 0.62f), Color(0.94f, 0.78f, 0.62f));
        Space::fog(Color(0.86f, 0.78f, 0.7f), 60, 230);
        Space::sun(Vec3(0.8f, 0.22f, 0.3f), Color(1, 0.78f, 0.55f));
        Space::ambient(Color(0.42f, 0.46f, 0.56f), Color(0.22f, 0.2f, 0.18f));
        Space::farthest(240);
        Space::shadows(0.55f, 40);
        Space::impostors = 70;
        bool small = App::platform == "Original Xbox";
        for (int i = 0; i < (small ? 260 : 700); i++)
        {
            float x = random(-120, 120), z = random(-120, 120), y = Space::height(x, z);
            if (y < 0.5f || Space::normal(x, z).y < 0.8f)
                continue;
            Entity@ e = Space::spawn(Vec3(x, y, z));
            e.model(random() < 0.6f ? pine : oak);
            float s = random(0.8f, 1.5f);
            e.size = Vec3(s, s, s);
            e.angles = Vec3(0, random(0, 360), 0);
            e.sway = 0.02f;
            e.impostor = true;
        }
        // A bank lying along the valley floor and over the water.
        Space::mist(Vec3(0, 3, 0), Vec3(240, 9, 240), Color(0.94f, 0.9f, 0.86f, 0.75f), 1.2f, 1, 9);
        // A fire on the shore, its glow and its smoke.
        fire = Vec3(18, 0, 30);
        fire.y = Space::height(fire.x, fire.z);
        Entity@ camp = Space::spawn(fire);
        camp.model(campfire);
        camp.light(Color(1.6f, 0.8f, 0.3f), 10);
        Space::mist(fire + Vec3(0, 0.9f, 0), Vec3(1.6f, 1.8f, 1.6f), Color(1, 0.55f, 0.15f, 0.9f), 1.5f, 6, 0.9f);
        Space::mist(fire + Vec3(0, 7, 0), Vec3(4, 12, 4), Color(0.45f, 0.45f, 0.47f, 0.7f), 1, 3, 2.5f);
    }

    void update(float dt)
    {
        t += dt;
        // Down from above the bank, into it, along the shore past the fire, and out over the water.
        float a = t * 0.06f + 0.4f;
        float high = 22 - 18 * clamp(sin(t * 0.22f) * 0.5f + 0.5f, 0, 1);
        Vec3 eye(sin(a) * 48, 0, cos(a) * 48);
        eye.y = max(Space::height(eye.x, eye.z), -1) + high;
        Vec3 look = fire + Vec3(0, 3, 0);
        Space::camera(eye, look, 62);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.35f, 0.8f);
        float a = clamp(5 - t, 0, 1);
        if (a > 0)
        {
            c.alpha = a;
            c.text(font, "Mist, smoke and fire: boxes of drifting 3D noise", 60, 650, White);
            c.alpha = 1;
        }
    }
}
