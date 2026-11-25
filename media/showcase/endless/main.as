// Land without end. Regions of it are made in the background as the camera comes near, and go when it
// has left; what stands in them comes and goes with them. One place is read from a file.

class EndlessScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Model@ pine = Assets::model("global:model/pine.glb");
    Model@ oak = Assets::model("global:model/oak.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    Vec3 eye(0, 20, 40);
    float yaw = 0;
    float bank = 0;
    float speed = 18;
    bool map = true;
    float flown = 0;
    array<int> xs;          // of the regions that are here
    array<int> zs;
    array<float> ages;
    uint arrivals = 0, departures = 0;
    float most = 0;

    void onEnter()
    {
        Space::endlessLand(77, 2, 40, 0.5f, App::platform == "Original Xbox" ? 3 : 5);
        Space::landColors(Color(0.78f, 0.72f, 0.52f), Color(0.35f, 0.5f, 0.23f), Color(0.9f, 0.92f, 0.95f), Color(0.45f, 0.41f, 0.37f), 0.5f, 27);
        Space::water(0, Color(0.14f, 0.38f, 0.52f, 0.85f));
        Space::flatten(0, -30, 26, 4);
        Space::sky(Color(0.25f, 0.48f, 0.85f), Color(0.78f, 0.86f, 0.92f));
        Space::fog(Color(0.78f, 0.86f, 0.92f), 120, 320);
        Space::farthest(400);
        Space::sun(Vec3(0.6f, 0.6f, 0.4f), Color(1, 0.93f, 0.8f));
        Space::ambient(Color(0.4f, 0.46f, 0.55f), Color(0.24f, 0.23f, 0.2f));
        Space::shadows(0.6f, 50);
    }

    // The same things every time a region is made, from where it is.
    float chance(int x, int z, int n)
    {
        float v = sin(float(x) * 12.9898f + float(z) * 78.233f + float(n) * 37.719f) * 43758.5453f;
        return v - floor(v);
    }

    void fill(int x, int z)
    {
        float size = Space::regionSize;
        for (int n = 0; n < 16; n++)
        {
            float px = (float(x) + chance(x, z, n)) * size, pz = (float(z) + chance(x, z, n + 100)) * size;
            float y = Space::height(px, pz);
            if (y < 1 || y > 26 || Space::normal(px, pz).y < 0.75f || (abs(px) < 22 && abs(pz + 30) < 22))
                continue;
            Entity@ e = Space::spawn(Vec3(px, y, pz));
            e.model(n % 5 == 0 ? rock : y > 13 ? pine : oak);
            e.sway = n % 5 == 0 ? 0.0f : 0.02f;
            float big = 0.9f + chance(x, z, n + 200) * 0.9f;
            e.size = Vec3(big, big, big);
            e.angles = Vec3(0, chance(x, z, n + 300) * 360, 0);
            e.streamed = true;
        }
        // A village, from a file, in its own region.
        if (x == 0 && z == -1)
            Space::load("asset:village.json", Vec3(0, 0, -30), true);
    }

    void update(float dt)
    {
        int x, z;
        bool arrived;
        while (Space::nextRegion(x, z, arrived))
        {
            if (arrived)
            {
                arrivals++;
                xs.insertLast(x);
                zs.insertLast(z);
                ages.insertLast(0);
                fill(x, z);
                continue;
            }
            departures++;
            for (uint i = 0; i < xs.length(); i++)
                if (xs[i] == x && zs[i] == z)
                {
                    xs.removeAt(i);
                    zs.removeAt(i);
                    ages.removeAt(i);
                    break;
                }
        }
        for (uint i = 0; i < ages.length(); i++)
            ages[i] += dt;

        float stick = Input::move.x + sin(App::time * 0.23f) * 0.2f;
        bank += (stick - bank) * clamp(dt * 3, 0, 1);
        yaw -= bank * 0.9f * dt;
        speed += (18 - Input::move.y * 22 - speed) * clamp(dt * 2, 0, 1);
        Vec3 ahead(-sin(yaw), 0, -cos(yaw));
        eye += ahead * speed * dt;
        flown += abs(speed) * dt;
        // Over what is coming, not only what is here.
        float highest = 2;
        for (int i = 0; i < 5; i++)
        {
            float h = Space::height(eye.x + ahead.x * float(i) * 7, eye.z + ahead.z * float(i) * 7);
            highest = h > highest ? h : highest;
        }
        eye.y += (highest + 9 - eye.y) * clamp(dt * 1.6f, 0, 1);
        float least = Space::height(eye.x, eye.z) + 2;
        eye.y = eye.y < least ? least : eye.y;
        if (Input::pressed("accept"))
            map = !map;
        Space::camera(eye, eye + ahead + Vec3(0, -0.16f, 0), 64);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.roundRect(24, 22, 300, 118, 16, Color(0, 0, 0, 0.45f));
        c.text(font, formatInt(int(flown)) + " metres flown", 44, 32);
        c.text(font, formatInt(int(Space::regions)) + " regions, " + formatInt(int(Space::regionsWaiting)) + " to come", 44, 60);
        c.text(font, formatInt(int(Scene::count)) + " things, " + formatInt(int(Space::drawn)) + " drawn", 44, 88);
        if (map)
        {
            float mx = c.width - 150, my = 150, scale = 20 / Space::regionSize;
            c.circle(mx, my, 128, Color(0, 0, 0, 0.45f));
            for (uint i = 0; i < xs.length(); i++)
            {
                float fx = (float(xs[i]) * Space::regionSize - eye.x) * scale, fz = (float(zs[i]) * Space::regionSize - eye.z) * scale;
                float fresh = clamp(1 - ages[i], 0, 1);
                if (fx * fx + fz * fz < 118 * 118)
                    c.rect(mx + fx + 1, my + fz + 1, 18, 18, lerp(Color(0.35f, 0.6f, 0.4f, 0.7f), Color(1, 0.9f, 0.4f), fresh));
            }
            float s = sin(yaw), k = cos(yaw);
            c.triangle(Vec2(mx - s * 14, my - k * 14), Vec2(mx - k * 8 + s * 8, my + s * 8 + k * 8), Vec2(mx + k * 8 + s * 8, my - s * 8 + k * 8), White, White, White);
        }
        c.roundRect(20, 660, c.width - 40, 42, 12, Color(0, 0, 0, 0.45f));
        c.text(font, "Left, right: turn     Up, down: faster, slower     Accept: map", 40, 668);
    }
}
