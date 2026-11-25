// A menu in three dimensions, from models made in Blender: a chamber, a machine in the middle of it and
// an arm for each choice. Everything is drawn by adding light.

class DashboardScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 40);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ open = Assets::sound("global:sound/accept.wav");
    Sound@ back = Assets::sound("global:sound/back.wav");
    Sound@ sweep = Assets::sound("global:sound/whoosh.wav");
    Texture@ wall = Assets::texture("asset:cellwall.png");
    Texture@ disc = Assets::texture("asset:disc.png");
    Model@ cellModel = Assets::model("asset:cell.glb");
    Model@ coreModel = Assets::model("asset:core.glb");
    Model@ pictureModel = Assets::model("asset:picture.glb");
    Model@ ringModel = Assets::model("asset:ring.glb");
    Model@ armModel = Assets::model("asset:arm.glb");
    Model@ podModel = Assets::model("asset:pod.glb");
    Model@ labelModel = Assets::model("asset:label.glb");
    Model@ badgeModel = Assets::model("asset:badge.glb");
    Model@ selectModel = Assets::model("asset:select.glb");

    array<string> items = { "Memory", "Music", "Settings", "System" };
    array<int> readings = { -1, -1, -1 };       // of the console: processor, board, fan
    uint driveSize = 0, driveFree = 0;
    float read = 0;

    string degrees(int value) { return value < 0 ? "-" : formatInt(value) + " C"; }

    void readConsole(float dt)
    {
        read -= dt;
        if (read > 0 || !Xbox::available)
            return;
        read = 1;
        readings = { Xbox::cpuTemperature, Xbox::boardTemperature, Xbox::fan };
        driveSize = Xbox::driveSize("E");
        driveFree = Xbox::driveFree("E");
    }
    array<float> hues = { 0.31f, 0.58f, 0.08f, 0.78f };
    Entity@ cell;
    Entity@ root;
    Entity@ core;
    Entity@ ring;
    Entity@ picture;
    array<Entity@> arms;
    array<Entity@> pods;
    array<Entity@> labels;
    array<Entity@> others;
    int chosen = 1;
    float turn = 0;
    float at = 1;             // chosen, smoothly
    float inside = 0;         // 0 at the menu, 1 looking at what was opened
    bool opened = false;
    uint hue = 0;
    float tint = 0.31f;
    float arrive = 0;         // 0 to 1 as it opens
    float wide = 1280;        // of the screen
    float flash = 0;
    array<Entity@> haze;
    array<Vec3> hazeAt;
    array<Entity@> dust;
    array<Vec3> dustAt;
    array<Entity@> sparks;
    Entity@ heart;
    Entity@ halo;

    void onEnter()
    {
        Space::shadows(0);
        // What is added to the picture fades into the dark with distance.
        Space::fog(Black, 34, 112);
        Space::farthest(150);
        Space::sun(Vec3(-0.3f, 0.25f, 1), Color(0.85f, 0.85f, 0.85f));
        Space::ambient(Color(0.2f, 0.2f, 0.2f), Color(0.1f, 0.1f, 0.1f));

        @cell = part(cellModel, null, Vec3(0, 0, 0));
        cell.skin(wall, true);
        cell.glowing = 1;
        @root = Space::spawn(Vec3(-10.3f, 3.85f, 0));
        root.angles = Vec3(3.7f, -3.8f, 0);
        @core = part(coreModel, root, Vec3(0, 0, 0));
        @picture = part(pictureModel, root, Vec3(0, 0, 0));
        picture.skin(disc);
        picture.glowing = 1;
        picture.blend = BlendNone;
        @ring = part(ringModel, root, Vec3(0, 0, 0));
        for (uint i = 0; i < items.length(); i++)
        {
            Entity@ arm = part(armModel, root, Vec3(0, 0, 0));
            arms.insertLast(arm);
            Entity@ pod = part(podModel, arm, Vec3(12.35f, 0.02f, 0.51f));
            pods.insertLast(pod);
            labels.insertLast(part(labelModel, pod, Vec3(0, 0, 0)));
            Entity@ badge = part(badgeModel, pod, Vec3(0, 0, 0));
            badge.skin(disc);
            badge.glowing = 1;
            badge.blend = BlendNone;
            others.insertLast(arm);
            others.insertLast(pod);
        }
        // Mist: large, faint and soft, drifting in front of the far wall.
        for (int i = 0; i < 16; i++)
        {
            float a = float(i) * 2.4f;
            hazeAt.insertLast(Vec3(sin(a) * (14 + float(i) * 1.6f), cos(a * 1.3f) * 13, -34 + float(i) * 2.2f));
            haze.insertLast(light(22 + float(i % 4) * 7));
        }
        for (int i = 0; i < 44; i++)
        {
            dustAt.insertLast(Vec3(random(-30, 30), random(-18, 18), random(-22, 18)));
            dust.insertLast(light(random(0.14f, 0.36f)));
        }
        for (int i = 0; i < 18; i++)
        {
            sparks.insertLast(light(1.6f - float(i % 6) * 0.22f));
            sparks[i].attach(root);
        }
        @heart = light(26);
        heart.attach(root);
        @halo = light(7);
        others.insertLast(part(selectModel, null, Vec3(0, 0, 0)));
        others.insertLast(core);
        others.insertLast(ring);
    }

    Entity@ light(float size)
    {
        Entity@ e = Space::spawn(Vec3(0, 0, 0));
        e.glow(size, Black);
        return e;
    }

    Entity@ part(Model@ model, Entity@ parent, const Vec3 &in place)
    {
        Entity@ e = Space::spawn(place);
        e.model(model);
        e.blend = BlendAdd;
        e.twoSided = true;
        e.shadow = false;
        if (parent !is null)
            e.attach(parent);
        return e;
    }

    void update(float dt)
    {
        readConsole(dt);
        int before = chosen;
        if (!opened && Input::repeated("down") && chosen + 1 < int(items.length()))
            chosen++;
        if (!opened && Input::repeated("up") && chosen > 0)
            chosen--;
        if (chosen != before)
        {
            move.play(0.7f);
            flash = 1;
        }
        arrive = clamp(arrive + dt * 0.45f, 0, 1);
        flash = clamp(flash - dt * 2.2f, 0, 1);
        if (!opened && Input::pressed("accept"))
        {
            flash = 1;
            opened = true;
            open.play(0.7f);
            sweep.play(0.5f, 0, 0.8f);
        }
        else if (opened && Input::pressed("cancel"))
        {
            opened = false;
            back.play(0.7f);
        }
        if (Input::pressed("alternate"))
        {
            hue = (hue + 1) % hues.length();
            move.play(0.7f, 0, 1.3f);
        }
        tint += (hues[hue] - tint) * clamp(dt * 3, 0, 1);
        at += (float(chosen) - at) * clamp(dt * 8, 0, 1);
        inside = clamp(inside + (opened ? dt : -dt) * 1.6f, 0, 1);
        turn += dt;

        Color dim = hsv(tint, 1, 0.14f);
        Color bright = hsv(tint, 0.85f, 0.5f);
        float pulse = 0.75f + sin(turn * 4) * 0.25f;
        cell.angles = Vec3(0, sin(turn * 0.022f * 6) * 45, 0);
        cell.color = hsv(tint, 1, 0.5f + flash * 0.12f);
        float come = smooth(arrive);
        mist(dt, come, pulse);
        core.angles = Vec3(0, 0, sin(turn * 0.4f) * 4);
        ring.angles = Vec3(0, 0, at * 18 + (1 - come) * 200);
        for (uint i = 0; i < others.length(); i++)
            others[i].color = dim;
        for (uint i = 0; i < arms.length(); i++)
        {
            // They fan out as it opens.
            float angle = (at - float(i)) * 18 * come - (1 - come) * 70;
            arms[i].angles = Vec3(0, 0, angle);
            pods[i].angles = Vec3(0, 0, -angle);
            bool here = int(i) == chosen;
            labels[i].color = here ? lerp(hsv(tint, 0.8f, 0.85f + pulse * 0.1f), White, flash * 0.5f) : hsv(tint, 0.9f, 0.22f);
            labels[i].glowing = here ? 0.7f : 0.2f;
            labels[i].alpha = 1 - inside;
        }
        picture.color = Color(0.9f + pulse * 0.1f, 0.9f + pulse * 0.1f, 1);

        // Inwards, towards what was chosen.
        float t = smooth(inside);
        // Farther back on a square screen, so that the labels fit.
        float back = wide < 1240 ? 30 * 1280 / wide : 30.0f;
        Vec3 from = lerp(Vec3(sin(turn * 0.3f) * 0.9f, sin(turn * 0.23f) * 0.6f, back + (1 - come) * (54 - back)), Vec3(6, 1.5f, 14), t);
        Vec3 to = lerp(Vec3(0, 0, 0), Vec3(7, 1, 0), t);
        Space::camera(from, to, 75);
    }

    void mist(float dt, float come, float pulse)
    {
        for (uint i = 0; i < haze.length(); i++)
        {
            float k = float(i);
            haze[i].place = hazeAt[i] + Vec3(sin(turn * 0.11f + k) * 5, sin(turn * 0.09f + k * 1.7f) * 3, sin(turn * 0.07f + k * 2.3f) * 3);
            haze[i].color = hsv(tint + sin(k) * 0.025f, 0.95f, (0.055f + 0.03f * sin(turn * 0.4f + k * 1.9f)) * come);
        }
        for (uint i = 0; i < dust.length(); i++)
        {
            Vec3 p = dustAt[i];
            p.y += dt * (0.25f + float(i % 5) * 0.12f);
            p.x += sin(turn * 0.5f + float(i)) * dt * 0.4f;
            if (p.y > 18)
                p.y = -18;
            dustAt[i] = p;
            dust[i].place = p;
            float shine = 0.5f + 0.5f * sin(turn * (1 + float(i % 7) * 0.2f) + float(i) * 2);
            dust[i].color = hsv(tint, 0.6f, 0.6f * shine * come);
        }
        // Energy, running round the ring in three trains.
        for (uint i = 0; i < sparks.length(); i++)
        {
            float a = turn * (1.1f + float(i / 6) * 0.15f) + float(i / 6) * 2.094f - float(i % 6) * 0.07f;
            sparks[i].place = Vec3(sin(a) * 12.9f, cos(a) * 12.9f, -0.9f);
            sparks[i].color = hsv(tint, 0.55f, (0.75f - float(i % 6) * 0.11f) * come);
        }
        heart.place = Vec3(0, 0, -3);
        heart.color = hsv(tint, 0.85f, (0.2f + pulse * 0.1f + flash * 0.25f) * come);
        // Behind the orb that is chosen.
        Vec3 wanted = pods[uint(chosen)].toSpace(Vec3(0.08f, -1.42f, 5.2f));
        halo.place = lerp(halo.place, wanted, clamp(dt * 12, 0, 1));
        float size = 6.5f + pulse * 1.2f + flash * 3;
        halo.size = Vec3(size, size, size);
        halo.color = hsv(tint, 0.5f, (0.5f + flash * 0.4f) * come * (1 - inside));
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        wide = c.width;
        Space::draw(c);
        c.bloom(0.22f, 0.75f);
        // Darker towards the edges.
        for (int i = 0; i < 2; i++)
        {
            float y = i == 0 ? 0.0f : 560.0f;
            c.gradient(0, y, wide, 160, i == 0 ? Color(0, 0, 0, 0.55f) : Color(0, 0, 0, 0), i == 0 ? Color(0, 0, 0, 0) : Color(0, 0, 0, 0.6f));
        }
        float menu = (1 - smooth(clamp(inside * 2, 0, 1))) * smooth(clamp(arrive * 3 - 2, 0, 1));
        for (uint i = 0; i < pods.length(); i++)
        {
            // Along the panel that each arm holds out, in the middle of it and at its angle.
            Vec2 a, b;
            if (menu > 0 && Space::toScreen(pods[i].toSpace(Vec3(4.1f, -2.48f, 7.3f)), a) && Space::toScreen(pods[i].toSpace(Vec3(16, -2.48f, 7.3f)), b))
            {
                c.push();
                c.translate(a.x, a.y);
                c.rotate(atan2(b.y - a.y, b.x - a.x) * 57.2958f);
                c.text(font, items[i], 0, -font.measure(items[i]).y * 0.5f, fade(int(i) == chosen ? Color(0.02f, 0.06f, 0.02f) : White, menu));
                c.pop();
            }
        }
        c.alpha = menu;
        c.text(font, "Up, down: choose     Accept: open     Alternate: colour", wide * 0.5f, 672, hsv(tint, 0.3f, 0.7f), AlignCenter);
        float page = smooth(clamp(inside * 2 - 1, 0, 1));
        if (page > 0)
        {
            c.alpha = page;
            float x = wide - 860 + (1 - page) * 120;
            c.roundRect(x, 130, 760, 440, 26, Color(0, 0, 0, 0.86f));
            Color edge = hsv(tint, 0.8f, 0.8f);
            c.rect(x + 36, 206, 688, 3, edge);
            c.text(big, items[chosen], x + 36, 148, hsv(tint, 0.25f, 1));
            array<string> names;
            array<string> values;
            float bar = -1;
            if (chosen == 0)
            {
                names = { "Used by the engine", "Used by scripts", "Left on this machine" };
                values = { formatInt(int(App::memoryKilobytes)) + " KB", formatInt(int(App::scriptKilobytes)) + " KB", formatInt(int(App::freeKilobytes / 1024)) + " MB" };
            }
            else if (chosen == 1)
            {
                names = { "Now playing", "Voices" };
                values = { "Nothing: it is quiet here", "32 at once" };
                bar = 0;
            }
            else if (chosen == 2)
            {
                names = { "Colour", "Screen", "Controls" };
                values = { formatInt(int(hue + 1)) + " of 4", formatInt(int(c.width)) + " x " + formatInt(int(c.height)), Input::usingPad ? "Gamepad" : "Keyboard" };
            }
            else
            {
                // An original Xbox can say more about itself than the rest.
                names = { "Platform", "Graphics", "Speed", "Triangles", "Network" };
                values = { App::platform, App::gpu, formatInt(int(App::fps + 0.5f)) + " frames a second", formatInt(int(Space::triangles)), Net::address == "" ? "Not connected" : Net::address };
                if (Xbox::available)
                {
                    names = { "Kernel", "Processor", "Board", "Fan", "Drive E", "Network" };
                    values = { Xbox::text(XboxKernel) + ", " + Xbox::text(XboxHardware), degrees(readings[0]), degrees(readings[1]), readings[2] < 0 ? "-" : formatInt(readings[2]) + "%",
                        formatInt(int(driveFree)) + " of " + formatInt(int(driveSize)) + " MB free", Net::address == "" ? "Not connected" : Net::address };
                }
            }
            for (uint i = 0; i < names.length(); i++)
            {
                c.text(font, names[i], x + 40, 240 + float(i) * 56, Color(0.7f, 0.75f, 0.72f));
                c.text(font, values[i], x + 720, 240 + float(i) * 56, White, AlignRight);
            }
            if (bar >= 0)
                for (int i = 0; i < 24; i++)
                    c.roundRect(x + 40 + float(i) * 28.5f, 520 - 14, 18, 14 + 50 * (0.5f + 0.5f * sin(turn * 3 + float(i) * 0.7f) * sin(turn * 1.7f + float(i))), 4, fade(edge, 0.8f));
            c.text(font, "Cancel: back", x + 380, 586, hsv(tint, 0.3f, 0.7f), AlignCenter);
        }
        c.alpha = 1;
    }
}
