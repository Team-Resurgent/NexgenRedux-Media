// Asking web servers for things, without waiting for them. Nothing is asked until you say so.

class WebScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    array<string> titles = { "What is new in Nexgen", "The demos", "A plain page", "Somewhere that isn't safe" };
    array<string> urls = { "https://api.github.com/repos/Team-Resurgent/NexgenRedux/commits?per_page=6", "https://raw.githubusercontent.com/Team-Resurgent/NexgenRedux-Media/main/README.md", "http://example.com/", "https://expired.badssl.com/" };
    int chosen = 0;
    Request@ request;
    Texture@ picture;
    array<string> lines;
    float scroll = 0, took = 0;

    void update(float dt)
    {
        if (Input::repeated("down") && chosen + 1 < int(urls.length())) chosen++;
        if (Input::repeated("up") && chosen > 0) chosen--;
        if (Input::pressed("accept"))
        {
            @request = Net::get(urls[uint(chosen)]);
            lines.resize(0);
            took = scroll = 0;
            if (picture is null)
                @picture = Assets::texture("https://raw.githubusercontent.com/Team-Resurgent/NexgenRedux/main/docs/screenshots/explore.png");
        }
        if (request !is null && !request.done)
            took += dt;
        if (request !is null && request.done && lines.length() == 0)
            read();
        scroll = clamp(scroll + dt * 14, 0, lines.length() > 15 ? float(lines.length() - 15) * 30 : 0.0f);
    }

    void read()
    {
        string text = request.text;
        if (chosen == 0)
        {
            // Only the first line of each message, which is all that is wanted of it.
            uint at = 0;
            for (int i = 0; i < 6; i++)
            {
                int found = text.findFirst("\"message\":\"", at);
                if (found < 0)
                    break;
                at = uint(found) + 11;
                int end = text.findFirst("\"", at);
                int line = text.findFirst("\\n", at);
                if (line > 0 && line < end)
                    end = line;
                lines.insertLast(text.substr(at, uint(end) - at));
            }
        }
        else
        {
            array<string>@ all = text.split("\n");
            for (uint i = 0; i < all.length() && i < 120; i++)
                lines.insertLast(all[i].length() > 86 ? all[i].substr(0, 86) : all[i]);
        }
        if (lines.length() == 0)
            lines.insertLast(request.failed ? "" : "(nothing)");
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.08f, 0.1f, 0.16f), Color(0.04f, 0.05f, 0.08f));
        c.text(big, "Web", 40, 24);
        c.text(font, Net::available ? "This machine is at " + (Net::address == "" ? "no address yet" : Net::address) : "There is no network", 1240, 40, Color(0.6f, 0.7f, 0.8f), AlignRight);
        for (uint i = 0; i < titles.length(); i++)
        {
            bool here = int(i) == chosen;
            c.roundRect(40, 100 + float(i) * 66, 360, 56, 12, here ? Color(0.2f, 0.4f, 0.75f) : Color(1, 1, 1, 0.07f));
            c.text(font, titles[i], 60, 115 + float(i) * 66, here ? White : Color(0.7f, 0.75f, 0.85f));
        }
        if (picture !is null && picture.ready && !picture.failed)
        {
            c.image(picture, 40, 400, 360, 203);
            c.rectLine(40, 400, 360, 203, 2, Color(1, 1, 1, 0.3f));
        }
        else if (picture !is null)
            c.text(font, "A picture is on its way", 60, 480, Color(0.5f, 0.55f, 0.65f));
        c.roundRect(430, 100, 810, 520, 16, Color(0, 0, 0, 0.4f));
        if (request is null)
            c.text(font, "Accept: ask", 835, 340, Color(0.6f, 0.65f, 0.75f), AlignCenter);
        else if (!request.done)
        {
            c.arc(835, 340, 40, 8, App::time * 260, App::time * 260 + 100, Blue);
            c.text(font, formatInt(int(request.received)) + " bytes", 835, 400, Color(0.6f, 0.65f, 0.75f), AlignCenter);
        }
        else if (request.failed)
        {
            c.text(font, "It was refused:", 460, 130, Color(1, 0.6f, 0.4f));
            c.text(font, request.error, 460, 164);
        }
        else
        {
            c.push();
            c.clip(440, 110, 790, 500);
            for (uint i = 0; i < lines.length(); i++)
                c.text(font, lines[i], 455, 124 + float(i) * 30 - scroll, Color(0.82f, 0.88f, 0.95f));
            c.pop();
            c.text(font, "Status " + formatInt(request.status) + ", " + formatInt(int(request.received)) + " bytes in " + formatFloat(took, "", 0, 2) + " seconds", 1240, 630, Color(0.6f, 0.7f, 0.8f), AlignRight);
        }
        c.text(font, "Up, down: choose     Accept: ask", 640, 676, Color(0.6f, 0.65f, 0.75f), AlignCenter);
    }
}
