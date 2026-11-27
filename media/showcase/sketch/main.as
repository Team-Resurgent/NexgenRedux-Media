// Polygons, lines through many points, ellipses, meshes and masks.

class SketchScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 64);
    Texture@ bricks = Assets::texture("global:picture/bricks.png");
    Texture@ planks = Assets::texture("global:picture/planks.png");
    Texture@ clouds = Assets::texture("global:picture/sky-clouds.png");
    float t = 0;

    void update(float dt) { t += dt; }

    void cell(Canvas@ c, uint index, const string &in label)
    {
        float x = float(index % 4) * 310 + 30;
        float y = float(index / 4) * 340 + 30;
        c.roundRect(x, y, 290, 320, 14, Color(0.11f, 0.13f, 0.2f));
        c.text(font, label, x + 145, y + 284, Color(0.7f, 0.76f, 0.86f), AlignCenter);
        c.push();
        c.clip(x, y, 290, 270);
        c.translate(x + 145, y + 140);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.05f, 0.06f, 0.1f));

        // A concave star, and an arrow, filled.
        cell(c, 0, "polygon");
        array<Vec2> star;
        for (int i = 0; i < 14; i++)
        {
            float a = float(i) * 3.14159f / 7 + t * 0.3f;
            float r = i % 2 == 0 ? 100 : 44 + 10 * sin(t * 2);
            star.insertLast(Vec2(cos(a) * r, sin(a) * r));
        }
        c.polygon(star, hsv(0.12f, 0.75f, 1));
        array<Vec2> arrow = { Vec2(-30, -14), Vec2(4, -14), Vec2(4, -30), Vec2(36, 0), Vec2(4, 30), Vec2(4, 14), Vec2(-30, 14) };
        c.rotate(-t * 40);
        c.polygon(arrow, Color(0.2f, 0.25f, 0.45f));
        c.pop();

        // A graph, mitred where it turns, and a polygon's outline.
        cell(c, 1, "polyline and polygonLine");
        array<Vec2> graph;
        for (int i = 0; i <= 12; i++)
            graph.insertLast(Vec2(-120 + float(i) * 20, 40 + sin(float(i) * 1.3f + t * 2) * 30 + (i % 2 == 0 ? -20 : 20)));
        c.polyline(graph, 6, Green);
        array<Vec2> hexagon;
        for (int i = 0; i < 6; i++)
        {
            float a = float(i) * 3.14159f / 3 + t * 0.5f;
            hexagon.insertLast(Vec2(cos(a) * 50, -50 + sin(a) * 50));
        }
        c.polygonLine(hexagon, 10, Orange);
        c.pop();

        // Ellipses, squashing and stretching.
        cell(c, 2, "ellipse and ellipseLine");
        for (int i = 5; i > 0; i--)
        {
            float rx = float(i) * 22 * (1 + 0.25f * sin(t * 2));
            float ry = float(i) * 22 * (1 - 0.25f * sin(t * 2));
            c.ellipse(0, 0, rx, ry, hsv(0.55f + float(i) * 0.04f, 0.6f, 0.25f + 0.12f * float(6 - i)));
        }
        c.ellipseLine(0, 0, 120, 30, 3, White);
        c.rotate(90);
        c.ellipseLine(0, 0, 120, 30, 3, fade(White, 0.4f));
        c.pop();

        // A picture as a flag, its points moved and lit by how they wave.
        cell(c, 3, "mesh");
        array<Vec2> points, uvs;
        array<Color> shades;
        array<uint> triangles;
        const int across = 12, down = 8;
        for (int y = 0; y <= down; y++)
            for (int x = 0; x <= across; x++)
            {
                float u = float(x) / across, v = float(y) / down;
                float wave = sin(u * 6 - t * 4) * 12 * u;
                points.insertLast(Vec2(-110 + u * 220, -80 + v * 160 + wave));
                uvs.insertLast(Vec2(u, v));
                float light = 0.75f + 0.25f * cos(u * 6 - t * 4);
                shades.insertLast(Color(light, light, light));
            }
        for (int y = 0; y < down; y++)
            for (int x = 0; x < across; x++)
            {
                uint a = uint(y * (across + 1) + x), b = a + 1, d = a + across + 1, e = d + 1;
                triangles.insertLast(a); triangles.insertLast(b); triangles.insertLast(e);
                triangles.insertLast(a); triangles.insertLast(e); triangles.insertLast(d);
            }
        c.mesh(planks, points, uvs, White, triangles, shades);
        c.pop();

        // A spotlight: the mask is a circle, and the picture is seen only inside it.
        cell(c, 4, "mask and masked");
        c.image(bricks, -145, -140, 290, 270, Color(0.18f, 0.18f, 0.22f));
        c.mask();
        c.circle(sin(t) * 80, cos(t * 1.3f) * 50, 60, White);
        c.circle(sin(t * 0.7f + 2) * 70, cos(t * 0.9f) * 60, 36, White);
        c.masked();
        c.image(bricks, -145, -140, 290, 270);
        c.unmask();
        c.pop();

        // Outside the mask: text cut out of the clouds.
        cell(c, 5, "masked(false)");
        c.mask();
        c.text(big, "NEXGEN", 0, -60, White, AlignCenter);
        c.polygon(star, White);
        c.masked(false);
        c.image(clouds, -145 + sin(t) * 20, -140, 330, 270);
        c.unmask();
        c.pop();

        // A fan of colours: a mesh of no picture.
        cell(c, 6, "mesh of colours");
        array<Vec2> fanPoints = { Vec2(0, 0) };
        array<Color> fanColors = { White };
        for (int i = 0; i <= 24; i++)
        {
            float a = float(i) * 6.28318f / 24 + t * 0.5f;
            float r = 90 + 20 * sin(float(i) * 2 + t * 3);
            fanPoints.insertLast(Vec2(cos(a) * r, sin(a) * r));
            fanColors.insertLast(hsv(float(i) / 24, 0.9f, 1));
        }
        c.mesh(null, fanPoints, fanPoints, White, null, fanColors);
        c.pop();

        // A trail behind something that moves, thinning as it goes.
        cell(c, 7, "trails");
        for (int k = 0; k < 3; k++)
        {
            array<Vec2> trail;
            for (int i = 0; i < 40; i++)
            {
                float s = t - float(i) * 0.02f + float(k) * 2;
                trail.insertLast(Vec2(sin(s * 1.7f) * 100, sin(s * 2.3f) * 90));
            }
            c.polyline(trail, 8 - float(k) * 2, hsv(float(k) * 0.3f + 0.05f, 0.7f, 1));
        }
        c.pop();
    }
}
