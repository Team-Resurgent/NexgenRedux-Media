// Bezier curves that the player bends, a polygon cut into triangles as it changes shape, fifteen hundred wisps drawn
// in one batch, and fonts drawn beforehand in pixels: an image font, and a BMFont with its own colours, justified.

class CurvesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 20);
    Font@ title = Assets::font("global:font/chunky.fnt", 36);
    Font@ pixel = Assets::imageFont("global:font/pixel.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?:-+=\'()/%", 21);
    Texture@ wisp = Assets::texture("global:picture/sprite-wisp.png");
    Batch@ wisps;
    array<Vec2> drift;
    Curve@ curve;
    int picked = -1;
    int nearest = 0;
    Vec2 cursor(380, 120);
    Vec2 lastMouse;
    float t = 0;
    float time = 0;
    array<Vec2> blob;
    array<uint> triangles;

    void onEnter()
    {
        array<Vec2> points = { Vec2(80, 400), Vec2(140, 130), Vec2(380, 120), Vec2(330, 420), Vec2(580, 380) };
        @curve = Curve(points);

        // The wisps: one batch, each its own place, size, frame and colour.
        @wisps = Batch(wisp);
        for (uint i = 0; i < 1500; i++)
        {
            float size = random(10, 34);
            wisps.addFrame(4, 2, randomInt(0, 7), random(0, 1280), random(0, 720), size, size, fade(hsv(random(0.5f, 0.8f), 0.6f, 1), random(0.06f, 0.3f)));
            drift.insertLast(Vec2(random(-20, 20), random(-50, -15)));
        }
    }

    void update(float dt)
    {
        time += dt;
        cursor += Input::move * 500 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != lastMouse) cursor = mouse;
        lastMouse = mouse;
        cursor = Vec2(clamp(cursor.x, 40, 620), clamp(cursor.y, 90, 450));

        // The control point nearest the pointer is the one that moves, while fire or the mouse holds it.
        nearest = 0;
        for (uint i = 1; i < curve.count; i++)
            if (curve.point(i).distance(cursor) < curve.point(nearest).distance(cursor)) nearest = int(i);
        bool holding = Input::held("fire") || (Input::hasMouse && Input::mouseDown(0));
        if (holding && picked < 0 && curve.point(nearest).distance(cursor) < 40) picked = nearest;
        if (!holding) picked = -1;
        if (picked >= 0) curve.setPoint(picked, cursor);
        if (Input::pressed("accept") && curve.count < 8) curve.insert(nearest + 1, cursor);
        if (Input::pressed("alternate") && curve.count > 2) curve.remove(nearest);
        if (Input::pressed("cancel")) Screens::replace("curves");
        t += dt * 0.25f;
        if (t > 1) t -= 1;

        // A blob whose corners come and go with noise: concave, and cut into triangles again each frame.
        blob.resize(0);
        for (int i = 0; i < 18; i++)
        {
            float a = float(i) * 20;
            float r = 120 + noise(float(i) * 0.7f, time * 0.6f) * 70 + (i % 2 == 0 ? 0 : -40);
            blob.insertLast(Vec2(960, 270) + Vec2(r, 0).rotated(a + time * 10));
        }
        triangles = triangulate(blob);

        // The wisps rise, turn, flicker through their frames and come round again.
        for (uint i = 0; i < wisps.count; i++)
        {
            Vec2 p = wisps.place(i) + drift[i] * dt;
            if (p.y < -40) p = Vec2(random(0, 1280), 740);
            wisps.move(i, p.x, p.y, time * 40 + float(i));
            wisps.frame(i, 4, 2, uint(time * 10 + float(i)) % 8);
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.08f, 0.1f, 0.2f), Color(0.02f, 0.02f, 0.06f));
        c.blend = BlendAdd;
        c.batch(wisps);
        c.blend = BlendAlpha;

        c.filter = FilterNearest;
        c.text(title, "CURVES AND BATCHES", 40, 24, White);
        c.filter = FilterLinear;

        // The curve: its control points and the lines between them, the curve itself, part of it, and a dot along it.
        c.roundRect(30, 80, 600, 380, 12, Color(0, 0, 0, 0.35f));
        for (uint i = 0; i + 1 < curve.count; i++)
            c.line(curve.point(i).x, curve.point(i).y, curve.point(i + 1).x, curve.point(i + 1).y, 1.5f, fade(White, 0.3f));
        c.polyline(curve.points(64), 5, Color(0.4f, 0.85f, 1));
        c.polyline(curve.part(0.4f, 0.6f).points(16), 9, Color(1, 0.75f, 0.3f));
        for (uint i = 0; i < curve.count; i++)
        {
            Vec2 p = curve.point(i);
            c.circle(p.x, p.y, int(i) == picked ? 11 : 8, int(i) == nearest ? Yellow : White);
        }
        Vec2 dot = curve.at(t);
        Vec2 ahead = dot + curve.slope(t).normalized() * 34;
        c.line(dot.x, dot.y, ahead.x, ahead.y, 3, Color(1, 0.4f, 0.5f));
        c.circle(dot.x, dot.y, 7, Color(1, 0.4f, 0.5f));
        c.ring(cursor.x, cursor.y, 14, 2, Yellow);
        c.text(font, "Degree " + curve.degree + ", " + int(curve.length()) + " long", 46, 430, fade(White, 0.7f));

        // The blob, each of its triangles a colour of its own.
        c.roundRect(650, 80, 600, 380, 12, Color(0, 0, 0, 0.35f));
        for (uint i = 0; i < triangles.length(); i += 3)
        {
            Color k = hsv(0.08f + float(i) / float(triangles.length()) * 0.25f, 0.7f, 0.95f);
            c.triangle(blob[triangles[i]], blob[triangles[i + 1]], blob[triangles[i + 2]], k, k, k);
        }
        for (uint i = 0; i < triangles.length(); i += 3)
        {
            array<Vec2> edge = { blob[triangles[i]], blob[triangles[i + 1]], blob[triangles[i + 2]] };
            c.polygonLine(edge, 1, Color(0.2f, 0.1f, 0.1f, 0.5f));
        }
        c.polygonLine(blob, 3, White);
        c.text(font, (triangles.length() / 3) + " triangles" + (isConvex(blob) ? ", convex" : ", not convex"), 666, 430, fade(White, 0.7f));

        // Text in the two pixel fonts, justified to fill its width.
        c.roundRect(30, 480, 1220, 190, 12, Color(0, 0, 0, 0.35f));
        c.filter = FilterNearest;
        c.paragraph(pixel, "AN IMAGE FONT: ITS LETTERS SIDE BY SIDE IN ONE PICTURE. EACH LINE OF THIS IS SPREAD TO FILL ITS WIDTH, AS A BOOK'S ARE, BUT THE LAST.", 50, 500, 560, Color(0.7f, 0.95f, 0.8f), AlignJustify);
        c.rich(title, "A [u]BMFONT[/u] WITH ITS OWN COLOURS AND SHADOW, JUSTIFIED AS WELL, OVER THREE LINES OF IT.", 670, 500, 560, White, AlignJustify);
        c.filter = FilterLinear;
        c.text(font, "Fire: hold and bend    Accept: add a point    Alternate: take one away    Cancel: again", 640, 690, Yellow, AlignCenter);
        c.text(font, wisps.count + " wisps in one batch, " + int(App::fps + 0.5f) + " frames a second", 1240, 24, fade(White, 0.7f), AlignRight);
    }
}
