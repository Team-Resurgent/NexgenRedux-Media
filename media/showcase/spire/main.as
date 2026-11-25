// Blocks fall round a tower, which turns to meet them. A ring that is full all the way round goes.

const int Around = 18;
const int Tall = 15;

class SpireScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 56);
    Sound@ thud = Assets::sound("global:sound/wall.wav");
    Sound@ turnSound = Assets::sound("global:sound/move.wav");
    Sound@ clearSound = Assets::sound("global:sound/win.wav");
    Sound@ lost = Assets::sound("global:sound/lose.wav");
    Sound@ music = Assets::sound("global:music/climb.ogg");

    // Each shape as places, across and up: two to five blocks.
    array<array<Vec2>> shapes = {
        { Vec2(0, 0), Vec2(1, 0) },
        { Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0) },
        { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1) },
        { Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(-1, 1), Vec2(1, 1) },
        { Vec2(0, 0), Vec2(-1, 0), Vec2(1, 0), Vec2(0, 1), Vec2(0, -1) },
        { Vec2(-1, 0), Vec2(0, 0), Vec2(1, 0), Vec2(1, 1) },
        { Vec2(0, 0), Vec2(1, 0), Vec2(0, 1), Vec2(1, 1) },
        { Vec2(0, 0) }
    };
    array<int> cells(Around * Tall);       // 0 empty, otherwise a colour
    array<Entity@> blocks(Around * Tall);
    array<Entity@> piece;
    array<Entity@> ghost;
    array<Vec2> form;
    array<Vec2> nextForm;
    int color = 1;
    int nextColor = 2;
    float turned = 0;                      // of the tower, in columns
    int facing = 0;                        // the column in front
    float high = 0;                        // of the piece
    float flash = 0;
    array<int> flashing;
    int score = 0;
    int rings = 0;
    bool over = false;
    float shake = 0;

    void onEnter()
    {
        music.playMusic(0.5f, 0.8f);
        Space::sky(Color(0.05f, 0.04f, 0.14f), Color(0.3f, 0.16f, 0.36f));
        Space::sun(Vec3(0.5f, 0.6f, 0.8f), Color(0.95f, 0.9f, 0.85f));
        Space::ambient(Color(0.4f, 0.4f, 0.5f), Color(0.26f, 0.2f, 0.28f));
        Space::shadows(0.5f, 14);
        Space::ground(-0.5f);
        Entity@ core = Space::spawn(Vec3(0, float(Tall) * 0.5f - 0.5f, 0));
        core.shape(SolidCylinder, Color(0.28f, 0.28f, 0.36f));
        core.size = Vec3(4.5f, float(Tall), 4.5f);
        core.shine = 0.5f;
        Entity@ base = Space::spawn(Vec3(0, -0.9f, 0));
        base.shape(SolidCylinder, Color(0.2f, 0.2f, 0.28f));
        base.size = Vec3(8.5f, 0.8f, 8.5f);
        for (int i = 0; i < Around * Tall; i++)
            @blocks[i] = block(Vec3(0, 0, 0));
        for (int i = 0; i < 5; i++)
        {
            piece.insertLast(block(Vec3(0, 0, 0)));
            Entity@ g = block(Vec3(0, 0, 0));
            g.blend = BlendAdd;
            g.shadow = false;
            ghost.insertLast(g);
        }
        start();
    }

    Entity@ block(const Vec3 &in at)
    {
        Entity@ e = Space::spawn(at);
        e.shape(SolidBox, White);
        e.shine = 0.4f;
        e.visible = false;
        return e;
    }

    void start()
    {
        for (int i = 0; i < Around * Tall; i++)
            cells[i] = 0;
        // Something to begin with: two rings, each with a few gaps.
        for (int x = 0; x < Around; x++)
        {
            cells[x] = x % 5 == 2 ? 0 : 1 + x % 6;
            cells[Around + x] = x % 3 == 0 ? 0 : 1 + (x + 2) % 6;
        }
        score = rings = 0;
        over = false;
        pick();
        take();
    }

    void pick()
    {
        nextForm = shapes[uint(randomInt(0, int(shapes.length()) - 1))];
        nextColor = randomInt(1, 6);
    }

    void take()
    {
        form = nextForm;
        color = nextColor;
        pick();
        high = float(Tall) - 1.5f;
        if (hits(form, facing, int(high)))
        {
            over = true;
            lost.play(0.8f);
        }
    }

    int wrap(int x) { return ((x % Around) + Around) % Around; }

    bool hits(const array<Vec2> &in f, int column, int row)
    {
        for (uint i = 0; i < f.length(); i++)
        {
            int x = wrap(column + int(f[i].x)), y = row + int(f[i].y);
            if (y < 0 || (y < Tall && cells[y * Around + x] != 0))
                return true;
        }
        return false;
    }

    int resting()
    {
        int y = int(ceil(high));
        while (y > -2 && !hits(form, facing, y - 1))
            y--;
        return y;
    }

    void update(float dt)
    {
        shake = clamp(shake - dt * 3, 0, 1);
        turned += (float(facing) - turned) * clamp(dt * 14, 0, 1);
        if (flash > 0)
        {
            flash -= dt * 2.5f;
            if (flash <= 0)
                collapse();
        }
        else if (over)
        {
            if (Input::pressed("accept"))
                start();
        }
        else
            play(dt);
        show();
    }

    void play(float dt)
    {
        int row = int(ceil(high));
        int way = (Input::repeated("right") ? 1 : 0) - (Input::repeated("left") ? 1 : 0);
        if (way != 0 && !hits(form, facing + way, row) && !hits(form, facing + way, int(floor(high))))
        {
            facing += way;
            turnSound.play(0.35f);
        }
        if (Input::pressed("accept") || Input::pressed("up"))
        {
            array<Vec2> other;
            for (uint i = 0; i < form.length(); i++)
                other.insertLast(Vec2(form[i].y, -form[i].x));
            // Nudged aside, if there is something in the way.
            for (int nudge = 0; nudge < 3; nudge++)
            {
                int by = nudge == 2 ? -1 : nudge;
                if (!hits(other, facing + by, row) && !hits(other, facing + by, int(floor(high))))
                {
                    form = other;
                    facing += by;
                    turnSound.play(0.35f, 0, 1.4f);
                    break;
                }
            }
        }
        float speed = 1.4f + float(rings) * 0.12f;
        if (Input::held("down"))
            speed = 14;
        int floorAt = resting();
        if (Input::pressed("fire") && !Input::pressed("accept"))
        {
            score += int(high - float(floorAt));
            high = float(floorAt);
            shake = 0.6f;
        }
        else
            high -= speed * dt;
        if (high <= float(floorAt))
            land(floorAt);
    }

    void land(int row)
    {
        for (uint i = 0; i < form.length(); i++)
        {
            int x = wrap(facing + int(form[i].x)), y = row + int(form[i].y);
            if (y >= 0 && y < Tall)
                cells[y * Around + x] = color;
        }
        thud.play(0.5f);
        score += 5;
        flashing.resize(0);
        for (int y = 0; y < Tall; y++)
        {
            int full = 0;
            for (int x = 0; x < Around; x++)
                full += cells[y * Around + x] != 0 ? 1 : 0;
            if (full == Around)
                flashing.insertLast(y);
        }
        if (flashing.length() > 0)
        {
            flash = 1;
            clearSound.play(0.7f);
            score += 100 * int(flashing.length() * flashing.length());
            rings += int(flashing.length());
        }
        else
            take();
    }

    void collapse()
    {
        for (int n = int(flashing.length()) - 1; n >= 0; n--)
        {
            for (int y = flashing[uint(n)]; y < Tall; y++)
                for (int x = 0; x < Around; x++)
                    cells[y * Around + x] = y + 1 < Tall ? cells[(y + 1) * Around + x] : 0;
            for (int i = 0; i < 12; i++)
            {
                Entity@ spark = Space::spawn(at(i * 2, float(flashing[uint(n)]), 4));
                spark.glow(random(0.4f, 1), hsv(random(0, 1), 0.6f, 1));
                spark.motion = Vec3(random(-3, 3), random(2, 6), random(0, 4));
                spark.gravity = 0.8f;
                spark.lifetime = 0.9f;
            }
        }
        flash = 0;
        take();
    }

    // A column of the tower, as it is turned.
    Vec3 at(int column, float row, float r = 2.85f)
    {
        float a = (float(column) - turned) * 6.28319f / float(Around);
        return Vec3(sin(a) * r, row, cos(a) * r);
    }

    void put(Entity@ e, int column, float row, const Color &in tone, float size)
    {
        e.visible = true;
        e.place = at(column, row);
        e.angles = Vec3(0, (float(column) - turned) * 360 / float(Around), 0);
        e.size = Vec3(0.94f, 0.92f, 1.1f) * size;
        e.color = tone;
    }

    Color tone(int which) { return hsv(0.02f + float(which) * 0.155f, 0.62f, 0.98f); }

    void show()
    {
        for (int y = 0; y < Tall; y++)
        {
            bool going = flash > 0 && flashing.find(y) >= 0;
            for (int x = 0; x < Around; x++)
            {
                Entity@ e = blocks[uint(y * Around + x)];
                int cell = cells[y * Around + x];
                e.visible = cell != 0;
                if (cell != 0)
                {
                    put(e, x, float(y), going ? White : tone(cell), going ? 0.3f + flash * 0.7f : 1.0f);
                    e.glowing = going ? 1 : 0;
                }
            }
        }
        int floorAt = over || flash > 0 ? 0 : resting();
        for (uint i = 0; i < 5; i++)
        {
            bool on = !over && flash <= 0 && i < form.length();
            piece[i].visible = on;
            ghost[i].visible = on;
            if (on)
            {
                int x = facing + int(form[i].x);
                put(piece[i], x, high + form[i].y, tone(color), 1);
                put(ghost[i], x, float(floorAt) + form[i].y, fade(tone(color), 0.35f), 1);
            }
        }
        Space::camera(Vec3(0, 10 + sin(App::time * 40) * shake * 0.2f, 18), Vec3(0, 6.2f, 0), 56);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.45f, 0.7f);
        c.text(big, formatInt(score), 60, 60);
        c.text(font, formatInt(rings) + " rings", 62, 130, Color(0.8f, 0.8f, 0.95f));
        c.text(font, "Next", c.width - 150, 60, Color(0.8f, 0.8f, 0.95f), AlignCenter);
        for (uint i = 0; i < nextForm.length(); i++)
            c.roundRect(c.width - 150 - 17 + nextForm[i].x * 36, 150 - nextForm[i].y * 36, 33, 33, 7, tone(nextColor));
        if (over)
        {
            c.roundRect(c.width * 0.5f - 260, 280, 520, 150, 24, Color(0, 0, 0, 0.75f));
            c.text(big, "It is full", c.width * 0.5f, 300, White, AlignCenter);
            c.text(font, "Accept: again", c.width * 0.5f, 378, Yellow, AlignCenter);
        }
        c.text(font, "Left, right: turn the tower     Up: turn the block     Down: faster     Fire: drop", c.width * 0.5f, 676, Color(0.8f, 0.8f, 0.95f), AlignCenter);
    }
}
