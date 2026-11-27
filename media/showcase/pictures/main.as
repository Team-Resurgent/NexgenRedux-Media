// Pictures to draw into: the same scene seen from above, drawn into a picture each frame, then shown as a map in the
// corner and on cards that turn, as any other picture would be.

class PicturesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 34);
    Model@ robot = Assets::model("global:model/robot.glb");
    Texture@ map = Assets::picture(320, 320);
    Entity@ dancer;
    array<Entity@> walkers;
    float t = 0;

    void onEnter()
    {
        Space::ground(0);
        Space::sky(Color(0.2f, 0.32f, 0.55f), Color(0.62f, 0.7f, 0.8f));
        Space::sun(Vec3(0.4f, 0.85f, 0.5f), Color(0.95f, 0.92f, 0.86f));
        Space::ambient(Color(0.4f, 0.45f, 0.55f), Color(0.25f, 0.22f, 0.2f));
        Space::shadows(0.6f, 14);
        Entity@ floor = Space::spawn(Vec3(0, -0.05f, 0));
        floor.shape(SolidCylinder, Color(0.32f, 0.4f, 0.36f));
        floor.size = Vec3(14, 0.1f, 14);
        for (int i = 0; i < 8; i++)
        {
            float a = float(i) * 0.785f;
            Entity@ post = Space::spawn(Vec3(sin(a) * 6, 0.6f, cos(a) * 6));
            post.shape(SolidBox, hsv(float(i) / 8, 0.6f, 0.9f));
            post.size = Vec3(0.5f, 1.2f, 0.5f);
        }
        @dancer = Space::spawn(Vec3(0, 0, 0));
        dancer.model(robot);
        dancer.animate("dance");
        for (int i = 0; i < 3; i++)
        {
            Entity@ w = Space::spawn(Vec3(4, 0, 0));
            w.model(robot);
            w.animate("walk");
            w.size = Vec3(0.7f, 0.7f, 0.7f);
            walkers.insertLast(w);
        }
    }

    void update(float dt)
    {
        t += dt;
        for (uint i = 0; i < walkers.length(); i++)
        {
            float a = t * 0.5f + float(i) * 2.09f;
            walkers[i].place = Vec3(sin(a) * 4, 0, cos(a) * 4);
            walkers[i].angles = Vec3(0, a * 57.3f + 90, 0);
        }
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);

        // First the picture: the same scene, from straight above, into its own pixels.
        if (map !is null && c.beginPicture(map, Color(0.05f, 0.06f, 0.1f, 1)))
        {
            Space::camera(Vec3(0.01f, 18, 0), Vec3(0, 0, 0), 50);
            Space::draw(c);
            c.ring(160, 160, 150, 4, Color(1, 1, 1, 0.5f));
            c.text(font, "from above", 160, 10, White, AlignCenter);
            c.endPicture();
        }

        // Then the screen, from the side, with the picture on it.
        float a = t * 0.15f;
        Space::camera(Vec3(sin(a) * 11, 4.5f, cos(a) * 11), Vec3(0, 1, 0), 50);
        Space::draw(c);
        if (map is null)
        {
            c.text(big, "No pictures to draw into here", 40, 40, Red);
            return;
        }
        c.rect(c.width - 356, 16, 340, 340, Color(0, 0, 0, 0.5f));
        c.image(map, c.width - 346, 26, 320, 320);
        for (int i = 0; i < 3; i++)
        {
            c.push();
            c.translate(140 + float(i) * 170, 600);
            c.rotate(sin(t * 1.3f + float(i)) * 12);
            float s = 0.9f + 0.1f * sin(t * 2 + float(i));
            c.scale(s, s);
            c.image(map, -70, -70, 140, 140, hsv(float(i) * 0.3f, 0.25f, 1));
            c.pop();
        }
        c.text(big, "Pictures drawn into", 40, 30);
        c.text(font, "One picture, drawn into each frame", 40, 74, Color(0.85f, 0.9f, 1));
    }
}
