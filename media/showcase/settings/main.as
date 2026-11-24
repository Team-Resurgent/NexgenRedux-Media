// Volumes and bindings. The engine keeps them between runs.

class SettingsScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 26);
    Font@ small = Assets::font("global:freesans.sfn", 20);
    Font@ big = Assets::font("global:freesans.sfn", 40);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ accept = Assets::sound("global:sound/accept.wav");
    array<string> actions = { "up", "down", "left", "right", "accept", "cancel", "fire", "alternate" };
    array<string> volumes = { "Everything", "Effects", "Music" };
    uint chosen = 0;
    bool waiting = false;

    uint rows() { return 3 + actions.length() + 1; }

    float volume(uint i)
    {
        if (i == 0) return Audio::masterVolume;
        return Audio::volume(i == 1 ? BusEffects : BusMusic);
    }

    void setVolume(uint i, float v)
    {
        v = clamp(v, 0, 1);
        if (i == 0) Audio::masterVolume = v;
        else Audio::setVolume(i == 1 ? BusEffects : BusMusic, v);
        move.play(0.8f);
    }

    void update(float dt)
    {
        if (waiting)
        {
            if (!Input::listening)
            {
                waiting = false;
                accept.play(0.7f);
            }
            return;
        }
        if (Input::repeated("up")) { chosen = chosen == 0 ? rows() - 1 : chosen - 1; move.play(0.5f); }
        if (Input::repeated("down")) { chosen = (chosen + 1) % rows(); move.play(0.5f); }
        if (chosen < 3)
        {
            if (Input::repeated("left")) setVolume(chosen, volume(chosen) - 0.05f);
            if (Input::repeated("right")) setVolume(chosen, volume(chosen) + 0.05f);
        }
        else if (Input::pressed("accept"))
        {
            if (chosen == rows() - 1)
                Input::resetBindings();
            else
            {
                Input::listen(actions[chosen - 3]);
                waiting = true;
            }
            accept.play(0.7f);
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.08f, 0.09f, 0.13f), Color(0.04f, 0.04f, 0.06f));
        c.text(big, "Settings", 80, 26);
        for (uint i = 0; i < rows(); i++)
        {
            float y = 92 + float(i) * 48 + (i >= 3 ? 14.0f : 0.0f);
            if (i == chosen) c.roundRect(60, y - 4, 1160, 42, 10, Color(0.2f, 0.28f, 0.44f));
            if (i < 3)
            {
                c.text(font, volumes[i], 80, y);
                c.roundRect(420, y + 10, 600, 12, 6, Color(0.17f, 0.19f, 0.27f));
                float w = 600 * volume(i);
                c.roundRect(420, y + 10, w < 12 ? 12 : w, 12, 6, Orange);
                c.circle(420 + w, y + 16, 12, White);
                c.text(font, formatInt(int(volume(i) * 100 + 0.5f)) + "%", 1190, y, White, AlignRight);
            }
            else if (i == rows() - 1)
                c.text(font, "Put the controls back", 80, y, Yellow);
            else
            {
                string action = actions[i - 3];
                c.text(font, action, 80, y);
                if (waiting && i == chosen)
                    c.text(font, "press a key or button...", 420, y, fade(Yellow, 0.6f + 0.4f * sin(App::time * 8)));
                else
                {
                    c.text(font, Input::keys(action), 420, y, Color(0.75f, 0.85f, 1));
                    c.text(font, Input::buttons(action), 820, y, Color(0.7f, 0.95f, 0.75f));
                }
            }
        }
        c.text(small, "Escape, Start, or holding Back always open the menu, whatever is set here.", 640, 686, Gray, AlignCenter);
    }
}
