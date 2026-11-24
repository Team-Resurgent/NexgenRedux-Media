// A ball goes to and fro along a tunnel. Hit it off centre, or while moving, and it curves.

class ReboundScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 64);
    Sound@ bat = Assets::sound("global:sound/hit.wav");
    Sound@ wall = Assets::sound("global:sound/wall.wav");
    Sound@ point = Assets::sound("global:sound/win.wav");
    Sound@ miss = Assets::sound("global:sound/lose.wav");

    // Half the width, height and length of the tunnel.
    Vec3 room(4, 2.6f, 11);
    Vec2 half(0.95f, 0.7f);
    Entity@ ball;
    array<Entity@> bats;
    array<Entity@> frames;
    Entity@ lamp;
    Vec2 mine, theirs, moving, mouseWas;
    Vec3 at, going;
    Vec2 curve;
    array<int> score = { 0, 0 };
    float wait = 1;
    float flash = 0;
    int serve = 1;
    bool finished = false;

    void onEnter()
    {
        Space::ambient(Color(0.3f, 0.32f, 0.42f), Color(0.2f, 0.2f, 0.28f));
        Space::sun(Vec3(0.2f, 1, 0.5f), Color(0.45f, 0.45f, 0.5f));
        Space::fog(Color(0.02f, 0.02f, 0.06f), 14, 40);
        Space::shadows(0);
        Mesh@ sides = Mesh();
        Color dark(0.12f, 0.15f, 0.28f);
        Vec3 r = room;
        sides.quad(Vec3(-r.x, -r.y, r.z), Vec3(r.x, -r.y, r.z), Vec3(r.x, -r.y, -r.z), Vec3(-r.x, -r.y, -r.z), dark);
        sides.quad(Vec3(-r.x, r.y, -r.z), Vec3(r.x, r.y, -r.z), Vec3(r.x, r.y, r.z), Vec3(-r.x, r.y, r.z), dark);
        sides.quad(Vec3(-r.x, -r.y, r.z), Vec3(-r.x, -r.y, -r.z), Vec3(-r.x, r.y, -r.z), Vec3(-r.x, r.y, r.z), dark);
        sides.quad(Vec3(r.x, -r.y, -r.z), Vec3(r.x, -r.y, r.z), Vec3(r.x, r.y, r.z), Vec3(r.x, r.y, -r.z), dark);
        Space::spawn(Vec3(0, 0, 0)).mesh(sides);
        // Frames along it; the one the ball is in lights up.
        for (int i = 0; i <= 10; i++)
        {
            Mesh@ frame = Mesh();
            float t = 0.06f;
            frame.box(Vec3(0, -r.y, 0), Vec3(r.x * 2, t, t));
            frame.box(Vec3(0, r.y, 0), Vec3(r.x * 2, t, t));
            frame.box(Vec3(-r.x, 0, 0), Vec3(t, r.y * 2, t));
            frame.box(Vec3(r.x, 0, 0), Vec3(t, r.y * 2, t));
            Entity@ e = Space::spawn(Vec3(0, 0, r.z - float(i) * r.z * 0.2f));
            e.mesh(frame, Blue);
            e.glowing = 1;
            frames.insertLast(e);
        }
        @ball = Space::spawn(Vec3(0, 0, 0));
        ball.shape(SolidSphere, Color(1, 0.9f, 0.5f));
        ball.size = Vec3(0.7f, 0.7f, 0.7f);
        ball.glowing = 0.4f;
        ball.shine = 1;
        @lamp = Space::spawn(Vec3(0, 0, 0));
        lamp.glow(2.2f, Color(1, 0.7f, 0.3f, 0.5f));
        for (int i = 0; i < 2; i++)
        {
            Entity@ e = Space::spawn(Vec3(0, 0, i == 0 ? r.z : -r.z));
            e.shape(SolidBox, i == 0 ? Color(0.4f, 0.8f, 1, 0.45f) : Color(1, 0.45f, 0.4f, 0.8f));
            e.size = Vec3(half.x * 2, half.y * 2, 0.15f);
            e.blend = BlendAlpha;
            e.glowing = 0.6f;
            bats.insertLast(e);
        }
        begin();
    }

    void begin()
    {
        at = Vec3(0, 0, 0);
        going = Vec3(random(-2, 2), random(-1.5f, 1.5f), float(serve) * 9);
        curve = Vec2(0, 0);
        wait = 1;
    }

    void update(float dt)
    {
        Vec2 before = mine;
        mine += Vec2(Input::move.x, -Input::move.y) * 8 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != mouseWas)
            mine = Vec2((mouse.x - 640) / 100, (360 - mouse.y) / 100);
        mouseWas = mouse;
        mine = Vec2(clamp(mine.x, -room.x + half.x, room.x - half.x), clamp(mine.y, -room.y + half.y, room.y - half.y));
        moving = (mine - before) / dt;
        if (finished)
        {
            if (Input::pressed("accept"))
            {
                score = { 0, 0 };
                finished = false;
                begin();
            }
            return;
        }
        // The other one follows, not quite fast enough.
        Vec2 wanted = going.z < 0 ? Vec2(at.x, at.y) : Vec2(0, 0);
        float quick = (3.6f + float(score[0]) * 0.25f) * dt;
        theirs += Vec2(clamp(wanted.x - theirs.x, -quick, quick), clamp(wanted.y - theirs.y, -quick, quick));

        wait -= dt;
        if (wait < 0)
        {
            going += Vec3(curve.x, curve.y, 0) * dt;
            at += going * dt;
            float r = 0.35f;
            if ((at.x > room.x - r && going.x > 0) || (at.x < -room.x + r && going.x < 0))
            {
                going.x = -going.x;
                curve.x = -curve.x * 0.5f;
                wall.play(0.4f, at.x / room.x);
            }
            if ((at.y > room.y - r && going.y > 0) || (at.y < -room.y + r && going.y < 0))
            {
                going.y = -going.y;
                curve.y = -curve.y * 0.5f;
                wall.play(0.4f, at.x / room.x);
            }
            if (at.z > room.z - 0.4f && going.z > 0)
                meet(mine, moving, 0);
            else if (at.z < -room.z + 0.4f && going.z < 0)
                meet(theirs, Vec2(random(-3, 3), random(-3, 3)), 1);
        }
        flash = clamp(flash - dt * 2, 0, 1);
        ball.place = at;
        ball.turn(Vec3(1, 0.4f, 0), going.z * 30 * dt);
        lamp.place = at;
        lamp.light(Color(1.4f, 1, 0.5f), 5);
        bats[0].place = Vec3(mine.x, mine.y, room.z);
        bats[1].place = Vec3(theirs.x, theirs.y, -room.z);
        for (uint i = 0; i < frames.length(); i++)
        {
            float near = clamp(1 - abs(frames[i].place.z - at.z) / 1.6f, 0, 1);
            frames[i].color = lerp(Color(0.12f, 0.2f, 0.5f), Color(1, 0.8f, 0.4f), near);
        }
        Space::camera(Vec3(mine.x * 0.18f, mine.y * 0.18f, room.z + 5.4f), Vec3(0, 0, -4), 55);
    }

    void meet(const Vec2 &in where, const Vec2 &in speed, int side)
    {
        Vec2 off(at.x - where.x, at.y - where.y);
        if (abs(off.x) < half.x + 0.3f && abs(off.y) < half.y + 0.3f)
        {
            going.z = -going.z * 1.035f;
            going.x += off.x * 2.4f;
            going.y += off.y * 2.4f;
            curve = Vec2(clamp(-speed.x * 0.8f, -7, 7), clamp(-speed.y * 0.8f, -7, 7));
            bat.play(0.7f, at.x / room.x);
            flash = 1;
            return;
        }
        if (abs(at.z) < room.z + 1)
            return;
        score[uint(1 - side)]++;
        (side == 0 ? miss : point).play(0.7f);
        serve = side == 0 ? -1 : 1;
        finished = score[uint(1 - side)] >= 7;
        begin();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        Space::draw(c);
        c.text(big, formatInt(score[0]), 560, 20, Color(0.5f, 0.85f, 1), AlignCenter);
        c.text(big, formatInt(score[1]), 720, 20, Color(1, 0.55f, 0.5f), AlignCenter);
        if (finished)
        {
            c.roundRect(390, 290, 500, 130, 24, Color(0, 0, 0, 0.75f));
            c.text(big, score[0] > score[1] ? "You win" : "You lose", 640, 296, White, AlignCenter);
            c.text(font, "Accept: again", 640, 378, Yellow, AlignCenter);
        }
        c.text(font, "Move the bat with the stick, arrows or mouse. First to seven.", 640, 676, Color(0.7f, 0.75f, 0.9f), AlignCenter);
    }
}
