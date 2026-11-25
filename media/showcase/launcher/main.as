// Finds what can be run on the hard disk of an original Xbox, shows how the console is, and runs one.
// Elsewhere there is nothing to find, so some are made up.

class Title
{
    string name, path;
}

class LauncherScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Sound@ move = Assets::sound("global:sound/move.wav");
    Sound@ accept = Assets::sound("global:sound/accept.wav");
    array<string> drives = { "E", "F", "G" };
    array<Title@> titles;
    array<string> waiting;          // folders still to look in
    int drive = 0, chosen = 0, looked = 0;
    float scroll = 0, sure = 0, next = 0;
    int cpu = -1, board = -1, fan = -1;

    void onEnter() { look(); }

    void look()
    {
        titles.resize(0);
        waiting.resize(0);
        chosen = looked = 0;
        scroll = 0;
        if (!Xbox::available)
        {
            array<string> some = { "Comet rally", "Rune shift", "Sky Patrol", "Platformer", "Spire", "Rebound", "Skimmer" };
            for (uint i = 0; i < some.length(); i++)
                found(some[i], "");
            return;
        }
        string root = drives[uint(drive)] + ":\\";
        check(root, "");
        array<string>@ top = Xbox::folders(root);
        for (uint i = 0; i < top.length(); i++)
            waiting.insertLast(root + top[i]);
    }

    void found(const string &in name, const string &in path)
    {
        Title@ t = Title();
        t.name = name;
        t.path = path;
        titles.insertLast(t);
    }

    void check(const string &in folder, const string &in name)
    {
        array<string>@ files = Xbox::files(folder);
        for (uint i = 0; i < files.length(); i++)
        {
            uint n = files[i].length();
            if (n > 4 && (files[i].substr(n - 4) == ".xbe" || files[i].substr(n - 4) == ".XBE"))
                found(name == "" ? files[i] : name, folder + (name == "" ? "" : "\\") + files[i]);
        }
    }

    void update(float dt)
    {
        // A folder each frame, so that nothing stops.
        if (waiting.length() > 0)
        {
            string folder = waiting[0];
            waiting.removeAt(0);
            looked++;
            int slash = folder.findLast("\\");
            check(folder, folder.substr(uint(slash + 1)));
            // One more deep, for those that are sorted.
            if (looked < 200 && folder.findLast("\\") < 4)
            {
                array<string>@ inside = Xbox::folders(folder);
                for (uint i = 0; i < inside.length() && i < 60; i++)
                    waiting.insertLast(folder + "\\" + inside[i]);
            }
        }
        next -= dt;
        if (next < 0)
        {
            next = 1;
            cpu = Xbox::cpuTemperature;
            board = Xbox::boardTemperature;
            fan = Xbox::fan;
        }
        int before = chosen;
        if (Input::repeated("down") && chosen + 1 < int(titles.length())) chosen++;
        if (Input::repeated("up") && chosen > 0) chosen--;
        if (chosen != before)
        {
            move.play(0.5f);
            sure = 0;
        }
        int way = (Input::pressed("right") ? 1 : 0) - (Input::pressed("left") ? 1 : 0);
        if (way != 0)
        {
            drive = (drive + way + int(drives.length())) % int(drives.length());
            look();
        }
        sure = clamp(sure - dt, 0, 10);
        if (Input::pressed("accept") && chosen < int(titles.length()))
        {
            accept.play(0.6f);
            if (sure > 0 && titles[uint(chosen)].path != "")
                Xbox::launch(titles[uint(chosen)].path);
            else
                sure = 3;
        }
        float wanted = clamp(float(chosen) * 46 - 230, 0, 100000);
        scroll += (wanted - scroll) * clamp(dt * 10, 0, 1);
    }

    void meter(Canvas@ c, float y, const string &in name, const string &in value, float part, const Color &in color)
    {
        c.text(font, name, 860, y, Color(0.65f, 0.7f, 0.8f));
        c.text(font, value, 1220, y, White, AlignRight);
        c.roundRect(860, y + 34, 360, 10, 5, Color(1, 1, 1, 0.1f));
        if (part > 0)
            c.roundRect(860, y + 34, 10 + 350 * clamp(part, 0, 1), 10, 5, color);
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.04f, 0.12f, 0.06f), Color(0.02f, 0.04f, 0.03f));
        for (int i = 0; i < 4; i++)
            c.ring(1040, 400, 200 + float(i) * 90 + sin(App::time * 0.4f + float(i)) * 14, 20, Color(0.3f, 0.9f, 0.3f, 0.04f));
        c.text(big, "Launcher", 40, 24);
        c.text(font, Xbox::available ? "Drive " + drives[uint(drive)] + (waiting.length() > 0 ? ", still looking" : "") : "There are drives only on an original Xbox: these are made up", 44, 82, Color(0.6f, 0.75f, 0.6f));
        c.push();
        c.clip(30, 120, 790, 520);
        for (uint i = 0; i < titles.length(); i++)
        {
            float y = 130 + float(i) * 46 - scroll;
            bool here = int(i) == chosen;
            if (y < 70 || y > 650)
                continue;
            c.roundRect(40, y, 770, 40, 10, here ? Color(0.25f, 0.75f, 0.25f, 0.9f) : Color(1, 1, 1, 0.06f));
            c.text(font, titles[i].name, 60, y + 6, here ? Color(0.02f, 0.08f, 0.02f) : Color(0.8f, 0.88f, 0.8f));
            if (here && sure > 0)
                c.text(font, titles[i].path == "" ? "nothing to run" : "again to run it", 795, y + 6, Color(0.02f, 0.08f, 0.02f), AlignRight);
        }
        if (titles.length() == 0)
            c.text(font, waiting.length() > 0 ? "Looking..." : "Nothing to run here", 420, 340, Color(0.6f, 0.7f, 0.6f), AlignCenter);
        c.pop();
        c.roundRect(836, 120, 408, 520, 20, Color(0, 0, 0, 0.45f));
        string degrees = " C";
        meter(c, 140, "Processor", cpu < 0 ? "-" : formatInt(cpu) + degrees, float(cpu) / 80, cpu > 65 ? Red : Green);
        meter(c, 208, "Board", board < 0 ? "-" : formatInt(board) + degrees, float(board) / 80, board > 55 ? Red : Green);
        meter(c, 276, "Fan", fan < 0 ? "-" : formatInt(fan) + "%", float(fan) / 100, Blue);
        for (uint i = 0; i < drives.length(); i++)
        {
            uint size = Xbox::available ? Xbox::driveSize(drives[i]) : 0, free = Xbox::available ? Xbox::driveFree(drives[i]) : 0;
            meter(c, 344 + float(i) * 68, "Drive " + drives[i], size == 0 ? "-" : formatInt(int(free)) + " MB free", size == 0 ? 0.0f : 1 - float(free) / float(size), Yellow);
        }
        c.text(font, Xbox::available ? "Kernel " + Xbox::text(XboxKernel) : App::platform, 860, 560, Color(0.65f, 0.75f, 0.65f));
        c.text(font, Xbox::available ? Xbox::text(XboxHardware) : "", 860, 594, Color(0.65f, 0.75f, 0.65f));
        c.text(font, "Up, down: choose     Left, right: drive     Accept: run", 640, 672, Color(0.6f, 0.75f, 0.6f), AlignCenter);
    }
}
