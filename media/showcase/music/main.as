// Music is decoded as it plays, from a playlist that goes on to the next by itself, fading one into the other. The bars
// are its spectrum and the circle is its wave.

class MusicScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 46);
    array<string> titles = { "Night Shift", "Slow Light" };
    array<Sound@> tunes = { Assets::sound("asset:tune.ogg"), Assets::sound("asset:ambient.mp3") };
    Playlist@ list = Playlist();
    array<float> peaks(32);
    float beat = 0;
    float turn = 0;

    void onEnter()
    {
        for (uint i = 0; i < tunes.length(); i++)
            list.add(tunes[i]);
        list.volume = 0.9f;
        list.crossfade = 3;
        list.play(0.5f);
    }

    void update(float dt)
    {
        // Across, fading one into the other.
        if (Input::pressed("left"))
            list.previous(1.2f);
        if (Input::pressed("right"))
            list.next(1.2f);
        if (Input::pressed("accept"))
            list.paused = !list.paused;
        float low = 0;
        for (uint i = 0; i < 4; i++) low += Audio::spectrum(i) / 4;
        beat = low > beat ? low : beat * 0.92f;
        turn += dt * (6 + beat * 40);
        for (uint i = 0; i < 32; i++)
        {
            float now = Audio::spectrum(i);
            peaks[i] = now > peaks[i] ? now : peaks[i] - dt * 0.35f;
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.02f, 0.02f, 0.06f), Color(0.1f, 0.03f, 0.16f));

        // Rings that swell with the low notes.
        c.blend = BlendAdd;
        for (int i = 4; i > 0; i--)
            c.circle(640, 290, 120 + float(i) * 34 * (0.4f + beat), fade(hsv(0.6f + float(i) * 0.06f, 0.8f, 0.7f), 0.10f + beat * 0.08f));
        c.blend = BlendAlpha;

        c.push();
        c.translate(640, 290);
        c.rotate(turn);
        float lastX = 0, lastY = 0;
        for (uint i = 0; i <= 128; i++)
        {
            float a = float(i % 128) / 128 * 6.28318f;
            // Faded at the ends so the circle joins up.
            float ends = sin(float(i % 128) / 128 * 3.14159f);
            float r = 150 + Audio::wave((i % 128) * 4) * 110 * ends + beat * 20;
            float x = cos(a) * r, y = sin(a) * r;
            if (i > 0) c.line(lastX, lastY, x, y, 4, hsv(0.5f + float(i) / 256, 0.6f, 1));
            lastX = x;
            lastY = y;
        }
        c.pop();

        for (uint i = 0; i < 32; i++)
        {
            float x = 80 + float(i) * 35;
            float h = Audio::spectrum(i) * 190;
            Color color = hsv(0.52f + float(i) * 0.012f, 0.75f, 1);
            c.gradient(x, 600 - h, 28, h + 2, color, fade(color, 0.35f));
            c.rect(x, 600 - peaks[i] * 190 - 6, 28, 4, White);
            c.gradient(x, 604, 28, h * 0.25f, fade(color, 0.25f), fade(color, 0));
        }

        c.text(big, titles[list.index], 60, 30);
        float length = list.seconds;
        c.text(font, clock(list.position) + (length > 0 ? " / " + clock(length) : "") + (list.paused ? "   paused" : "") + "      " + formatInt(int(list.index + 1)) + " of " + formatInt(int(list.count)), 62, 90, Color(0.7f, 0.75f, 0.9f));
        c.text(font, Input::usingPad ? "Left and right: change tune    A: pause" : "Left and right: change tune    Enter: pause", 640, 672, Color(0.7f, 0.75f, 0.9f), AlignCenter);
    }

    string clock(float t)
    {
        int s = int(t);
        return formatInt(s / 60) + ":" + formatInt(s % 60, "0", 2);
    }
}
