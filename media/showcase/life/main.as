const uint across = 96;
const uint down = 54;

// Pixels a script writes, one at a time: Conway's Life, from a seed. The same seed grows the same way on every
// machine. Beside it, the cells fingerprinted and squeezed, a bell curve of random numbers, and a screenshot kept as a PNG.

class LifeScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 20);
    Font@ big = Assets::font("global:freesans.sfn", 30);
    Sound@ click = Assets::sound("global:sound/accept.wav");
    Sound@ shutter = Assets::sound("global:sound/case.wav");
    Pixels@ picture = Pixels(across, down, Color(0.03f, 0.04f, 0.07f));
    array<uint8>@ cells = array<uint8>(across * down);
    array<uint8>@ next = array<uint8>(across * down);
    array<float> heat(across * down);
    array<uint> leftOf(across), rightOf(across);
    array<Color> alive(across);
    uint seed = 1;
    uint generation = 0;
    float wait = 0;
    string fingerprint;
    uint squeezed = 0;
    array<uint> bell(31);
    string message;
    float messageTime = 0;

    void onEnter()
    {
        // Worked out once: the neighbours across, wrapping round, and each column's colour.
        for (uint x = 0; x < across; x++)
        {
            leftOf[x] = (x + across - 1) % across;
            rightOf[x] = (x + 1) % across;
            alive[x] = hsv(0.45f + float(x) / float(across) * 0.3f, 0.6f, 1);
        }
        start(2026);
    }

    void start(uint newSeed)
    {
        seed = newSeed;
        generation = 0;
        Random r(seed);
        for (uint i = 0; i < cells.length(); i++)
        {
            cells[i] = r.random() < 0.3f ? 1 : 0;
            heat[i] = 0.03f;   // so that every pixel is painted afresh
        }
        // A bell curve from the same generator.
        for (uint i = 0; i < bell.length(); i++)
            bell[i] = 0;
        for (int i = 0; i < 3000; i++)
        {
            int bin = int(floor(r.normal(15.5f, 5)));
            if (bin >= 0 && bin < int(bell.length())) bell[bin]++;
        }
        measure();
        paint();
    }

    // The cells as bytes: what they are fingerprinted and squeezed as.
    void measure()
    {
        string bytes;
        bytes.resize(cells.length());
        for (uint i = 0; i < cells.length(); i++)
            bytes[i] = cells[i];
        fingerprint = Data::sha256(bytes).substr(0, 16);
        squeezed = Data::compress(bytes).length();
    }

    void step()
    {
        for (uint y = 0; y < down; y++)
        {
            uint above = ((y + down - 1) % down) * across, here = y * across, below = ((y + 1) % down) * across;
            for (uint x = 0; x < across; x++)
            {
                uint l = leftOf[x], r = rightOf[x];
                uint around = cells[above + l] + cells[above + x] + cells[above + r] + cells[here + l] + cells[here + r] + cells[below + l] + cells[below + x] + cells[below + r];
                next[here + x] = around == 3 || (around == 2 && cells[here + x] == 1) ? 1 : 0;
            }
        }
        array<uint8>@ swap = cells;
        @cells = next;
        @next = swap;
        generation++;
    }

    // Only the pixels that change: what lives, and what has died and is still fading.
    void paint()
    {
        for (uint y = 0; y < down; y++)
            for (uint x = 0; x < across; x++)
            {
                uint i = y * across + x;
                if (cells[i] == 1)
                {
                    if (heat[i] < 1) picture.set(x, y, alive[x]);
                    heat[i] = 1;
                }
                else if (heat[i] > 0)
                {
                    float h = heat[i] * 0.8f;
                    heat[i] = h < 0.02f ? 0 : h;
                    picture.set(x, y, Color(0.03f + h * 0.25f, 0.04f + h * 0.12f, 0.07f + h * 0.35f));
                }
            }
    }

    void update(float dt)
    {
        wait -= dt;
        if (wait <= 0)
        {
            wait = 0.09f;
            step();
            paint();
            if (generation % 10 == 0) measure();
        }
        messageTime -= dt;
        if (Input::pressed("accept"))
        {
            click.play(0.5f);
            start(seed + 1);
        }
        if (Input::pressed("alternate"))
        {
            // The last frame, as pixels, kept as a PNG with the saves.
            Pixels@ shot = App::screenshot();
            if (shot is null) message = "This machine can't read its screen back";
            else if (shot.save("saved:life.png")) message = "Kept as saved:life.png, " + formatInt(shot.width) + " x " + formatInt(shot.height);
            else message = "It couldn't be kept";
            shutter.play(0.6f);
            messageTime = 3;
        }
        if (Input::pressed("cancel")) Screens::pop();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.rect(0, 0, 1280, 720, Color(0.06f, 0.07f, 0.1f));

        // Ten design units to a pixel, kept sharp.
        c.push();
        c.filter = FilterNearest;
        c.image(picture.texture, 30, 60, float(across) * 10, float(down) * 10);
        c.pop();
        c.rectLine(29, 59, float(across) * 10 + 2, float(down) * 10 + 2, 1, Color(0.3f, 0.34f, 0.45f));

        float x = 1010;
        c.text(big, "Life", x, 60, White);
        c.text(font, "Seed " + formatInt(seed), x, 110, Color(0.75f, 0.8f, 0.9f));
        c.text(font, "Generation " + formatInt(generation), x, 140, Color(0.75f, 0.8f, 0.9f));
        c.text(font, "SHA-256 of the cells", x, 190, Gray);
        c.text(font, fingerprint, x, 216, Yellow);
        c.text(font, "Squeezed", x, 260, Gray);
        c.text(font, formatInt(cells.length()) + " to " + formatInt(squeezed) + " bytes", x, 286, Yellow);

        // The bell curve: Random.normal, 3000 times.
        c.text(font, "Random.normal, 3000 times", x, 340, Gray);
        uint most = 1;
        for (uint i = 0; i < bell.length(); i++)
            if (bell[i] > most) most = bell[i];
        array<Vec2> curve;
        for (uint i = 0; i < bell.length(); i++)
        {
            float h = float(bell[i]) / float(most) * 120;
            c.rect(x + float(i) * 7.5f, 500 - h, 6, h, Color(0.3f, 0.55f, 0.9f));
            curve.insertLast(Vec2(x + float(i) * 7.5f + 3, 500 - h));
        }
        c.polyline(curve, 2, Color(1, 1, 1, 0.6f));

        c.text(font, "Accept: another seed    Alternate: screenshot    Cancel: back", 30, 650, Yellow);
        if (messageTime > 0) c.text(font, message, 30, 20, fade(White, min(1, messageTime)));
    }
}
