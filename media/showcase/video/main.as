// A film: MPEG-1 with MP2 sound, from ffmpeg. It plays by itself while the screen is on top, and its picture is an
// image like any other, drawn here as it is and on a card that turns.

class VideoScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Video@ film = Assets::video("asset:mandel.mpg");
    Entity@ card;
    float t = 0;

    void onEnter()
    {
        film.loop = true;
        film.play();
        @card = Scene::spawn(Vec2(1110, 520));
        card.image(film.picture, 240, 136);
        card.layer = 2;
    }

    void update(float dt)
    {
        t += dt;
        if (Input::pressed("accept"))
        {
            if (film.playing) film.pause();
            else film.play();
        }
        if (Input::pressed("alternate"))
        {
            film.stop();
            film.play();
        }
        card.rotation = sin(t * 0.8f) * 18;
        card.scale = Vec2(0.85f + 0.15f * cos(t * 1.7f), 1);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.07f, 0.08f, 0.12f), Color(0.02f, 0.02f, 0.04f));
        float w = 960, h = w * float(film.height) / float(film.width);
        float x = 40, y = 40;
        c.roundRect(x - 8, y - 8, w + 16, h + 16, 12, Color(0, 0, 0, 0.6f));
        c.image(film.picture, x, y, w, h);
        if (!film.playing)
            c.text(font, film.done ? "The end" : "Paused", x + w / 2, y + h / 2 - 12, White, AlignCenter);

        // How far in it is.
        float part = film.duration > 0 ? film.time / film.duration : 0;
        c.roundRect(x, y + h + 24, w, 10, 5, Color(1, 1, 1, 0.15f));
        c.roundRect(x, y + h + 24, w * part, 10, 5, Color(0.4f, 0.75f, 1));
        c.text(font, formatFloat(film.time, "", 0, 1) + " of " + formatFloat(film.duration, "", 0, 1) + " seconds, " + formatInt(film.width) + " by " + formatInt(film.height) + " at " + formatFloat(film.framerate, "", 0, 0) + " a second" + (film.loop ? ", over and over" : ""), x, y + h + 44, Color(0.8f, 0.85f, 0.95f));

        Scene::draw(c);
        c.text(font, "The same picture,", 1110, 360, Color(0.7f, 0.75f, 0.85f), AlignCenter);
        c.text(font, "on a card", 1110, 386, Color(0.7f, 0.75f, 0.85f), AlignCenter);
        c.text(font, Input::buttons("accept") + ": play or pause    " + Input::buttons("alternate") + ": from the start", 640, 680, Color(0.7f, 0.75f, 0.85f), AlignCenter);
    }
}
