// A small game made from two scenes, as the scene editor saves them: the village, where a key opens the ring,
// and the island beyond it, with crystals to gather. The scenes say what is where, which triggers do what,
// and what the HUD shows; this script only walks, follows, and keeps the score.
#include "global:scene.as"

// Turns, and bobs a little.
class Spin : Behaviour
{
    Vec3 home;
    float at = 0;

    void start()
    {
        home = entity.place;
        at = random(0, 6);
    }

    void update(float dt)
    {
        at += dt;
        entity.place = home + Vec3(0, sin(at * 2) * 0.15f, 0);
        entity.turn(Vec3(0, 1, 0), 80 * dt);
    }
}

class QuestScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 48);
    Sound@ chime = Assets::sound("global:sound/coin.wav");
    Sound@ gate = Assets::sound("global:sound/gate.wav");
    Sound@ jump = Assets::sound("global:sound/whoosh.wav");
    Sound@ step = Assets::sound("global:sound/step.wav");
    Model@ robot = Assets::model("global:model/robot.glb");

    Level level;
    Entity@ hero;
    string scene;
    // What has been taken, in any scene, so that it stays gone when you come back.
    array<string> taken;
    bool hasKey = false;
    int crystals = 0;
    int total = 5;
    float time = 0, shown = 0, strode = 0, sinceArrived = 0;
    float fade = 1;              // black over everything, after going through
    bool won = false;
    float yaw = 0, lean = 0.3f;
    Vec3 look;
    Vec2 mouseWas;
    bool wasDown = false;

    void onEnter()
    {
        Scene::load("asset:effects.json");
        @level.onTouch = LevelTouch(this.touched);
        go("village", "start");
    }

    void onExit()
    {
        level.clear();
    }

    // A scene, from its arrival.
    void go(const string &in name, const string &in arrive)
    {
        if (hero !is null)
            hero.destroy();
        scene = name;
        level.load("asset:" + name + ".json");
        // What was taken before stays taken.
        for (uint i = 0; i < taken.length(); i++)
        {
            level.hide(taken[i], 0);
            level.switchOn("get " + taken[i], false);
        }
        if (hasKey && name == "village")
        {
            level.switchOn("locked", false);
            level.switchOn("through", true);
            level.show("portal", 0);
        }
        level.set("crystals", crystals + " of " + total);
        level.set("key", hasKey ? "yes" : "not yet");

        Vec3 at(0, 0, 0);
        float turned = 0;
        level.arrival(arrive, at, turned);
        @hero = Space::spawn(at + Vec3(0, 0.3f, 0));
        hero.model(robot);
        hero.capsule(0.35f, 1.6f, 1);
        hero.colliderAt = Vec3(0, 0.8f, 0);
        hero.walker = true;
        hero.mass = 60;
        hero.shine = 0.5f;
        hero.angles = Vec3(0, turned + 180, 0);
        yaw = turned * 0.0174533f;
        look = hero.place + Vec3(0, 1.4f, 0);
        fade = 1;
        sinceArrived = scene == "village" && !hasKey ? 0.0f : 5.0f;
    }

    // What the scenes' triggers tell the game.
    void touched(const string &in name, Entity@ who)
    {
        if (name == "get key")
        {
            hasKey = true;
            taken.insertLast("key");
            level.set("key", "yes");
            level.switchOn("locked", false);
            level.switchOn("through", true);
            level.show("portal", 1.2f, "grow");
            gate.play(0.8f);
            Space::burst("gold", who.place + Vec3(0, 1, 0), 40);
        }
        else if (name.findFirst("get c") == 0)
        {
            crystals++;
            taken.insertLast(name.substr(4));
            level.set("crystals", crystals + " of " + total);
            chime.play(0.7f);
            Space::burst("shard", who.place + Vec3(0, 1, 0), 40);
            if (crystals == total)
            {
                won = true;
                level.say("All five, in " + clock(time), 6);
            }
            else
                level.say(crystals + " found", 1.5f);
        }
    }

    string clock(float t)
    {
        int s = int(t);
        return (s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60);
    }

    void update(float dt)
    {
        shown += dt;
        sinceArrived += dt;
        fade = clamp(fade - dt * 2, 0, 1);
        if (!won)
            time += dt;
        level.set("time", clock(time));
        walk(dt);
        follow(dt);
        string goes = level.update(dt, hero);
        if (goes != "")
        {
            int bar = goes.findFirst("|");
            go(goes.substr(0, uint(bar)), goes.substr(uint(bar) + 1));
        }
    }

    void walk(float dt)
    {
        Vec2 stick = Input::move;
        Vec3 ahead(-sin(yaw), 0, -cos(yaw));
        Vec3 side(cos(yaw), 0, -sin(yaw));
        Vec3 way = side * stick.x - ahead * stick.y;
        Vec3 wanted = way * 6;
        Vec3 motion = hero.motion;
        float grip = clamp((hero.onGround ? 12 : 3) * dt, 0, 1);
        motion.x += (wanted.x - motion.x) * grip;
        motion.z += (wanted.z - motion.z) * grip;
        if (Input::pressed("accept") && hero.onGround)
        {
            motion.y = 6.4f;
            jump.play(0.35f);
        }
        hero.motion = motion;
        float going = Vec3(motion.x, 0, motion.z).length();
        strode += going * dt;
        if (strode > (going > 4 ? 1.5f : 0.9f) && hero.onGround)
        {
            strode = 0;
            step.play(0.25f, 0, random(0.85f, 1.15f));
        }
        if (way.length() > 0.1f)
            hero.face(way, clamp(12 * dt, 0, 1));
        hero.animate(!hero.onGround && abs(motion.y) > 1.5f ? "jump" : going > 4 ? "run" : going > 0.5f ? "walk" : "idle");
        hero.animationSpeed = going > 4 ? going / 6 : going > 0.5f ? going / 2.4f : 1;
        // Into the sea, or off the edge: back to where this scene began.
        if (hero.place.y < -8)
        {
            Vec3 at;
            float turned;
            if (level.arrival(scene == "village" ? "start" : "in", at, turned))
                hero.place = at + Vec3(0, 0.5f, 0);
            hero.motion = Vec3();
        }
    }

    void follow(float dt)
    {
        Vec2 turn = Input::padRight(0);
        yaw -= turn.x * 2.4f * dt;
        lean = clamp(lean - turn.y * 1.4f * dt, -0.1f, 1.1f);
        Vec2 mouse = Input::mouse;
        if (Input::mouseDown(1) && wasDown)
        {
            yaw -= (mouse.x - mouseWas.x) * 0.006f;
            lean = clamp(lean + (mouse.y - mouseWas.y) * 0.004f, -0.1f, 1.1f);
        }
        wasDown = Input::mouseDown(1);
        mouseWas = mouse;
        // It swings round behind as you walk.
        Vec3 side(cos(yaw), 0, -sin(yaw));
        yaw -= clamp(hero.motion.dot(side) * 0.1f, -1, 1) * dt * 1.5f;

        look = lerp(look, hero.place + Vec3(0, 1.4f, 0), clamp(9 * dt, 0, 1));
        float away = 6.5f;
        Vec3 back(sin(yaw) * cos(lean), sin(lean), cos(yaw) * cos(lean));
        Vec3 from = look + back * away;
        Vec3 hit, normal;
        if (Space::raycast(look, look + back * (away + 0.4f), hit, normal, (1 << 0) | (1 << 2), hero))
            from = look + back * clamp((hit - look).length() - 0.4f, 1, away);
        float least = Space::height(from.x, from.z) + 0.5f;
        from.y = from.y < least ? least : from.y;
        Space::camera(from, look + Vec3(0, 0.3f, 0), 62);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.35f, 0.8f);
        level.drawHud(c);
        c.designHeight(720);
        if (won)
            c.text(big, "Well done!", c.width * 0.5f, 220, Color(1, 0.9f, 0.4f), AlignCenter);
        float help = clamp(8 - sinceArrived, 0, 1);
        if (help > 0)
        {
            c.alpha = help;
            string goal = scene == "island" ? "Gather the five crystals" : hasKey ? "Go through the stone ring" : "Find the key that opens the stone ring";
            c.roundRect(c.width * 0.5f - 420, 600, 840, 88, 14, Color(0, 0, 0, 0.45f));
            c.text(font, goal, c.width * 0.5f, 610, Color(1, 0.9f, 0.6f), AlignCenter);
            c.text(font, Input::usingPad ? "Left stick: walk    Right stick: look    A: jump" : "Arrows: walk    Right button: look    Space: jump", c.width * 0.5f, 648, White, AlignCenter);
            c.alpha = 1;
        }
        if (fade > 0)
            c.rect(0, 0, c.width, 720, Color(0, 0, 0, fade));
    }
}
