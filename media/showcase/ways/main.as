// Ways: a ship that follows a looping Path at a steady speed, its points drifting with noise; clouds of noise behind it;
// and a seeker that finds its way round a maze with Scene::path, to wherever it is sent.

class WaysScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ small = Assets::font("global:freesans.sfn", 18);
    float t = 0;

    // The loop the ship flies, and where its points are when still.
    Path@ track = Path();
    array<Vec2> home = { Vec2(120, 220), Vec2(330, 130), Vec2(540, 230), Vec2(500, 470), Vec2(300, 600), Vec2(110, 470) };
    float along = 0;

    // The maze is a map in the scene, drawn where its corner is here on the screen.
    Vec2 corner(680, 120);
    Vec2 seeker(60, 60);
    Vec2 target;
    array<Vec2> way;
    uint next = 0;
    float sendAgain = 0;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        for (uint i = 0; i < home.length(); i++)
            track.add(home[i]);
        track.loop = true;
        send();
    }

    // Somewhere open in the maze, and the way there.
    void send()
    {
        for (int tries = 0; tries < 50; tries++)
        {
            Vec2 to(float(randomInt(0, 13)) * 40 + 20, float(randomInt(0, 11)) * 40 + 20);
            if (!Scene::blocked(to) && (to - seeker).length() > 160 && Scene::path(seeker, to, way))
            {
                target = to;
                next = 0;
                sendAgain = 5;
                return;
            }
        }
    }

    void update(float dt)
    {
        t += dt;

        // The points wander a little, each with its own noise: the curve through them stays smooth.
        for (uint i = 0; i < home.length(); i++)
        {
            float k = float(i) * 3.7f;
            track.setPoint(i, Vec3(home[i].x + noise(t * 0.3f, k) * 50, home[i].y + noise(t * 0.3f, k + 50) * 50, 0));
        }
        along += 260 * dt;    // pixels a second, however far apart the points are

        // Along the way, corner by corner.
        float step = 170 * dt;
        while (next < way.length() && step > 0)
        {
            Vec2 to = way[next] - seeker;
            float far = to.length();
            if (far <= step)
            {
                seeker = way[next];
                next++;
                step -= far;
            }
            else
            {
                seeker += to * (step / far);
                step = 0;
            }
        }
        sendAgain -= dt;
        if (Input::pressed("accept") || (next >= way.length() && sendAgain < 3.5f) || sendAgain < 0)
            send();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.05f, 0.07f, 0.12f));

        // Clouds: layers of noise, moving slowly through the third dimension.
        for (int y = 0; y < 23; y++)
            for (int x = 0; x < 40; x++)
            {
                float n = fractalNoise(float(x) * 0.09f + t * 0.05f, float(y) * 0.09f, t * 0.08f, 4, 0.55f);
                if (n > 0)
                    c.rect(float(x) * 32, float(y) * 32, 32, 32, Color(0.45f, 0.6f, 0.95f, n * 0.45f));
            }

        // The path, the points it passes through, and the ship on it.
        Vec2 was = track.at2(0);
        for (int i = 1; i <= 160; i++)
        {
            Vec2 now = track.at2(track.length * float(i) / 160);
            c.line(was.x, was.y, now.x, now.y, 3, Color(0.4f, 0.75f, 1, 0.7f));
            was = now;
        }
        for (uint i = 0; i < track.count; i++)
            c.circle(track.point(i).x, track.point(i).y, 6, Yellow);
        Vec2 at = track.at2(along), ahead = track.direction2(along);
        Vec2 side(-ahead.y, ahead.x);
        c.triangle(at + ahead * 22, at - ahead * 12 + side * 13, at - ahead * 12 - side * 13, Orange, Color(1, 0.4f, 0.2f), Color(1, 0.4f, 0.2f));
        c.text(font, "A Path through six points, which drift with noise", 40, 650, White);

        // The maze, the way round it, and the seeker going along it.
        Scene::camera(Vec2(640, 360) - corner, 1);
        Scene::draw(c);
        Vec2 from = seeker;
        for (uint i = next; i < way.length(); i++)
        {
            c.line(corner.x + from.x, corner.y + from.y, corner.x + way[i].x, corner.y + way[i].y, 3, Color(0.5f, 1, 0.6f, 0.8f));
            from = way[i];
        }
        c.ring(corner.x + target.x, corner.y + target.y, 12 + sin(t * 6) * 2, 3, Green);
        c.circle(corner.x + seeker.x, corner.y + seeker.y, 12, Color(1, 0.85f, 0.3f));
        c.text(font, "Scene::path finds the way round", 680, 620, White);
        c.text(small, Input::buttons("accept") + " or " + Input::keys("accept") + ": somewhere else", 680, 652, Yellow);
    }
}
