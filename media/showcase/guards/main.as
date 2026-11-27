// Take the gem without being caught. The scene file says who guards, who patrols which route, who runs away and who
// follows; global:ai.as moves them, as the level's crowd: they see what is in front of them and not behind a wall, hear running, chase,
// search where you were last seen, and go back to what they were doing. Ways round the houses come from
// Space::navigate, which the level works out when it is made.
#include "global:scene.as"

class GuardsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 48);
    Sound@ chime = Assets::sound("global:sound/coin.wav");
    Sound@ alarm = Assets::sound("global:sound/gate.wav");
    Sound@ step = Assets::sound("global:sound/step.wav");
    Model@ robot = Assets::model("global:model/robot.glb");

    Level level;
    Entity@ hero;
    bool hasGem = false, won = false;
    int caught = 0;
    float time = 0, shown = 0, strode = 0, fade = 1, shout = 0;
    float yaw = 0, lean = 0.45f;
    Vec3 look;
    Vec2 mouseWas;
    bool wasDown = false, wasShow = false;

    void onEnter()
    {
        Scene::load("asset:effects.json");
        @level.onTouch = LevelTouch(this.touched);
        @level.onAgent = LevelAgent(this.agentDid);
        level.load("asset:yard.json");
        start();
    }

    void onExit()
    {
        level.clear();
    }

    void start()
    {
        if (hero !is null)
            hero.destroy();
        Vec3 at;
        float turned = 0;
        level.arrival("start", at, turned);
        @hero = Space::spawn(at + Vec3(0, 0.3f, 0));
        hero.model(robot);
        hero.color = Color(0.7f, 0.85f, 1);
        hero.capsule(0.35f, 1.6f, 1);
        hero.colliderAt = Vec3(0, 0.8f, 0);
        hero.walker = true;
        hero.mass = 60;
        hero.angles = Vec3(0, turned + 180, 0);
        yaw = turned * 0.0174533f;
        look = hero.place + Vec3(0, 1.4f, 0);
        fade = 1;
        // The little one follows you.
        for (uint i = 0; i < level.agents.length(); i++)
            if (level.agents[i] !is null && level.agents[i].role == "follow")
            {
                @level.agents[i].leader = hero;
                level.agents[i].entity.place = hero.place + Vec3(1.5f, 0.2f, 1.5f);
            }
        level.set("gem", hasGem ? "yours" : "there");
        level.set("caught", "" + caught);
    }

    void touched(const string &in name, Entity@ who)
    {
        if (name == "get gem")
        {
            hasGem = true;
            chime.play(0.7f);
            Space::burst("gold", who.place + Vec3(0, 1, 0), 40);
            level.set("gem", "yours");
        }
        else if (name == "home" && hasGem && !won)
        {
            won = true;
            level.say("You made it, in " + clock(time), 8);
        }
    }

    void agentDid(const string &in name, const string &in what)
    {
        if (what == "spotted" && !won)
        {
            alarm.play(0.5f);
            shout = 1.5f;
        }
        else if (what == "caught" && !won)
        {
            caught++;
            level.say("Caught by the " + name + "!", 2.5f);
            // The gem goes back, and so do you.
            if (hasGem)
            {
                hasGem = false;
                level.show("gem", 0.6f, "rise");
                level.switchOn("get gem", true);
            }
            start();
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
        fade = clamp(fade - dt * 2, 0, 1);
        shout -= dt;
        if (!won)
            time += dt;
        level.set("time", clock(time));
        walk(dt);
        follow(dt);
        level.update(dt, hero);
    }

    void walk(float dt)
    {
        Vec2 stick = Input::move;
        Vec3 ahead(-sin(yaw), 0, -cos(yaw));
        Vec3 side(cos(yaw), 0, -sin(yaw));
        Vec3 way = side * stick.x - ahead * stick.y;
        // Held: creep, and make no sound.
        bool sneaking = Input::held("alternate");
        // How the guards find their way: the left trigger, or C.
        bool show = Input::padTriggers(0).x > 0.5f || Input::key("C");
        if (show && !wasShow)
        {
            Space::showNavigation = !Space::showNavigation;
            Space::showShapes = Space::showNavigation;
        }
        wasShow = show;
        Vec3 wanted = way * (sneaking ? 2.2f : 5.5f);
        Vec3 motion = hero.motion;
        float grip = clamp((hero.onGround ? 12 : 3) * dt, 0, 1);
        motion.x += (wanted.x - motion.x) * grip;
        motion.z += (wanted.z - motion.z) * grip;
        hero.motion = motion;
        float going = Vec3(motion.x, 0, motion.z).length();
        strode += going * dt;
        if (strode > (going > 3 ? 1.5f : 0.9f) && hero.onGround)
        {
            strode = 0;
            step.play(going > 3 ? 0.3f : 0.08f, 0, random(0.85f, 1.15f));
            // Running is heard.
            if (going > 3)
                level.crowd.noise(hero.place, 0.7f);
        }
        if (way.length() > 0.1f)
            hero.face(way, clamp(12 * dt, 0, 1));
        hero.animate(going > 3.2f ? "run" : going > 0.4f ? "walk" : "idle");
        hero.animationSpeed = going > 3.2f ? going / 6 : going > 0.4f ? going / 2.4f : 1;
    }

    void follow(float dt)
    {
        Vec2 turn = Input::padRight(0);
        yaw -= turn.x * 2.4f * dt;
        lean = clamp(lean - turn.y * 1.4f * dt, 0, 1.2f);
        Vec2 mouse = Input::mouse;
        if (Input::mouseDown(1) && wasDown)
        {
            yaw -= (mouse.x - mouseWas.x) * 0.006f;
            lean = clamp(lean + (mouse.y - mouseWas.y) * 0.004f, 0, 1.2f);
        }
        wasDown = Input::mouseDown(1);
        mouseWas = mouse;
        Vec3 side(cos(yaw), 0, -sin(yaw));
        yaw -= clamp(hero.motion.dot(side) * 0.1f, -1, 1) * dt * 1.5f;
        look = lerp(look, hero.place + Vec3(0, 1.4f, 0), clamp(9 * dt, 0, 1));
        float away = 8;
        Vec3 back(sin(yaw) * cos(lean), sin(lean), cos(yaw) * cos(lean));
        Vec3 from = look + back * away;
        // Kept clear of walls and eaves: along its line, and along lines a little to each side of it and above.
        float reach = away;
        for (int i = 0; i < 6; i++)
        {
            Vec3 up(0, 0.8f, 0);
            Vec3 offset = i == 0 ? Vec3() : i == 1 ? side * 0.8f : i == 2 ? side * -0.8f : i == 3 ? up : i == 4 ? side * 0.8f + up : side * -0.8f + up;
            Vec3 hit, normal;
            if (Space::raycast(look + offset, look + offset + back * (away + 0.4f), hit, normal, 0xFFFD, hero))
                reach = min(reach, (hit - look - offset).length() - 0.4f);
        }
        from = look + back * clamp(reach, 1, away);
        float least = Space::height(from.x, from.z) + 0.5f;
        from.y = from.y < least ? least : from.y;
        Space::camera(from, look + Vec3(0, 0.3f, 0), 62);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Space::draw(c);
        c.bloom(0.4f, 0.75f);
        level.crowd.draw(c);
        level.drawHud(c);
        c.designHeight(720);
        if (shout > 0)
            c.text(big, "!", c.width * 0.5f, 90, Color(1, 0.3f, 0.2f, clamp(shout, 0, 1)), AlignCenter);
        if (won)
            c.text(big, "Well done!", c.width * 0.5f, 220, Color(1, 0.9f, 0.4f), AlignCenter);
        float help = clamp(8 - shown, 0, 1);
        if (help > 0)
        {
            c.alpha = help;
            c.roundRect(c.width * 0.5f - 460, 600, 920, 88, 14, Color(0, 0, 0, 0.5f));
            c.text(font, "Take the gem from behind the walls, and bring it back here", c.width * 0.5f, 610, Color(1, 0.9f, 0.6f), AlignCenter);
            c.text(font, Input::usingPad ? "Left stick: walk    Hold B: creep quietly    Right stick: look    Left trigger: how they find their way" : "Arrows: walk    Hold Shift: creep quietly    Right button: look    C: how they find their way", c.width * 0.5f, 648, White, AlignCenter);
            c.alpha = 1;
        }
        if (fade > 0)
            c.rect(0, 0, c.width, 720, Color(0, 0, 0, fade));
    }
}
