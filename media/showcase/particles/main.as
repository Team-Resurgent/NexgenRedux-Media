// Kinds of particles are described in scene.json. An emitter makes them steadily; a burst, at once.

class ParticlesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 40);
    Sound@ boom = Assets::sound("global:sound/boom.wav");
    array<string> names = { "Campfire", "Fountain", "Snow", "Fireworks", "Galaxy" };
    uint chosen = 0;
    array<Entity@> emitters;
    float next = 0, t = 0;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        choose(0);
    }

    void choose(uint which)
    {
        chosen = which;
        for (uint i = 0; i < emitters.length(); i++) emitters[i].destroy();
        emitters.resize(0);
        Scene::setGravity(Vec2(0, 600));
        if (which == 0)
        {
            emitters.insertLast(Scene::spawn("campfire", Vec2(640, 560)));
            emitters.insertLast(Scene::spawn("smoke", Vec2(640, 500)));
            emitters.insertLast(Scene::spawn("embers", Vec2(640, 560)));
        }
        else if (which == 1) emitters.insertLast(Scene::spawn("fountain", Vec2(640, 610)));
        else if (which == 2)
            for (int i = 0; i < 12; i++) emitters.insertLast(Scene::spawn("snow", Vec2(60 + float(i) * 110, -20)));
        else if (which == 4)
            for (int i = 0; i < 5; i++) emitters.insertLast(Scene::spawn("star", Vec2(640, 360)));
    }

    void update(float dt)
    {
        t += dt;
        if (Input::pressed("right")) choose((chosen + 1) % names.length());
        if (Input::pressed("left")) choose((chosen + names.length() - 1) % names.length());
        if (chosen == 1) emitters[0].x = 640 + sin(t) * 200;
        if (chosen == 3)
        {
            next -= dt;
            if (next <= 0)
            {
                next = random(0.3f, 0.9f);
                Vec2 at(random(200, 1080), random(120, 400));
                array<string> kinds = { "red", "green", "gold" };
                Scene::burst(kinds[randomInt(0, 2)], at, 120);
                boom.play(0.25f, (at.x - 640) / 640, random(1.2f, 1.8f));
            }
        }
        if (chosen == 4)
            for (uint i = 0; i < emitters.length(); i++)
            {
                float a = t * 1.2f + float(i) * 1.2566f, r = 60 + 130 * (1 + sin(t * 0.5f));
                emitters[i].position = Vec2(640 + cos(a) * r * 1.5f, 360 + sin(a) * r);
            }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.02f, 0.02f, 0.06f), Color(0.06f, 0.05f, 0.1f));
        if (chosen < 3) c.rect(0, 620, 1280, 100, chosen == 2 ? Color(0.75f, 0.8f, 0.9f) : Color(0.08f, 0.09f, 0.1f));
        if (chosen == 0)
        {
            c.setBlend(BlendAdd);
            c.glow(640, 560, 320 + sin(t * 12) * 14, Color(1, 0.5f, 0.15f, 0.25f));
            c.setBlend(BlendAlpha);
            for (int i = 0; i < 3; i++) c.line(580 + float(i) * 20, 625, 660 + float(i) * 15, 600, 14, Color(0.25f, 0.15f, 0.1f));
        }
        Scene::draw(c);
        c.text(big, names[chosen], 640, 30, White, AlignCenter);
        c.text(font, formatInt(Scene::particles()) + " particles in " + formatInt(App::draws()) + " draws", 640, 84, Gray, AlignCenter);
        c.text(font, "Left and right: another", 1250, 684, Yellow, AlignRight);
    }
}
