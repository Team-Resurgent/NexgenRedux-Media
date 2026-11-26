// A world of blocks to dig and build in: hills of grass, earth and stone with hollows under them, sand by the sea,
// snow on the tops and trees, all made in the engine from a number. Each chunk of 16 blocks a side is made into only
// the faces that can be seen, joined where they are alike, with corners darker where blocks crowd them.

class BlocksScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ small = Assets::font("global:freesans.sfn", 16);
    Sound@ dig = Assets::sound("global:sound/hit.wav");
    Sound@ put = Assets::sound("global:sound/pop.wav");
    Sound@ boom = Assets::sound("global:sound/boom.wav");
    Sound@ jump = Assets::sound("global:sound/whoosh.wav");
    array<uint> kinds = { 1, 2, 3, 4, 5, 6, 7, 9, 11 };
    array<string> names = { "Grass", "Earth", "Stone", "Sand", "Wood", "Leaves", "Brick", "Planks", "Gold" };
    Entity@ hero;
    Entity@ aim;
    float yaw = 200, pitch = -30, shown = 0, again = 0;
    uint chosen = 6;
    bool hasTarget = false;
    Vec3 cell, face;
    int across = 160, deep = 160, high = 48, sea = 12;
    bool wasLeft = false, wasRight = false, wasLeftShoulder = false, wasRightShoulder = false;
    Vec2 wasTriggers;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        if (App::platform == "Original Xbox")
        {
            across = 112;
            deep = 112;
            high = 40;
        }
        // From a corner, so that the sea is at 0.
        Space::voxels(Vec3(-across / 2, -sea - 0.5f, -deep / 2), uint(across), uint(high), uint(deep), 1);
        Space::voxelHills(7, 22, 0.55f, sea, 0.55f);
        Space::water(0, Color(0.14f, 0.36f, 0.5f, 0.8f));
        Space::waterStyle("calm");
        Space::sky(Color(0.28f, 0.5f, 0.86f), Color(0.78f, 0.86f, 0.94f));
        Space::fog(Color(0.78f, 0.86f, 0.94f), 50, 150);
        Space::sun(Vec3(0.5f, 0.75f, 0.35f), Color(1, 0.93f, 0.8f));
        Space::ambient(Color(0.45f, 0.5f, 0.62f), Color(0.25f, 0.22f, 0.18f));
        Space::farthest(160);
        Space::shadows(0.55f, 36);
        plantTrees();
        buildHouse();

        // Where to start: on the land nearest the middle.
        int sx = across / 2, sz = deep / 2;
        for (int r = 0; r < 40 && Space::voxelTop(sx, sz) <= sea; r++)
            sx += 2;
        Vec3 start = Space::voxelPlace(sx, Space::voxelTop(sx, sz) + 1, sz) - Vec3(0, 0.5f, 0);
        @hero = Space::spawn(start + Vec3(0, 0.2f, 0));
        hero.capsule(0.35f, 1.7f, 1);
        hero.colliderAt = Vec3(0, 0.85f, 0);
        hero.walker = true;
        hero.mass = 60;
        // The block looked at, a little larger, and see-through.
        @aim = Space::spawn(Vec3());
        // The edges of the block looked at.
        Mesh@ frame = Mesh();
        for (int i = 0; i < 4; i++)
        {
            float a = (i & 1) == 0 ? -0.51f : 0.51f, b = (i & 2) == 0 ? -0.51f : 0.51f;
            frame.box(Vec3(0, a, b), Vec3(1.06f, 0.04f, 0.04f), Color(0.08f, 0.08f, 0.1f));
            frame.box(Vec3(a, 0, b), Vec3(0.04f, 1.06f, 0.04f), Color(0.08f, 0.08f, 0.1f));
            frame.box(Vec3(a, b, 0), Vec3(0.04f, 0.04f, 1.06f), Color(0.08f, 0.08f, 0.1f));
        }
        aim.mesh(frame);
        aim.shadow = false;
        aim.visible = false;
    }

    void onExit()
    {
        Input::lockMouse(false);
    }

    void plantTrees()
    {
        for (int i = 0; i < across * deep / 220; i++)
        {
            int x = int(random(4, float(across - 4))), z = int(random(4, float(deep - 4)));
            int top = Space::voxelTop(x, z);
            if (top <= sea + 1 || Space::voxel(x, top, z) != 1 || top > high - 10)
                continue;
            int tall = int(random(4, 7));
            Space::voxelBall(Space::voxelPlace(x, top + tall, z), random(2, 2.8f), 6);
            Space::fillVoxels(x, top + 1, z, x, top + tall, z, 5);
        }
    }

    // A little brick house with a plank roof, near the start, to show that building is just more blocks.
    void buildHouse()
    {
        int x = across / 2 + 6, z = deep / 2 - 8;
        int ground = 0;
        for (int dz = 0; dz < 7; dz++)
            for (int dx = 0; dx < 7; dx++)
                if (Space::voxelTop(x + dx, z + dz) > ground)
                    ground = Space::voxelTop(x + dx, z + dz);
        if (ground <= sea)
            return;
        Space::fillVoxels(x, ground - 3, z, x + 6, ground, z + 6, 3);
        Space::fillVoxels(x, ground + 1, z, x + 6, ground + 4, z + 6, 7);
        Space::fillVoxels(x + 1, ground + 1, z + 1, x + 5, ground + 4, z + 5, 0);
        Space::fillVoxels(x + 3, ground + 1, z, x + 3, ground + 2, z, 0);
        Space::fillVoxels(x, ground + 3, z + 3, x, ground + 3, z + 3, 0);
        Space::fillVoxels(x + 6, ground + 3, z + 3, x + 6, ground + 3, z + 3, 0);
        for (int step = 0; step < 4; step++)
            Space::fillVoxels(x - 1 + step, ground + 5 + step, z - 1 + step, x + 7 - step, ground + 5 + step, z + 7 - step, 9);
        Space::fillVoxels(x + 1, ground + 1, z + 1, x + 5, ground + 1, z + 5, 0);
        // Up to the open sky, and clear in front of the door.
        Space::fillVoxels(x - 1, ground + 1, z - 3, x + 7, ground + 12, z - 1, 0);
    }

    void update(float dt)
    {
        shown += dt;
        look(dt);
        walk(dt);
        target();
        act(dt);
    }

    void look(float dt)
    {
        Input::lockMouse(true);
        Vec2 turn = Input::mouseMove;
        if (shown > 0.3f)
        {
            yaw += turn.x * 0.2f;
            pitch = clamp(pitch - turn.y * 0.2f, -85, 85);
        }
        Vec2 pad = Input::padRight(0);
        yaw += pad.x * 130 * dt;
        pitch = clamp(pitch + pad.y * 100 * dt, -85, 85);
    }

    Vec3 eye() { return hero.place + Vec3(0, 1.55f, 0); }

    Vec3 gaze()
    {
        float a = yaw * 0.0174533f, p = pitch * 0.0174533f;
        return Vec3(sin(a) * cos(p), sin(p), -cos(a) * cos(p));
    }

    void walk(float dt)
    {
        Vec2 stick = Input::move;
        float a = yaw * 0.0174533f;
        Vec3 ahead(sin(a), 0, -cos(a)), side(cos(a), 0, sin(a));
        Vec3 wanted = (ahead * -stick.y + side * stick.x) * 4.6f;
        Vec3 m = hero.motion;
        float grip = hero.onGround ? 14 * dt : 4 * dt;
        m.x += (wanted.x - m.x) * clamp(grip, 0, 1);
        m.z += (wanted.z - m.z) * clamp(grip, 0, 1);
        bool swimming = hero.place.y < -1;
        if (swimming)
            m.y += (clamp((-0.9f - hero.place.y) * 3, -1, 2) - m.y) * clamp(6 * dt, 0, 1);
        // A block high, and a little more.
        if (Input::pressed("accept") && (hero.onGround || swimming))
        {
            m.y = 6.4f;
            jump.play(0.25f);
        }
        hero.motion = m;
        if (hero.place.y < -30)
            hero.place = Vec3(hero.place.x, 30, hero.place.z);
        Vec3 e = eye();
        Space::camera(e, e + gaze(), 72);
    }

    void target()
    {
        Vec3 hit;
        Vec3 e = eye();
        hasTarget = Space::voxelRay(e, e + gaze() * 8, cell, face, hit);
        aim.visible = hasTarget;
        if (hasTarget)
            aim.place = Space::voxelPlace(int(cell.x), int(cell.y), int(cell.z));
    }

    void act(float dt)
    {
        // Which kind to build with: the wheel, the shoulders or the numbers.
        bool ls = Input::padButton(0, 12), rs = Input::padButton(0, 13);
        int turn = (Input::wheel < 0 || (rs && !wasRightShoulder)) ? 1 : (Input::wheel > 0 || (ls && !wasLeftShoulder)) ? -1 : 0;
        wasLeftShoulder = ls;
        wasRightShoulder = rs;
        chosen = uint((int(chosen) + turn + int(kinds.length())) % int(kinds.length()));
        for (uint i = 0; i < kinds.length(); i++)
            if (Input::key(formatInt(i + 1)))
                chosen = i;

        Vec2 triggers = Input::padTriggers(0);
        bool left = Input::mouseDown(0), right = Input::mouseDown(1);
        bool digging = (left && !wasLeft) || (triggers.y > 0.5f && wasTriggers.y <= 0.5f) || Input::pressed("alternate");
        bool building = (right && !wasRight) || (triggers.x > 0.5f && wasTriggers.x <= 0.5f);
        // Held, again and again.
        bool holding = left || right || triggers.x > 0.5f || triggers.y > 0.5f || Input::held("alternate");
        again = holding ? again - dt : 0.35f;
        if (again < 0)
        {
            again = 0.2f;
            digging = left || triggers.y > 0.5f || Input::held("alternate");
            building = right || triggers.x > 0.5f;
        }
        wasLeft = left;
        wasRight = right;
        wasTriggers = triggers;
        if (!hasTarget)
            return;
        int x = int(cell.x), y = int(cell.y), z = int(cell.z);
        if (digging)
        {
            uint was = Space::voxel(x, y, z);
            if (Space::setVoxel(x, y, z, 0))
            {
                Space::burst(was == 4 || was == 8 ? "puff" : "chips", Space::voxelPlace(x, y, z), 18);
                dig.playAt(Space::voxelPlace(x, y, z), 0.5f, 30, random(0.8f, 1.2f));
            }
        }
        else if (building)
        {
            int bx = x + int(face.x), by = y + int(face.y), bz = z + int(face.z);
            Vec3 middle = Space::voxelPlace(bx, by, bz);
            // Not where the one building is standing.
            Vec3 d = middle - hero.place;
            bool inside = abs(d.x) < 0.85f && abs(d.z) < 0.85f && d.y > -0.5f && d.y < 2.2f;
            if (!inside && Space::setVoxel(bx, by, bz, kinds[chosen]))
                put.playAt(middle, 0.5f, 30, random(0.9f, 1.1f));
        }
        // Y, or the middle button: a round hole, all at once.
        if (Input::padButton(0, 11) && !wasY || Input::mouseDown(2) && !wasMiddle)
        {
            Vec3 at = Space::voxelPlace(x, y, z);
            if (Space::voxelBall(at, 2.6f, 0) > 0)
            {
                Space::burst("chips", at, 60);
                Space::burst("puff", at, 30);
                boom.playAt(at, 0.6f, 50);
            }
        }
        wasY = Input::padButton(0, 11);
        wasMiddle = Input::mouseDown(2);
    }
    bool wasY = false, wasMiddle = false;

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        float mid = c.width * 0.5f;
        // Where it is aimed.
        c.rect(mid - 9, 359, 18, 2, Color(1, 1, 1, 0.8f));
        c.rect(mid - 1, 351, 2, 18, Color(1, 1, 1, 0.8f));
        // What it builds with.
        float w = 54, left = mid - w * float(kinds.length()) * 0.5f;
        c.roundRect(left - 8, 640, w * float(kinds.length()) + 16, 64, 12, Color(0, 0, 0, 0.45f));
        for (uint i = 0; i < kinds.length(); i++)
        {
            float x = left + w * float(i);
            Color top = kindColor(kinds[i]);
            if (i == chosen)
                c.roundRect(x + 2, 644, w - 4, 56, 8, Color(1, 1, 1, 0.85f));
            c.roundRect(x + 8, 650, w - 16, w - 16, 6, top);
            c.text(small, formatInt(i + 1), x + 12, 650, Color(0, 0, 0, 0.6f));
        }
        c.text(small, names[chosen], mid, 616, White, AlignCenter);
        float help = clamp(8 - shown, 0, 1);
        if (help > 0)
        {
            c.alpha = help;
            c.roundRect(mid - 470, 24, 940, 44, 14, Color(0, 0, 0, 0.5f));
            c.text(font, Input::usingPad ? "Sticks: walk and look   A: jump   RT: dig   LT: build   Y: big hole   Shoulders: kind" : "Arrows: walk   Mouse: look   Space: jump   Left: dig   Right: build   Middle: big hole   Wheel: kind", mid, 34, White, AlignCenter);
            c.alpha = 1;
        }
    }

    Color kindColor(uint kind)
    {
        if (kind == 1) return Color(0.36f, 0.62f, 0.26f);
        if (kind == 2) return Color(0.5f, 0.38f, 0.26f);
        if (kind == 3) return Color(0.55f, 0.55f, 0.56f);
        if (kind == 4) return Color(0.86f, 0.8f, 0.58f);
        if (kind == 5) return Color(0.4f, 0.29f, 0.18f);
        if (kind == 6) return Color(0.24f, 0.47f, 0.2f);
        if (kind == 7) return Color(0.66f, 0.33f, 0.26f);
        if (kind == 9) return Color(0.76f, 0.62f, 0.42f);
        return Color(0.95f, 0.78f, 0.3f);
    }
}
