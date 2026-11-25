// A race. The land streams in ahead and goes behind; the way through it is worked out from a number, so it
// is the same for everyone. Three others race, and a second player may, with a gamepad of their own.

const int Gates = 30;
const float Between = 62;
const float Sea = 11.5f;       // how high the ponds stand

Sound@ chime = Assets::sound("global:sound/gate.wav");
Sound@ bump = Assets::sound("global:sound/hit.wav");

// Where the way goes: along -z, from side to side.
float wayX(float z) { return sin(z * 0.011f) * 34 + sin(z * 0.0047f + 1.3f) * 46 + sin(z * 0.023f + 0.4f) * 9; }
Vec3 gateAt(int i)
{
    float z = -float(i + 1) * Between;
    float x = wayX(z);
    float y = Space::height(x, z);
    return Vec3(x, (y > Sea ? y : Sea) + 4.4f, z);
}

class Racer
{
    Entity@ e;
    Entity@ jet;
    string name;
    Color color;
    Vec3 at, speed;
    float yaw = 0, bank = 0, climb = 0, nose = 0;
    float boost = 1;
    bool boosting = false;
    int gate = 0;
    float done = 0;         // seconds it took, when it has
    bool human = false;
    int pad = -1;           // whose
    float skill = 1;
    float stuck = 0;
    Voice engine;
    Vec3 eye, look;         // of their camera
    float flash = 0;
    Vec2 mark;              // where their gate is on the screen
    bool marked = false;

    // How far along, to see who is ahead.
    float along() { return done > 0 ? 100000 - done : float(gate) * Between + (Between - (gateAt(gate) - at).length()); }
}

class SkimScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 64);
    Model@ skimmer = Assets::model("global:model/skimmer.glb");
    Model@ gateModel = Assets::model("global:model/gate.glb");
    Model@ pine = Assets::model("global:model/pine.glb");
    Model@ oak = Assets::model("global:model/oak.glb");
    Model@ rock = Assets::model("global:model/rock.glb");
    Sound@ engine = Assets::sound("global:sound/engine.wav");
    Sound@ rush = Assets::sound("global:sound/boost.wav");
    Sound@ beep = Assets::sound("global:sound/move.wav");
    Sound@ splash = Assets::sound("global:sound/splash.wav");
    Sound@ music = Assets::sound("global:music/climb.ogg");
    array<Racer@> racers;
    array<Entity@> gates;
    float clock = -3.5f;
    int counted = 4;
    bool two = false;
    bool over = false;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        music.playMusic(0.35f, 1);
        Space::endlessLand(1234, 2.5f, 26, 0.35f, App::platform == "Original Xbox" ? 2 : 4);
        Space::landColors(Color(0.8f, 0.72f, 0.5f), Color(0.36f, 0.52f, 0.26f), Color(0.6f, 0.58f, 0.55f), Color(0.46f, 0.41f, 0.36f), Sea + 0.9f, 20);
        Space::water(Sea, Color(0.16f, 0.42f, 0.55f, 0.82f));
        Space::sky(Color(0.25f, 0.4f, 0.75f), Color(0.95f, 0.75f, 0.6f));
        Space::fog(Color(0.92f, 0.76f, 0.66f), 90, 290);
        Space::sun(Vec3(0.5f, 0.45f, -0.6f), Color(1, 0.82f, 0.62f));
        Space::ambient(Color(0.42f, 0.44f, 0.55f), Color(0.26f, 0.22f, 0.2f));
        Space::farthest(360);
        Space::shadows(0.6f, 45);
        two = Input::padConnected(1);
        array<Color> colors = { Color(1, 0.55f, 0.2f), Color(0.3f, 0.7f, 1), Color(0.55f, 0.95f, 0.4f), Color(0.95f, 0.4f, 0.75f) };
        array<string> names = { "You", "Isla", "Bram", "Juno" };
        for (int i = 0; i < 4; i++)
        {
            Racer@ r = Racer();
            r.name = i == 1 && two ? "Two" : names[uint(i)];
            r.color = colors[uint(i)];
            r.human = i == 0 || (i == 1 && two);
            r.pad = i;
            r.skill = 0.86f + float(i) * 0.03f;
            r.at = Vec3(wayX(0) + (float(i) - 1.5f) * 6, 6, 0);
            r.at.y = level(r.at) + 1.4f;
            @r.e = Space::spawn(r.at);
            r.e.model(skimmer);
            r.e.color = r.color;
            r.e.shine = 0.8f;
            r.e.sphere(1.3f, 1);
            @r.jet = Space::spawn(Vec3(0, -0.02f, -1.6f));
            r.jet.attach(r.e);
            r.jet.angles = Vec3(-90, 0, 0);
            r.jet.emit("jet", 40);
            r.engine = r.e.sound(engine, i == 0 ? 0.35f : 0.5f, 70);
            r.eye = r.at + Vec3(0, 4, 10);
            r.look = r.at;
            racers.insertLast(r);
        }
        for (int i = 0; i < Gates; i++)
        {
            Entity@ g = Space::spawn(Vec3(0, -100, 0));
            g.model(gateModel);
            g.visible = false;
            gates.insertLast(g);
        }
    }

    float level(const Vec3 &in p)
    {
        float y = Space::height(p.x, p.z);
        return y > Sea + 0.2f ? y : Sea + 0.2f;      // over water too
    }

    float chance(int x, int z, int n)
    {
        float v = sin(float(x) * 12.9898f + float(z) * 78.233f + float(n) * 37.719f) * 43758.5453f;
        return v - floor(v);
    }

    void fill(int x, int z)
    {
        float size = Space::regionSize;
        for (int n = 0; n < 11; n++)
        {
            float px = (float(x) + chance(x, z, n)) * size, pz = (float(z) + chance(x, z, n + 50)) * size;
            float y = Space::height(px, pz);
            // The way is kept clear.
            if (y < Sea + 0.8f || abs(px - wayX(pz)) < 17 || Space::normal(px, pz).y < 0.75f)
                continue;
            Entity@ e = Space::spawn(Vec3(px, y, pz));
            bool stone = n % 4 == 0;
            e.model(stone ? rock : y > 11 ? pine : oak);
            float big2 = stone ? 1 + chance(x, z, n + 90) * 2 : 1 + chance(x, z, n + 90) * 0.8f;
            e.size = Vec3(big2, big2, big2);
            e.angles = Vec3(0, chance(x, z, n + 130) * 360, 0);
            e.streamed = true;
            if (stone)
                e.sphere(0.9f, 2);
            else
                e.capsule(0.45f, 6, 2);
            e.colliderAt = Vec3(0, stone ? 0.3f : 2.0f, 0);
        }
    }

    void update(float dt)
    {
        int x, z;
        bool arrived;
        while (Space::nextRegion(x, z, arrived))
            if (arrived)
                fill(x, z);

        clock += dt;
        int count = int(ceil(-clock));
        if (clock < 0 && count < counted)
        {
            counted = count;
            beep.play(0.6f);
        }
        else if (clock >= 0 && counted > 0)
        {
            counted = 0;
            chime.play(0.8f, 0, 1.4f);
        }
        for (uint i = 0; i < racers.length(); i++)
            race(racers[i], dt);
        // Gates light up for whoever is nearest to them.
        for (int i = 0; i < Gates; i++)
        {
            bool near = false;
            for (uint n = 0; n < racers.length(); n++)
                if (racers[n].human && i >= racers[n].gate && i < racers[n].gate + 5)
                    near = true;
            gates[uint(i)].visible = near;
            if (near)
            {
                Vec3 p = gateAt(i);
                gates[uint(i)].place = p;
                Vec3 to = gateAt(i + 1 < Gates ? i + 1 : i) - (i > 0 ? gateAt(i - 1) : Vec3(wayX(0), p.y, 0));
                gates[uint(i)].face(to);
                gates[uint(i)].color = i == racers[0].gate ? Color(1, 0.85f, 0.3f) : Color(0.35f, 0.7f, 1);
            }
        }
        if (racers[0].done > 0 && !over && (!two || racers[1].done > 0))
            over = true;
        if (over && Input::pressed("accept"))
            Screens::replace("skim");
    }

    void race(Racer@ r, float dt)
    {
        // What is asked of it.
        float turn = 0, thrust = 0;
        bool fast = false;
        Vec3 target = gateAt(r.gate < Gates ? r.gate : Gates - 1) + (r.gate >= Gates ? Vec3(0, 0, -200) : Vec3());
        if (clock > 0)
        {
            Vec3 to = target - r.at;
            // Each rival has a line of its own.
            if (!r.human)
                to.x += (float(r.pad) - 2) * 2.6f;
            float off = atan2(-to.x, -to.z) - r.yaw;
            while (off > 3.14159f) off -= 6.28319f;
            while (off < -3.14159f) off += 6.28319f;
            if (r.human && r.done == 0)
            {
                Vec2 stick = r.pad == 0 ? Input::move : Vec2(Input::padLeft(1).x, -Input::padLeft(1).y);
                // With the stick let go, it keeps to the way by itself.
                turn = abs(stick.x) > 0.12f ? -stick.x : clamp(off * 2, -0.7f, 0.7f);
                thrust = clamp(0.75f - stick.y * 0.5f, 0, 1);
                fast = r.pad == 0 ? Input::held("fire") || Input::held("accept") : Input::padButton(1, 8);
            }
            else
            {
                turn = clamp(off * 2.6f, -1, 1);
                // Those far behind try harder, and those far ahead take it easier.
                float gap = clamp((racers[0].along() - r.along()) * 0.0018f, -0.1f, 0.16f);
                thrust = clamp(r.skill + gap - abs(turn) * 0.18f, 0.3f, 1.15f);
                fast = abs(off) < 0.15f && r.boost > 0.9f && r.skill > 0.9f;
                if (r.boosting)
                    fast = r.boost > 0.1f;
            }
        }
        if (fast && r.boost > 0.05f)
        {
            if (!r.boosting)
                rush.playAt(r.at, 0.6f, 60);
            r.boosting = true;
        }
        else
            r.boosting = false;
        r.boost = clamp(r.boost + (r.boosting ? -dt * 0.55f : dt * 0.16f), 0, 1);

        r.yaw += turn * 1.35f * dt;
        r.bank += (turn - r.bank) * clamp(dt * 6, 0, 1);
        Vec3 ahead(-sin(r.yaw), 0, -cos(r.yaw));
        float top = (r.boosting ? 62.0f : 43.0f) * thrust;
        Vec3 flat(r.speed.x, 0, r.speed.z);
        // It slides a little before it goes where it points.
        flat = lerp(flat, ahead * top, clamp(dt * (clock > 0 ? 1.9f : 4.0f), 0, 1));
        // On a cushion of air.
        float under = level(r.at), aheadLevel = level(r.at + flat * 0.22f);
        float wantedY = (under > aheadLevel ? under : aheadLevel) + 1.5f + sin(App::time * 2 + float(r.pad)) * 0.12f;
        r.climb += ((wantedY - r.at.y) * 26 - r.climb * 7) * dt;
        r.speed = Vec3(flat.x, r.climb, flat.z);
        r.at += r.speed * dt;
        if (r.at.y < under + 0.5f)
        {
            r.at.y = under + 0.5f;
            r.climb = r.climb < 0 ? 0.0f : r.climb;
        }
        // They keep apart.
        for (uint i = 0; i < racers.length(); i++)
        {
            Vec3 gap = r.at - racers[i].at;
            float far = gap.length();
            if (racers[i] !is r && far < 5 && far > 0.01f)
                r.at += gap * ((5 - far) / far * clamp(dt * 3, 0, 1));
        }
        // Trees and rocks.
        array<Entity@>@ met = Space::within(r.at, 1.2f, 1 << 2);
        r.stuck -= dt;
        if (met.length() > 0)
        {
            Vec3 away = r.at - met[0].place;
            away.y = 0;
            away = away.normalized();
            r.speed = away * 16;
            r.at += away * 0.6f;
            if (r.stuck < 0)
            {
                bump.playAt(r.at, 0.7f, 50);
                Space::burst("spark", r.at, 24);
                r.stuck = 0.4f;
            }
        }
        r.nose += (clamp(r.climb * 1.6f, -24, 24) - r.nose) * clamp(dt * 5, 0, 1);
        r.e.place = r.at;
        r.e.angles = Vec3(-r.nose, r.yaw * 57.2958f + 180, r.bank * -34);
        float going = flat.length();
        r.jet.emit(r.boosting ? "burn" : "jet", clock > 0 ? 20 + going : 10);
        r.engine.pitch = 0.7f + going * 0.018f + (r.boosting ? 0.25f : 0.0f);
        if (under <= Sea + 0.25f && going > 8)
            Space::burst("spray", Vec3(r.at.x, Sea + 0.1f, r.at.z) - ahead * 1.2f, 2);
        else if (going > 20)
            Space::burst("dust", Vec3(r.at.x, under + 0.1f, r.at.z) - ahead * 1.6f, 1);

        // Through a gate, or past it.
        r.flash = clamp(r.flash - dt * 2, 0, 1);
        if (r.gate < Gates && r.done == 0)
        {
            Vec3 to = target - r.at;
            bool passed = r.at.z < target.z;
            if (passed || to.length() < 4)
            {
                bool through = Vec3(to.x, to.y * 0.5f, 0).length() < 5.4f;
                if (through)
                {
                    r.boost = clamp(r.boost + 0.22f, 0, 1);
                    r.flash = 1;
                    if (r.human)
                        chime.play(0.6f, 0, 1 + float(r.gate % 8) * 0.06f);
                    Space::burst("spark", target, 30);
                }
                else if (r.human)
                    r.speed = r.speed * 0.55f;      // missing one costs
                r.gate++;
                if (r.gate == Gates)
                    r.done = clock;
            }
        }
        // Their camera, a little behind.
        Vec3 wantedEye = r.at - ahead * (9 - going * 0.02f) + Vec3(0, 3.4f, 0);
        float least = level(wantedEye) + 1;
        wantedEye.y = wantedEye.y < least ? least : wantedEye.y;
        r.eye = lerp(r.eye, wantedEye, clamp(dt * 6, 0, 1));
        r.look = lerp(r.look, r.at + ahead * 9 + Vec3(0, 0.6f, 0), clamp(dt * 9, 0, 1));
        if (r.pad == 0)
            Space::camera(r.eye, r.look, 62 + going * 0.22f);
    }

    int place(Racer@ r)
    {
        int ahead = 1;
        for (uint i = 0; i < racers.length(); i++)
            if (racers[i] !is r && racers[i].along() > r.along())
                ahead++;
        return ahead;
    }

    void view(Canvas@ c, Racer@ r, float x, float w)
    {
        Space::camera(r.eye, r.look, 62 + Vec3(r.speed.x, 0, r.speed.z).length() * 0.22f);
        Space::draw(c, x, 0, w, 720);
        Vec3 g = gateAt(r.gate < Gates ? r.gate : Gates - 1);
        r.marked = r.gate < Gates && Space::toScreen(g, r.mark) && (g - r.at).length() > 16;
    }

    void readings(Canvas@ c, Racer@ r, float x, float w)
    {
        int at = place(r);
        c.text(big, formatInt(at), x + 46, 28, r.color);
        c.text(font, at == 1 ? "st" : at == 2 ? "nd" : at == 3 ? "rd" : "th", x + 90, 40, r.color);
        c.text(font, "Gate " + formatInt(r.gate) + " of " + formatInt(Gates), x + 46, 104);
        c.roundRect(x + 46, 640, 240, 18, 9, Color(0, 0, 0, 0.45f));
        c.roundRect(x + 48, 642, 10 + 226 * r.boost, 14, 7, r.boosting ? Color(1, 0.6f, 0.2f) : Color(0.35f, 0.8f, 1));
        c.text(font, formatInt(int(Vec3(r.speed.x, 0, r.speed.z).length() * 3.6f)) + " km/h", x + 300, 632);
        if (r.marked)
        {
            c.ring(r.mark.x, r.mark.y, 16, 2, Color(1, 0.85f, 0.3f, 0.8f));
            c.text(font, formatInt(int((gateAt(r.gate) - r.at).length())), r.mark.x, r.mark.y + 20, Color(1, 0.85f, 0.3f, 0.9f), AlignCenter);
        }
        if (r.flash > 0)
            c.rect(x, 0, w, 720, Color(1, 0.9f, 0.5f, r.flash * 0.12f));
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        if (two)
        {
            view(c, racers[0], 0, c.width * 0.5f - 2);
            view(c, racers[1], c.width * 0.5f + 2, c.width * 0.5f - 2);
            c.bloom(0.45f, 0.85f);
            readings(c, racers[0], 0, c.width * 0.5f - 2);
            readings(c, racers[1], c.width * 0.5f + 2, c.width * 0.5f - 2);
            c.rect(c.width * 0.5f - 2, 0, 4, 720, Black);
        }
        else
        {
            view(c, racers[0], 0, c.width);
            c.bloom(0.45f, 0.85f);
            readings(c, racers[0], 0, c.width);
        }
        float t = racers[0].done > 0 ? racers[0].done : clock > 0 ? clock : 0.0f;
        int tenths = int(t * 10) % 10;
        c.text(font, formatInt(int(t) / 60) + ":" + (int(t) % 60 < 10 ? "0" : "") + formatInt(int(t) % 60) + "." + formatInt(tenths), c.width - 46, 34, White, AlignRight);
        for (uint i = 0; i < racers.length(); i++)
        {
            // How far along everyone is.
            float part = clamp(float(racers[i].gate) / float(Gates), 0, 1);
            c.circle(c.width - 46 - (1 - part) * 260, 84, racers[i].human ? 9 : 6, racers[i].color);
        }
        c.rect(c.width - 306, 83, 260, 2, Color(1, 1, 1, 0.3f));
        if (clock < 0)
            c.text(big, formatInt(int(ceil(-clock)) > 3 ? 3 : int(ceil(-clock))), c.width * 0.5f, 200, White, AlignCenter);
        else if (clock < 1)
            c.text(big, "Go!", c.width * 0.5f, 200, Color(1, 0.9f, 0.4f, 1 - clock), AlignCenter);
        if (over)
        {
            c.roundRect(c.width * 0.5f - 250, 220, 500, 280, 24, Color(0, 0, 0, 0.72f));
            for (uint i = 0; i < racers.length(); i++)
            {
                int at = place(racers[i]);
                c.text(font, formatInt(at) + "   " + racers[i].name, c.width * 0.5f - 200, 250 + float(at - 1) * 46, racers[i].color);
                c.text(font, racers[i].done > 0 ? formatFloat(racers[i].done, "", 0, 1) : "still going", c.width * 0.5f + 200, 250 + float(at - 1) * 46, White, AlignRight);
            }
            c.text(font, "Accept: again", c.width * 0.5f, 450, Yellow, AlignCenter);
        }
        else if (clock < 4)
            c.text(font, "Left, right: steer     Up, down: faster, slower     Fire: boost", c.width * 0.5f, 676, White, AlignCenter);
    }
}
