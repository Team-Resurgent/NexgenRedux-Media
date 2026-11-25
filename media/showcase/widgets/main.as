// Every kind of widget. Add them to a page, say what to do when they are used, and that is all:
// layout, focus, the gamepad, the mouse and typing are the engine's.

class WidgetsScreen : Screen
{
    Widget@ bar;
    Widget@ volumeText;
    Widget@ said;
    float at = 0;
    int popups = 0;

    void onEnter()
    {
        build();
    }

    void build()
    {
        Ui::clear();
        Widget@ page = Ui::root;
        page.padding = 44;
        page.gap = 16;
        Widget@ top = page.row();
        top.label("Widgets", "title").grow = 1;
        top.label("Theme");
        Widget@ theme = top.choice(array<string> = { "Nexgen", "Paper", "Arcade" }, themeNow, WidgetEvent(this.onTheme));
        theme.id = "theme";

        Widget@ tabs = page.tabs();
        controls(tabs.tab("Controls"));
        words(tabs.tab("Text"));
        pictures(tabs.tab("Pictures"));
        asking(tabs.tab("Asking"));

        @said = page.label(" ", "small");
        tabs.child(1).child(0).focus();
    }

    int themeNow = 0;
    void onTheme(Widget@ w)
    {
        themeNow = w.chosen;
        array<string> files = { "", "asset:paper.json", "asset:arcade.json" };
        Ui::theme(files[uint(themeNow)]);
    }

    Widget@ named(Widget@ page, const string &in name)
    {
        Widget@ row = page.row(20);
        row.label(name).grow = 1;
        return row;
    }

    void controls(Widget@ page)
    {
        Widget@ sides = page.row(24);
        sides.grow = 1;
        sides.align = PlaceStretch;
        Widget@ left = sides.panel();
        left.grow = 1;
        left.toggle("Sound effects", true, WidgetEvent(this.onToggle));
        left.toggle("Subtitles", false, WidgetEvent(this.onToggle));
        Widget@ volume = named(left, "Volume");
        @volumeText = volume.label("60%", "small");
        Widget@ slide = volume.slider(60, 0, 100, WidgetEvent(this.onVolume));
        slide.step = 5;
        slide.width = 320;
        named(left, "Difficulty").choice(array<string> = { "Gentle", "Fair", "Hard", "Cruel" }, 1, WidgetEvent(this.onChoice)).width = 320;
        Widget@ row = left.row();
        row.button("Save", WidgetEvent(this.onSave)).grow = 1;
        Widget@ off = row.button("Not now");
        off.enabled = false;
        off.grow = 1;
        Widget@ right = sides.panel();
        right.grow = 1;
        right.label("Progress", "heading");
        @bar = right.progress(0);
        right.line();
        right.label("What you use is named below", "small");
        Widget@ grid = right.grid(3);
        for (int i = 1; i <= 6; i++)
        {
            Widget@ b = grid.button(formatInt(i), WidgetEvent(this.onNumber));
            b.tag = i;
        }
    }

    void words(Widget@ page)
    {
        Widget@ panel = page.panel();
        panel.grow = 1;
        panel.label("A heading", "heading");
        panel.paragraph("Text goes on to other lines to fit the width it is given. How tall it turns out is worked out from that, and everything under it moves down. Nothing here has a position: rows, columns and grids share out the room there is.");
        panel.line();
        Widget@ row = named(panel, "Your name");
        Widget@ name = row.field("", "Type something", WidgetEvent(this.onTyped));
        name.width = 420;
        name.limit = 24;
        Widget@ secret = named(panel, "A secret").field("", "Hidden", WidgetEvent(this.onTyped));
        secret.secret = true;
        secret.width = 420;
        Widget@ number = named(panel, "A number").field("", "0", WidgetEvent(this.onTyped));
        number.numeric = true;
        number.width = 420;
        panel.label("With a gamepad, the keyboard comes up on the screen", "small");
    }

    void pictures(Widget@ page)
    {
        Widget@ sides = page.row(24);
        sides.grow = 1;
        sides.align = PlaceStretch;
        Widget@ left = sides.panel();
        left.grow = 1;
        left.label("Pictures in buttons", "heading");
        Widget@ grid = left.grid(3);
        for (int i = 0; i < 6; i++)
        {
            Widget@ b = grid.button("", WidgetEvent(this.onNumber));
            b.tag = i + 1;
            b.align = PlaceCenter;
            b.image(Assets::texture("asset:cover" + formatInt(i) + ".jpg"), 130, 130);
            b.label("Cover " + formatInt(i + 1), "small");
        }
        Widget@ right = sides.panel();
        right.grow = 1;
        right.label("Drawn by the script", "heading");
        right.custom(WidgetDraw(this.drawn)).grow = 1;
    }

    void asking(Widget@ page)
    {
        Widget@ panel = page.panel();
        panel.grow = 1;
        panel.paragraph("Something in front must be dealt with first. Cancel closes it, and the focus goes back to where it was.");
        Widget@ row = panel.row();
        row.button("Ask a question", WidgetEvent(this.onAsk)).grow = 1;
        row.button("Open a popup", WidgetEvent(this.onPopup)).grow = 1;
        row.button("Say something", WidgetEvent(this.onToast)).grow = 1;
    }

    void onToggle(Widget@ w) { said.text = w.text + ": " + (w.checked ? "on" : "off"); }
    void onChoice(Widget@ w) { said.text = "Chosen: " + w.chosenText; }
    void onNumber(Widget@ w) { said.text = "Pressed " + formatInt(w.tag); }
    void onTyped(Widget@ w) { said.text = "Typed: " + (w.secret ? "something" : w.text); }
    void onSave(Widget@ w) { Ui::toast("Saved"); }
    void onToast(Widget@ w) { Ui::toast("Hello! This goes by itself."); }
    void onVolume(Widget@ w) { volumeText.text = formatInt(int(w.value)) + "%"; }
    void onAsk(Widget@ w) { Ui::dialog("Leave the game?", "What you have done since the last save will be lost.", array<string> = { "Stay", "Leave" }, WidgetAnswer(this.onAnswer)); }
    void onAnswer(int which) { said.text = which < 0 ? "Not answered" : which == 0 ? "You stayed" : "You left"; }

    void onPopup(Widget@ w)
    {
        Widget@ popup = Ui::popup();
        popups++;
        popup.label("Popup number " + formatInt(popups), "heading");
        popup.label("Anything can go in one");
        popup.toggle("Like this");
        popup.button("Another on top", WidgetEvent(this.onPopup));
        Widget@ close = popup.button("Close", WidgetEvent(this.onClose));
    }

    void onClose(Widget@ w) { w.parent.close(); }

    void drawn(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place, s = w.size;
        for (int i = 0; i < 5; i++)
        {
            float a = at * (0.4f + float(i) * 0.13f) + float(i);
            c.circle(p.x + s.x * 0.5f + cos(a) * s.x * 0.3f, p.y + s.y * 0.5f + sin(a * 1.3f) * s.y * 0.3f, 34, hsv(float(i) * 0.2f + at * 0.05f, 0.65f, 1));
        }
    }

    void update(float dt)
    {
        at += dt;
        bar.value = 0.5f - 0.5f * cos(at * 0.6f);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        Color top = themeNow == 1 ? Color(0.93f, 0.91f, 0.86f) : themeNow == 2 ? Color(0.1f, 0, 0.16f) : Color(0.07f, 0.09f, 0.15f);
        Color bottom = themeNow == 1 ? Color(0.86f, 0.83f, 0.76f) : themeNow == 2 ? Color(0.02f, 0, 0.06f) : Color(0.03f, 0.04f, 0.07f);
        c.gradient(0, 0, c.width, 720, top, bottom);
        Ui::draw(c);
        if (themeNow == 2)
            c.bloom(0.6f, 0.6f);
    }
}
