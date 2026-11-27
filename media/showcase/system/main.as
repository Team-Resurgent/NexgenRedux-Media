// What a machine says about itself, and the window: full-screen, its title, waiting for the refresh, the pointer, the
// clipboard, the system's own messages, and opening a web page. On a console there is only the screen.

class SystemScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 34);
    array<string> actions = { "Full-screen", "Wait for the refresh", "Copy the time", "Paste", "A message", "A question", "Open the docs", "Change the title" };
    uint chosen = 0;
    string pasted = "(nothing yet)";
    string answer = "";
    uint titles = 0;
    float fps = 0;

    void update(float dt)
    {
        fps += (App::fps - fps) * 0.05f;
        if (Input::repeated("down")) chosen = (chosen + 1) % actions.length();
        if (Input::repeated("up")) chosen = (chosen + actions.length() - 1) % actions.length();
        // The pointer is a hand over the list, a cross elsewhere.
        Vec2 m = Input::mouse;
        bool overList = m.x > 760 && m.x < 1220 && m.y > 150 && m.y < 150 + 56 * float(actions.length());
        if (Input::hasMouse && overList) chosen = uint((m.y - 150) / 56);
        Window::pointer = overList ? PointerHand : PointerCrosshair;
        if (Input::pressed("accept") || (overList && Input::mouseDown(0) && !wasDown)) act(chosen);
        wasDown = Input::mouseDown(0);
        if (Input::pressed("cancel")) Screens::pop();
    }
    bool wasDown = false;

    void act(uint which)
    {
        if (which == 0) Window::fullscreen = !Window::fullscreen;
        else if (which == 1) Window::vsync = !Window::vsync;
        else if (which == 2) System::clipboard = "Nexgen at " + formatFloat(App::time, "", 0, 1) + " seconds";
        else if (which == 3) pasted = System::clipboard;
        else if (which == 4) answer = Window::message("Nexgen", "A message from a script, in the system's own box.") ? "OK" : "(no boxes here)";
        else if (which == 5) answer = Window::ask("Nexgen", "Is this the system's own box?") ? "Yes" : "No, or none here";
        else if (which == 6) answer = System::open("https://github.com/Team-Resurgent/NexgenRedux") ? "Opened" : "(nothing opens here)";
        else if (which == 7) Window::title = "Nexgen, title " + formatInt(++titles);
    }

    void line(Canvas@ c, float y, const string &in name, const string &in value)
    {
        c.text(font, name, 60, y, Gray);
        c.text(font, value, 330, y, White);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.07f, 0.09f, 0.14f), Color(0.03f, 0.04f, 0.07f));
        c.text(big, "System", 60, 50, White);
        line(c, 130, "Running on", App::platform + ", " + App::gpu);
        line(c, 170, "Locale", System::locale + " (" + System::language + ")");
        line(c, 210, "Processors", formatInt(System::processors));
        int battery = System::battery;
        line(c, 250, "Battery", battery < 0 ? "none" : formatInt(battery) + "%" + (System::charging ? ", charging" : ""));
        line(c, 290, "Drawn at", formatInt(Window::width) + " x " + formatInt(Window::height) + " pixels");
        line(c, 330, "Window", !Window::available ? "the whole screen" : Window::fullscreen ? "full-screen" : "a window");
        line(c, 370, "Waits for refresh", Window::vsync ? "yes" : "no");
        line(c, 410, "Frames a second", formatInt(int(fps + 0.5f)));
        line(c, 450, "Focused", Window::focused ? "yes" : "no");
        line(c, 490, "Pasted", pasted);
        line(c, 530, "Answer", answer);

        for (uint i = 0; i < actions.length(); i++)
        {
            float y = 150 + float(i) * 56;
            bool here = i == chosen;
            c.roundRect(760, y, 460, 46, 10, here ? Color(0.25f, 0.32f, 0.52f) : Color(0.13f, 0.15f, 0.22f));
            c.text(font, actions[i], 780, y + 11, here ? White : Color(0.75f, 0.78f, 0.88f));
        }
        c.text(font, "Up, down: choose    Accept or click: do it    Cancel: back", 640, 670, Yellow, AlignCenter);
    }
}
