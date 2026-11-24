// The level is rows of letters in scene.json. Solid bodies stop at its tiles; ledges only from above.

PlatformerScreen@ game;

class Hero : Behaviour
{
    float grace = 0, early = 0, squash = 0;
    bool wasDown = true;
    Vec2 spawned;
    Entity@ eyes;

    void start()
    {
        spawned = entity.position;
        @eyes = Scene::spawn(Vec2(6, -8));
        eyes.rect(10, 8, White);
        eyes.layer = 6;
        eyes.attach(entity);
    }

    void update(float dt)
    {
        float move = Input::move().x;
        Vec2 v = entity.velocity;
        v.x = lerp(v.x, move * 290, entity.onGround ? 0.2f : 0.1f);
        // Jumping still works just after leaving a ledge, and just before landing.
        grace = entity.onGround ? 0.1f : grace - dt;
        early = Input::pressed("accept") ? 0.12f : early - dt;
        if (early > 0 && grace > 0)
        {
            v.y = -640;
            grace = early = 0;
            squash = -0.3f;
            game.jump.play(0.4f);
        }
        if (early > 0 && entity.onWall != 0 && !entity.onGround)
        {
            v = Vec2(-float(entity.onWall) * 380, -560);
            early = 0;
            game.jump.play(0.4f, 0, 1.2f);
        }
        if (!Input::held("accept") && v.y < -220) v.y = -220;    // a short press is a short jump
        if (entity.onWall != 0 && v.y > 120) v.y = 120;          // sliding down a wall
        entity.velocity = v;

        if (entity.onGround && !wasDown)
        {
            squash = 0.3f;
            Scene::burst("dust", entity.position + Vec2(0, 18), 8);
        }
        wasDown = entity.onGround;
        squash = lerp(squash, 0, 0.18f);
        entity.scale = Vec2(1 + squash, 1 - squash);
        if (move != 0) eyes.position = Vec2(move > 0 ? 6.0f : -6.0f, -8);
        if (entity.y > Scene::mapSize().y + 100) hurt();
    }

    void hurt()
    {
        game.lose.play(0.5f);
        Scene::burst("poof", entity.position, 30);
        entity.position = spawned;
        entity.velocity = Vec2();
    }

    void onHit(Entity@ other)
    {
        Walker@ walker = cast<Walker>(other.behaviour);
        if (other.name == "coin")
        {
            game.coins++;
            game.coin.play(0.5f, 0, 1 + float(game.coins % 8) * 0.05f);
            Scene::burst("shine", other.position, 10);
            other.destroy();
        }
        else if (other.name == "goal") game.won();
        else if (walker !is null)
        {
            if (entity.velocity.y > 60 && entity.y < other.y - 8)
            {
                Scene::burst("poof", other.position, 20);
                game.stomp.play(0.6f);
                other.destroy();
                entity.velocity = Vec2(entity.velocity.x, -420);
            }
            else hurt();
        }
        else hurt();   // spikes
    }
}

class Walker : Behaviour
{
    float way = -70;
    void update(float dt)
    {
        if (entity.onWall != 0) way = entity.onWall > 0 ? -70.0f : 70.0f;
        // Turns back at an edge.
        if (entity.onGround && Scene::tile(entity.position + Vec2(way > 0 ? 18.0f : -18.0f, 26)) == 0) way = -way;
        entity.velocity = Vec2(way, entity.velocity.y);
        entity.rotation = sin(App::time() * 8) * 6;
    }
}

class Spin : Behaviour
{
    float t = random(0, 6);
    void update(float dt)
    {
        t += dt;
        entity.scale = Vec2(cos(t * 4), 1);
    }
}

class PlatformerScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 64);
    Sound@ jump = Assets::sound("global:sound/whoosh.wav");
    Sound@ coin = Assets::sound("global:sound/coin.wav");
    Sound@ stomp = Assets::sound("global:sound/hit.wav");
    Sound@ lose = Assets::sound("global:sound/lose.wav");
    Sound@ win = Assets::sound("global:sound/win.wav");
    int coins = 0;
    bool done = false;
    float t = 0;
    Vec2 camera;

    void onEnter()
    {
        @game = this;
        Scene::load("asset:scene.json");
        camera = Scene::find("hero").position;
    }
    void onExit() { @game = null; }

    void won()
    {
        if (done) return;
        done = true;
        win.play(0.8f);
        Scene::burst("shine", Scene::find("hero").position, 80);
    }

    void update(float dt)
    {
        if (!done) t += dt;
        else if (Input::pressed("accept")) Screens::replace("platformer");
        Entity@ hero = Scene::find("hero");
        Vec2 size = Scene::mapSize();
        Vec2 want = Vec2(clamp(hero.x + hero.velocity.x * 0.35f, 640 / 1.4f, size.x - 640 / 1.4f), clamp(hero.y - 30, -1000, size.y - 360 / 1.4f));
        camera = camera + (want - camera) * 0.08f;
    }

    void hills(Canvas@ c, float depth, float base, float size, const Color &in color)
    {
        for (int i = -1; i < 9; i++)
        {
            float x = float(i) * size * 1.3f - camera.x * depth % (size * 1.3f);
            c.circle(x, base + size * 0.45f, size, color);
        }
        c.rect(0, base + size * 0.4f, 1280, 720, color);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.35f, 0.6f, 0.95f), Color(0.8f, 0.9f, 1));
        c.circle(1050, 130, 60, Color(1, 0.95f, 0.7f));
        hills(c, 0.1f, 430, 200, Color(0.55f, 0.75f, 0.85f));
        hills(c, 0.25f, 540, 150, Color(0.4f, 0.68f, 0.6f));
        Scene::camera(camera, 1.4f);
        Scene::draw(c);
        c.roundRect(20, 16, 330, 44, 10, Color(0, 0, 0, 0.35f));
        c.text(font, "Coins " + formatInt(coins) + "    " + formatFloat(t, "", 0, 1) + " s", 40, 22);
        if (done)
        {
            c.rect(0, 280, 1280, 160, Color(0, 0, 0, 0.5f));
            c.text(big, "You made it!", 640, 290, White, AlignCenter);
            c.text(font, "Accept to run it again", 640, 380, Yellow, AlignCenter);
        }
    }
}
