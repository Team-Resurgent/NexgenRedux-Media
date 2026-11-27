// Tiles that join up: water and a path drawn from a sheet of 16 frames each, chosen by which sides meet more of the same,
// and on the right a map drawn only in colours, whose terrains are edged and rounded where they end. Paint the left one.

class TilesScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ small = Assets::font("global:freesans.sfn", 18);
    int cx = 10, cy = 10;       // the brush, in tiles of the painted map
    float t = 0;

    void onEnter()
    {
        Scene::load("asset:scene.json");
    }

    Vec2 placeOf(int x, int y) { return Vec2(20 + (float(x) + 0.5f) * 32, 8 + (float(y) + 0.5f) * 32); }

    void update(float dt)
    {
        t += dt;
        if (Input::repeated("left")) cx = max(0, cx - 1);
        if (Input::repeated("right")) cx = min(19, cx + 1);
        if (Input::repeated("up")) cy = max(0, cy - 1);
        if (Input::repeated("down")) cy = min(21, cy + 1);
        if (Input::held("accept")) Scene::setTile(placeOf(cx, cy), 2);
        if (Input::held("alternate")) Scene::setTile(placeOf(cx, cy), 3);
        if (Input::held("cancel")) Scene::setTile(placeOf(cx, cy), 1);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.12f, 0.13f, 0.16f));
        Scene::draw(c);
        Vec2 at = placeOf(cx, cy);
        c.rectLine(at.x - 16, at.y - 16, 32, 32, 3, Color(1, 1, 1, 0.6f + 0.4f * sin(t * 6)));
        c.text(small, Input::buttons("accept") + ": water   " + Input::buttons("alternate") + ": path   " + Input::buttons("cancel") + ": grass", 680, 694, Yellow);
        c.text(small, "Drawn from a sheet: 16 frames for each", 24, 694, Color(0.85f, 0.9f, 1));
    }
}
