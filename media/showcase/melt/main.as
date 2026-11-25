// Shapes described by how far away they are, drawn by marching along rays. Where the GPU can't, the
// engine makes triangles of them instead.

class MeltScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    float around = 0;
    int kind = 0;
    array<string> kinds = { "Melting", "Cut and kept", "Again and again" };

    void onEnter()
    {
        Space::sky(Color(0.2f, 0.35f, 0.65f), Color(0.85f, 0.75f, 0.7f));
        Space::sun(Vec3(0.6f, 0.7f, 0.4f), Color(1, 0.92f, 0.8f));
        Space::ambient(Color(0.35f, 0.4f, 0.5f), Color(0.25f, 0.22f, 0.22f));
        Space::fog(Color(0.8f, 0.75f, 0.75f), 22, 50);
        // A mesh among them, to show that they mix.
        Entity@ ball = Space::spawn(Vec3(0, 1, 0));
        ball.shape(SolidTorus, Color(1, 0.8f, 0.2f));
        ball.shine = 1;
        ball.size = Vec3(5.2f, 1.2f, 5.2f);
    }

    void update(float dt)
    {
        around += (Input::move.x * 1.5f + 0.12f) * dt;
        if (Input::pressed("accept"))
            kind = (kind + 1) % 3;
        float t = App::time;
        Space::clearField();
        Space::field(FieldPlane, Vec3(0, -0.6f, 0), Vec3(1, 1, 1), Color(0.42f, 0.4f, 0.45f));
        if (kind == 0)
        {
            for (int i = 0; i < 9; i++)
            {
                float a = t * (0.4f + float(i) * 0.07f) + float(i) * 2.1f;
                Space::field(FieldSphere, Vec3(sin(a) * 1.5f, 1.2f + sin(a * 1.3f + float(i)) * 1.2f, cos(a * 0.9f) * 1.5f), Vec3(0.45f + sin(float(i)) * 0.15f, 0, 0), hsv(float(i) / 9.0f, 0.65f, 0.95f), 0.5f);
            }
            Space::fieldLook(0.8f, 0.25f);
        }
        else if (kind == 1)
        {
            Space::field(FieldBox, Vec3(0, 1.2f, 0), Vec3(1.1f, 1.1f, 1.1f), Color(0.3f, 0.6f, 0.95f), 0, JoinAdd, t * 20);
            Space::field(FieldSphere, Vec3(0, 1.2f, 0), Vec3(1.42f, 0, 0), Color(0.95f, 0.95f, 1), 0.05f, JoinCut);
            Space::field(FieldSphere, Vec3(0, 1.2f + sin(t) * 0.2f, 0), Vec3(0.75f, 0, 0), Color(1, 0.45f, 0.3f), 0.1f);
            for (int i = 0; i < 6; i++)
            {
                float a = float(i) * 1.047f + t * 0.5f;
                Space::field(FieldCylinder, Vec3(sin(a) * 2.7f, 0.5f, cos(a) * 2.7f), Vec3(0.35f, 1, 0), hsv(0.3f + float(i) * 0.05f, 0.5f, 0.9f), 0.3f);
                Space::field(FieldSphere, Vec3(sin(a) * 2.7f, 1.6f + sin(t * 2 + float(i)) * 0.2f, cos(a) * 2.7f), Vec3(0.4f, 0, 0), Color(0.98f, 0.95f, 0.9f), 0.35f);
            }
            Space::fieldLook(0.6f, 0.15f);
        }
        else
        {
            Space::field(FieldCylinder, Vec3(0, 0.8f, 0), Vec3(0.5f, 1.6f, 0), Color(0.8f, 0.76f, 0.7f), 0.5f);
            Space::field(FieldTorus, Vec3(0, 1.4f + sin(t * 0.8f) * 0.7f, 0), Vec3(0.9f, 0.2f, 0), Color(0.95f, 0.5f, 0.25f), 0.25f);
            Space::field(FieldSphere, Vec3(0, 3, 0), Vec3(0.7f, 0, 0), Color(0.5f, 0.8f, 0.95f), 0.4f);
            Space::fieldLook(0.5f, 0.2f, 4.5f);
        }
        Space::camera(Vec3(sin(around) * 6.5f, 2.6f + sin(around * 0.7f) * 0.6f, cos(around) * 6.5f), Vec3(0, 1.1f, 0), 55);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.3f, 0.8f);
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Left, right: look around     Accept: next     " + kinds[kind], 40, 668);
    }
}
