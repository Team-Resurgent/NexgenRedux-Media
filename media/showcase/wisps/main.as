// Sprites: each wisp is one picture from a sheet, chosen by which side of it you see and how far its flicker has
// got. They stand upright and turn to face you, as the characters of old maze games did; the maze is boxes.

class Wisp : Behaviour
{
    int cx, cz, tx, tz;       // the square it is in, and the one it is going to
    float flicker = 0;
    array<string>@ map;

    void start()
    {
        flicker = random(0, 1);
        next();
    }

    bool open(int x, int z) { return z >= 0 && z < int(map.length()) && x >= 0 && x < int(map[uint(z)].length()) && map[uint(z)][uint(x)] != 35; }

    // On to an open square beside, not back the way it came unless it has to.
    void next()
    {
        array<int> dx = { 1, -1, 0, 0 }, dz = { 0, 0, 1, -1 };
        int backX = cx - (tx - cx), backZ = cz - (tz - cz);
        array<int> ways;
        for (int i = 0; i < 4; i++)
            if (open(cx + dx[uint(i)], cz + dz[uint(i)]) && !(cx + dx[uint(i)] == backX && cz + dz[uint(i)] == backZ))
                ways.insertLast(i);
        if (ways.length() == 0)
        {
            tx = backX;
            tz = backZ;
            return;
        }
        int w = ways[uint(random(0, float(ways.length()) - 0.01f))];
        tx = cx + dx[uint(w)];
        tz = cz + dz[uint(w)];
    }

    void update(float dt)
    {
        flicker += dt * 5;
        entity.spriteFrame = uint(flicker) % 2;
        Vec3 to = Vec3(tx * 4, 1, tz * 4) - entity.place;
        to.y = 0;
        float far = to.length();
        if (far < 0.05f)
        {
            cx = tx;
            cz = tz;
            next();
            return;
        }
        entity.face(to, clamp(dt * 6, 0, 1));
        entity.place = entity.place + to * (clamp(dt * 1.8f / far, 0, 1));
        entity.place = Vec3(entity.place.x, 0.9f + sin(flicker * 0.7f) * 0.12f, entity.place.z);
    }
}

class WispsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Texture@ sheet = Assets::texture("global:picture/sprite-wisp.png");
    Texture@ bricks = Assets::texture("global:picture/bricks.png");
    Texture@ tiles = Assets::texture("global:picture/tiles.png");
    array<string> map = {
        "###########",
        "#....#....#",
        "#.##.#.##.#",
        "#.#.....#.#",
        "#.#.###.#.#",
        "#...#.#...#",
        "###.#.#.###",
        "#.........#",
        "#.##.#.##.#",
        "#....#....#",
        "###########" };
    Entity@ hero;
    float yaw = 0, pitch = 0, shown = 0;

    void onEnter()
    {
        Space::ground(0);
        Space::sky(Color(0.02f, 0.02f, 0.05f), Color(0.05f, 0.05f, 0.1f));
        Space::fog(Color(0.03f, 0.03f, 0.07f), 6, 34);
        Space::sun(Vec3(0.3f, 1, 0.2f), Color(0.15f, 0.15f, 0.25f));
        Space::ambient(Color(0.12f, 0.12f, 0.2f), Color(0.05f, 0.05f, 0.08f));
        Space::farthest(40);
        int wisps = 0;
        for (uint z = 0; z < map.length(); z++)
            for (uint x = 0; x < map[z].length(); x++)
            {
                Vec3 at(float(x) * 4, 0, float(z) * 4);
                Entity@ floor = Space::spawn(at - Vec3(0, 0.1f, 0));
                floor.shape(SolidBox);
                floor.size = Vec3(4, 0.2f, 4);
                floor.skin(tiles);
                if (map[z][x] == 35)
                {
                    Entity@ wall = Space::spawn(at + Vec3(0, 1.75f, 0));
                    wall.shape(SolidBox);
                    wall.size = Vec3(4, 3.5f, 4);
                    wall.skin(bricks);
                    wall.cube(Vec3(1, 1, 1), 2);
                    wall.wall = true;
                }
                else if ((x + z * 3) % 7 == 0 && wisps < 9)
                {
                    wisps++;
                    Entity@ e = Space::spawn(at + Vec3(0, 0.9f, 0));
                    e.sprite(sheet, 4, 2);
                    e.size = Vec3(1.3f, 1.3f, 1.3f);
                    e.glowing = 1;
                    e.light(Color(0.5f, 0.7f, 1.4f), 6);
                    Wisp w;
                    w.cx = w.tx = int(x);
                    w.cz = w.tz = int(z);
                    @w.map = map;
                    e.add(w);
                }
            }
        @hero = Space::spawn(Vec3(4, 0.1f, 4));
        hero.capsule(0.35f, 1.6f, 1);
        hero.colliderAt = Vec3(0, 0.8f, 0);
        hero.walker = true;
        hero.mass = 60;
        yaw = 180;
    }

    void onExit()
    {
        Input::lockMouse(false);
    }

    void update(float dt)
    {
        shown += dt;
        // Look with the mouse, held in the window, or the right stick; walk with the left.
        Input::lockMouse(true);
        Vec2 turn = Input::mouseMove;
        if (shown > 0.3f)
        {
            yaw += turn.x * 0.2f;
            pitch = clamp(pitch - turn.y * 0.2f, -60, 60);
        }
        Vec2 pad = Input::padRight(0);
        yaw += pad.x * 120 * dt;
        pitch = clamp(pitch + pad.y * 90 * dt, -60, 60);
        Vec2 stick = Input::move;
        float a = yaw * 0.0174533f;
        Vec3 ahead(sin(a), 0, -cos(a)), side(cos(a), 0, sin(a));
        // Left and right turn, as in the old games, unless the mouse is there to look with.
        if (!Input::hasMouse)
            yaw += stick.x * 110 * dt;
        Vec3 wanted = (ahead * -stick.y + (Input::hasMouse ? side * stick.x : Vec3())) * 4.5f;
        Vec3 m = hero.motion;
        m.x += (wanted.x - m.x) * clamp(12 * dt, 0, 1);
        m.z += (wanted.z - m.z) * clamp(12 * dt, 0, 1);
        hero.motion = m;
        float p = pitch * 0.0174533f;
        Vec3 eye = hero.place + Vec3(0, 1.5f, 0);
        Space::camera(eye, eye + Vec3(sin(a) * cos(p), sin(p), -cos(a) * cos(p)), 70);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.6f, 0.6f);
        float help = clamp(6 - shown, 0, 1);
        if (help > 0)
        {
            c.alpha = help;
            c.roundRect(c.width * 0.5f - 380, 640, 760, 48, 14, Color(0, 0, 0, 0.5f));
            c.text(font, Input::usingPad ? "Left stick: walk    Right stick: look" : "Arrows: walk    Mouse: look", c.width * 0.5f, 650, White, AlignCenter);
            c.alpha = 1;
        }
    }
}
