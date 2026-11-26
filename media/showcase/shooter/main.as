// Everything that flies is a prefab in scene.json: how it looks, moves and collides, and which class
// below runs it. The engine moves, collides and draws them.

const uint EnemyGroup = 1, PlayerGroup = 0;

ShooterScreen@ game;

class Player : Behaviour
{
    float reload = 0, safe = 2;
    int power = 1;

    void update(float dt)
    {
        Vec2 move = Input::move;
        entity.position += move * 420 * dt;
        entity.position = Vec2(clamp(entity.x, 60, 1220), clamp(entity.y, 120, 670));
        entity.rotation = lerp(entity.rotation, move.x * 14, 0.2f);
        safe -= dt;
        entity.alpha = safe > 0 && sin(App::time * 30) > 0 ? 0.3f : 1.0f;

        reload -= dt;
        if (Input::held("fire") && reload <= 0)
        {
            reload = 0.13f;
            game.shotSound.play(0.25f, (entity.x - 640) / 800);
            for (int i = 0; i < power; i++)
            {
                float side = float(i) - float(power - 1) / 2;
                Entity@ s = Scene::spawn("shot", entity.position + Vec2(side * 22, -44));
                s.velocity = Vec2(side * 60, -900);
                s.rotation = side * 4;
            }
        }
    }

    void onHit(Entity@ other)
    {
        if (cast<PowerUp>(other.behaviour) !is null)
        {
            other.destroy();
            power = power < 5 ? power + 1 : 5;
            game.score += 250;
            game.coinSound.play(0.6f);
            Scene::burst("pickup", entity.position, 24);
        }
        else if (safe <= 0)
        {
            Scene::burst("fire", entity.position, 60);
            game.boomSound.play(0.9f);
            Input::rumbleMotors(1, 0.7f, 0.6f);
            entity.destroy();
            game.lost();
        }
    }
}

class Shot : Behaviour
{
    void onHit(Entity@ other)
    {
        Enemy@ enemy = cast<Enemy>(other.behaviour);
        if (enemy is null) return;
        enemy.hurt(1);
        Scene::burst("spark", entity.position, 5);
        entity.destroy();
    }
}

class Enemy : Behaviour
{
    int health = 2;
    int worth = 100;
    float t = random(0, 6);
    float reload = random(1, 3);
    float from = 0;

    void start() { from = entity.x; }

    void update(float dt)
    {
        t += dt;
        think(dt);
        Color c = entity.color;
        entity.color = Color(1, lerp(c.g, 1, 0.15f), lerp(c.b, 1, 0.15f));
        if (entity.y > 780) entity.destroy();
    }

    // Drifts down in curves, and shoots at the player now and then.
    void think(float dt)
    {
        entity.x = from + sin(t * 1.6f) * 110;
        entity.rotation = cos(t * 1.6f) * 12;
        reload -= dt;
        if (reload <= 0 && entity.y > 60)
        {
            reload = random(1.4f, 3);
            aim(entity.position + Vec2(0, 30), 300, 0);
        }
    }

    void aim(const Vec2 &in at, float speed, float turn)
    {
        Entity@ p = Scene::find("player");
        Vec2 way = p is null ? Vec2(0, 1) : p.position - at;
        float angle = atan2(way.y, way.x) + turn;
        Entity@ b = Scene::spawn("bullet", at);
        b.velocity = Vec2(cos(angle), sin(angle)) * speed;
        b.rotation = angle * 57.3f + 90;
    }

    void hurt(int by)
    {
        health -= by;
        entity.color = Color(1, 0.3f, 0.3f);
        if (health > 0 || !entity.alive) return;
        game.score += worth;
        game.shake = worth > 500 ? 1.0f : 0.25f;
        // A thud for a big one, a tap for the rest.
        if (worth > 500) Input::rumbleMotors(1, 0.5f, 0.7f);
        else Input::rumbleMotors(0, 0.35f, 0.07f);
        game.boomSound.play(worth > 500 ? 1.0f : 0.35f, (entity.x - 640) / 800, random(0.9f, 1.2f));
        Scene::burst("fire", entity.position, worth > 500 ? 200 : 26);
        Scene::burst("smoke", entity.position, worth > 500 ? 40 : 6);
        if (random() < 0.14f || worth > 500) Scene::spawn("power", entity.position);
        entity.destroy();
    }
}

class Diver : Enemy
{
    Diver() { health = 1; worth = 150; }
    void think(float dt) { entity.x += sin(t * 3) * 2; }
}

class Boss : Enemy
{
    Boss() { health = 70; worth = 3000; }

    void think(float dt)
    {
        entity.x = 640 + sin(t * 0.7f) * 380;
        entity.y = lerp(entity.y, 190, 0.02f);
        entity.velocity = Vec2();
        reload -= dt;
        if (reload <= 0)
        {
            reload = health < 30 ? 0.7f : 1.1f;
            for (int i = -3; i <= 3; i++) aim(entity.position + Vec2(0, 60), 340, float(i) * 0.2f);
        }
    }
}

class PowerUp : Behaviour {}

class ShooterScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ big = Assets::font("global:freesans.sfn", 64);
    Texture@ nebula = Assets::texture("asset:nebula.png");
    Texture@ stars = Assets::texture("asset:stars.png");
    Sound@ shotSound = Assets::sound("global:sound/pop.wav");
    Sound@ boomSound = Assets::sound("global:sound/boom.wav");
    Sound@ coinSound = Assets::sound("global:sound/coin.wav");
    Sound@ winSound = Assets::sound("global:sound/win.wav");
    Sound@ loseSound = Assets::sound("global:sound/lose.wav");

    int score = 0, best = 0, lives = 3, wave = 0;
    float shake = 0, scroll = 0;
    bool over = false;
    string banner;
    Tween bannerIn;

    void onEnter()
    {
        @game = this;
        best = int(parseInt(Save::get("shooter.best", "0")));
        Scene::load("asset:scene.json");
        start(Coroutine(this.play));
    }

    void onExit() { @game = null; }

    void say(const string &in text)
    {
        banner = text;
        bannerIn = Tween(0, 1, 0.5f, EaseOvershoot);
    }

    void play()
    {
        Scene::spawn("player", Vec2(640, 600));
        while (true)
        {
            wave++;
            say("Wave " + formatInt(wave));
            wait(1.4f);
            banner = "";
            for (int i = 0; i < 4 + wave * 2; i++)
            {
                Scene::spawn(i % 3 == 2 ? "diver" : "enemy", Vec2(random(160, 1120), -60));
                wait(clamp(0.9f - float(wave) * 0.06f, 0.35f, 1));
            }
            if (wave % 3 == 0)
            {
                say("Here it comes");
                Scene::spawn("boss", Vec2(640, -120));
                wait(1.5f);
                banner = "";
            }
            while (Scene::countIn(EnemyGroup) > 0) nextUpdate();
            winSound.play(0.4f);
            wait(0.6f);
        }
    }

    void lost()
    {
        lives--;
        shake = 1;
        if (lives > 0) start(Coroutine(this.again));
        else
        {
            over = true;
            loseSound.play(0.9f);
            say("Game over");
            if (score > best) Save::set("shooter.best", formatInt(score));
        }
    }

    void again()
    {
        wait(1.2f);
        Scene::spawn("player", Vec2(640, 600));
    }

    void update(float dt)
    {
        scroll += dt;
        shake = clamp(shake - dt * 2, 0, 1);
        if (over && Input::pressed("accept")) Screens::replace("shooter");
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.tile(nebula, 0, 0, 1280, 720, 1280, 1280, 0, scroll * 12);
        c.tile(stars, 0, 0, 1280, 720, 1024, 1024, 0, scroll * 40);
        Scene::camera(Vec2(640 + random(-1, 1) * shake * 14, 360 + random(-1, 1) * shake * 14));
        Scene::draw(c);
        c.text(font, "Score " + formatInt(score), 30, 20);
        c.text(font, "Best " + formatInt(score > best ? score : best), 640, 20, Gray, AlignCenter);
        c.text(font, "Ships " + formatInt(lives), 1250, 20, White, AlignRight);
        if (banner != "")
        {
            c.push();
            c.translate(640, 300);
            c.scale(bannerIn.value, bannerIn.value);
            c.text(big, banner, 0, -40, White, AlignCenter);
            if (over) c.text(font, "Accept to play again", 0, 50, Yellow, AlignCenter);
            c.pop();
        }
    }
}
