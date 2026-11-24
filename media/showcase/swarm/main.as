// Each is an entity with an image, a body and a collider. The engine does all the work in here.

class SwarmScreen : Screen
{
    Texture@ fish = Assets::texture("asset:fish.png");
    Font@ font = Assets::font("global:freesans.sfn", 22);
    array<Entity@> all;
    bool collide = true;
    uint touched = 0;

    void onEnter()
    {
        wall(640, -50, 1480, 100);
        wall(640, 770, 1480, 100);
        wall(-50, 360, 100, 920);
        wall(1330, 360, 100, 920);
        add(300);
    }

    void wall(float x, float y, float w, float h)
    {
        Entity@ e = Scene::spawn(Vec2(x, y));
        e.box(w, h, 1);
        e.wall = true;
    }

    void add(uint count)
    {
        for (uint i = 0; i < count && all.length() < 4000; i++)
        {
            Entity@ e = Scene::spawn(Vec2(random(40, 1240), random(40, 680)));
            e.image(fish, 26, 24);
            e.color = hsv(random(), 0.5f, 1);
            e.velocity = Vec2(random(-150, 150), random(-150, 150));
            e.spin = random(-90, 90);
            e.circle(11, 0, collide ? 1 : 0);
            e.solid = true;
            e.bounce = 1;
            all.insertLast(e);
        }
    }

    void update(float dt)
    {
        if (Input::repeated("up")) add(100);
        if (Input::repeated("down"))
            for (uint i = 0; i < 100 && all.length() > 0; i++)
            {
                all[all.length() - 1].destroy();
                all.removeLast();
            }
        if (Input::pressed("accept"))
        {
            collide = !collide;
            for (uint i = 0; i < all.length(); i++) all[i].hits = collide ? 1 : 0;
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.03f, 0.08f, 0.13f));
        Scene::draw(c);
        c.roundRect(30, 24, 520, 112, 12, Color(0, 0, 0, 0.7f));
        c.text(font, formatInt(all.length()) + " entities in " + formatInt(App::draws) + " draws", 50, 34);
        c.text(font, formatInt(Scene::pairs) + " pairs compared, collision " + (collide ? "on" : "off"), 50, 64, collide ? Green : Gray);
        c.text(font, formatInt(int(App::fps + 0.5f)) + " frames a second", 50, 94, App::fps > 55 ? Green : Orange);
        c.text(font, "Up and down: how many    Accept: collision", 1250, 684, Yellow, AlignRight);
    }
}
