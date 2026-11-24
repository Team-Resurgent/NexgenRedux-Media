// Lights that move: sixteen at once, the nearest four on each thing.

class Wisp : Behaviour
{
    float at = 0;
    float reach = 0;
    Color color;

    Wisp(float at_, float reach_, const Color &in color_)
    {
        at = at_;
        reach = reach_;
        color = color_;
    }

    void update(float dt)
    {
        at += dt * (0.5f + 2 / reach);
        entity.place = Vec3(sin(at) * reach, 0.8f + sin(at * 2.3f) * 0.5f, cos(at * 1.1f) * reach);
        float flicker = 2 + sin(at * 11) * 0.2f;
        entity.light(Color(color.r * flicker, color.g * flicker, color.b * flicker), 6);
    }
}

class LightsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Model@ crystal = Assets::model("global:model/crystal.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    Model@ mushroom = Assets::model("global:model/mushroom.glb");
    float around = 0;
    bool moon = false;

    void onEnter()
    {
        Mesh@ floor = Mesh();
        floor.plane(44, 44, 40, Color(0.5f, 0.5f, 0.55f));
        Space::spawn(Vec3(0, 0, 0)).mesh(floor);
        for (int i = 0; i < 40; i++)
        {
            float a = float(i) * 2.4f, r = 1.2f + sqrt(float(i)) * 1.5f;
            Vec3 p(sin(a) * r, 0, cos(a) * r);
            Entity@ e = Space::spawn(p);
            e.angles = Vec3(0, float(i * 77), 0);
            if (i % 3 == 0)
            {
                e.shape(SolidCylinder, Color(0.75f, 0.73f, 0.7f));
                float tall = 1.5f + float(i % 5) * 0.5f;
                e.place = p + Vec3(0, tall * 0.5f, 0);
                e.size = Vec3(0.7f, tall, 0.7f);
            }
            else
            {
                e.model(i % 3 == 1 ? rock : mushroom);
                float size = 0.5f + float(i % 4) * 0.2f;
                e.size = Vec3(size, size, size);
            }
            e.shine = 0.4f;
        }
        for (int i = 0; i < 16; i++)
        {
            Color color = hsv(float(i) / 16.0f, 0.7f, 1);
            Entity@ e = Space::spawn(Vec3(0, 1, 0));
            e.glow(1, color);
            e.add(Wisp(float(i) * 1.7f, 1.5f + float(i) * 0.5f, color));
        }
        Space::sky(Color(0.01f, 0.01f, 0.04f), Color(0.05f, 0.05f, 0.12f));
        Space::fog(Color(0.04f, 0.04f, 0.1f), 12, 30);
    }

    void update(float dt)
    {
        around += (Input::move().x * 1.5f + 0.1f) * dt;
        if (Input::pressed("accept"))
            moon = !moon;
        Space::sun(Vec3(0.5f, 0.7f, -0.5f), moon ? Color(0.25f, 0.28f, 0.4f) : Color(0, 0, 0));
        Space::ambient(Color(0.04f, 0.04f, 0.07f), Color(0.02f, 0.02f, 0.03f));
        Space::shadows(moon ? 0.7f : 0.0f, 16);
        Space::camera(Vec3(sin(around) * 9, 4.2f, cos(around) * 9), Vec3(0, 0.7f, 0), 55);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Left, right: look around     Accept: " + (moon ? "hide the moon" : "bring out the moon"), 40, 668);
    }
}
