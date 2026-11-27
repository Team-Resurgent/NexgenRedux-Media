// Lights on the plane: a dark dungeon, a lantern that goes where you do, torches that flicker, crystals of colour, and
// crates and a pillar that turns, all casting shadows. Scene::ambient is the dark; each light adds to it.

class LightsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Entity@ hero;
    array<Entity@> torches;
    array<Entity@> crates;
    Entity@ pillar;
    float t = 0;

    void onEnter()
    {
        Scene::load("asset:scene.json");
        Scene::gravity = Vec2(0, 0);
        Scene::ambient = Color(0.07f, 0.07f, 0.13f);
        Scene::lightLayer = 5;      // the flames above it glow, unlit

        @hero = Scene::spawn(Vec2(100, 100));
        hero.disc(13, Color(1, 0.85f, 0.55f));
        hero.circle(13);
        hero.solid = true;
        hero.light(Color(1, 0.86f, 0.62f), 260);

        array<Vec2> places = { Vec2(260, 60), Vec2(1020, 60), Vec2(60, 420), Vec2(1220, 300), Vec2(640, 660), Vec2(420, 300) };
        for (uint i = 0; i < places.length(); i++)
        {
            Entity@ torch = Scene::spawn(places[i]);
            torch.disc(7, Color(1, 0.6f, 0.2f));
            torch.layer = 10;
            torches.insertLast(torch);
        }
        array<Vec2> gems = { Vec2(860, 200), Vec2(680, 330), Vec2(1100, 560) };
        array<Color> colours = { Color(0.3f, 0.6f, 1), Color(0.4f, 1, 0.5f), Color(1, 0.35f, 0.8f) };
        for (uint i = 0; i < gems.length(); i++)
        {
            Entity@ gem = Scene::spawn(gems[i]);
            gem.disc(9, colours[i]);
            gem.layer = 10;
            gem.light(colours[i], 200);
        }
        for (int i = 0; i < 3; i++)
        {
            Entity@ crate = Scene::spawn(Vec2(520 + float(i) * 120, 420));
            crate.rect(44, 44, Color(0.55f, 0.4f, 0.25f));
            crate.box(44, 44);
            crate.wall = true;
            crate.occluder = true;
            crates.insertLast(crate);
        }
        @pillar = Scene::spawn(Vec2(860, 380));
        pillar.rect(140, 20, Color(0.45f, 0.45f, 0.55f));
        pillar.box(140, 20);
        pillar.occluder = true;
    }

    void update(float dt)
    {
        t += dt;
        hero.velocity = Input::move * 230;
        for (uint i = 0; i < torches.length(); i++)
        {
            float flicker = 0.85f + noise(t * 5, float(i) * 9) * 0.25f;
            torches[i].light(Color(flicker, 0.55f * flicker, 0.2f * flicker), 190 + noise(t * 3, float(i) * 7 + 50) * 20);
        }
        for (uint i = 0; i < crates.length(); i++)
            crates[i].position = Vec2(520 + float(i) * 120 + sin(t * 0.8f + float(i)) * 50, 420 + cos(t * 0.6f + float(i) * 2) * 30);
        pillar.rotation = t * 40;
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.1f, 0.1f, 0.12f));
        Scene::draw(c);
        c.text(font, "A lantern, torches and crystals; the walls, crates and pillar cast shadows", 20, 690, Color(0.85f, 0.88f, 1));
    }
}
