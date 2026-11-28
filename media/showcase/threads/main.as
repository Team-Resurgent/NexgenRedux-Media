// Threads: the Mandelbrot set worked out by scripts on threads of their own, a row at a time, and drawn here as the
// rows come back through a channel. The screen goes on turning smoothly however long they take.

const uint across = 320;
const uint down = 180;

class ThreadsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 34);
    array<Thread@> workers;
    Channel rows("rows"), done("done");
    Pixels@ picture = Pixels(across, down, Black);
    array<Color> palette(256);
    double zoom = 3.2;
    double cx = -0.743643887, cy = 0.131825904;   // deep in the seahorse valley
    uint waiting = 0;
    uint made = 0;
    float turned = 0;
    float rowsLately = 0;
    uint frameRows = 0;

    void onEnter()
    {
        for (uint i = 0; i < 255; i++)
        {
            float t = float(i) / 64;
            palette[i] = hsv(0.6f + t * 0.35f, 0.75f, 0.25f + 0.75f * min(1, t * 2));
        }
        palette[255] = Black;
        uint count = System::processors > 4 ? 4 : System::processors;
        for (uint i = 0; i < count; i++)
        {
            Thread@ t = Thread("asset:rows.as");
            t.start();
            workers.insertLast(t);
        }
        ask();
    }

    // Every row of the next picture, for whichever thread is free.
    void ask()
    {
        rows.clear();
        for (uint y = 0; y < down; y++)
            rows.push(formatUInt(made) + " " + formatUInt(y) + " " + formatUInt(across) + " " + formatUInt(down) + " " + formatFloat(zoom, "", 0, 17) + " " + formatFloat(cx, "", 0, 17) + " " + formatFloat(cy, "", 0, 17));
        waiting = down;
    }

    void update(float dt)
    {
        turned += dt * 90;
        string row;
        frameRows = 0;
        while (done.pop(row))
        {
            int first = row.findFirst(" ");
            int space = row.findFirst(" ", first + 1);
            if (parseUInt(row.substr(0, first)) != made) continue;   // from a picture already left behind
            uint y = parseUInt(row.substr(first + 1, space - first - 1));
            for (uint x = 0; x < across; x++)
                picture.set(x, y, palette[uint8(row[space + 1 + x])]);
            frameRows++;
            if (waiting > 0 && --waiting == 0)
            {
                made++;
                zoom *= 0.82;
                if (zoom < 1e-11) zoom = 3.2;
                ask();
            }
        }
        rowsLately += (float(frameRows) / dt - rowsLately) * 0.05f;
        if (Input::pressed("cancel")) Screens::pop();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.04f, 0.05f, 0.08f));
        c.push();
        c.filter = FilterNearest;
        c.image(picture.texture, 40, 90, 960, 540);
        c.pop();
        c.text(big, "Threads", 40, 30, White);

        float x = 1030;
        c.text(font, formatUInt(workers.length()) + " threads", x, 100, White);
        c.text(font, "of " + formatUInt(System::processors) + " processors", x, 130, Gray);
        c.text(font, formatInt(int(rowsLately)) + " rows a second", x, 180, Yellow);
        c.text(font, formatUInt(made) + " pictures", x, 210, Yellow);
        c.text(font, formatInt(int(App::fps + 0.5f)) + " frames a second", x, 260, Color(0.5f, 0.9f, 0.6f));

        // Something that would stutter if the work were done here.
        c.push();
        c.translate(1130, 420);
        c.rotate(turned);
        for (int i = 0; i < 8; i++)
        {
            c.rotate(45);
            c.roundRect(40, -8, 50, 16, 8, hsv(float(i) / 8, 0.6f, 1));
        }
        c.pop();
        c.text(font, "Turned here, smoothly,", 1130, 540, Gray, AlignCenter);
        c.text(font, "while threads work", 1130, 566, Gray, AlignCenter);
    }
}
