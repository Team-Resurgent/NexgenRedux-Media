// A list makes only the rows that can be seen, and uses them again as it scrolls. Type to find.

class LongListScreen : Screen
{
    Widget@ list;
    Widget@ field;
    Widget@ status;
    array<int> found;
    int made = 0;
    array<string> first = { "Quiet", "Amber", "Northern", "Paper", "Copper", "Silver", "Hidden", "Second", "Winter", "Velvet", "Broken", "Golden", "Distant", "Little", "Electric", "Slow" };
    array<string> second = { "River", "Lantern", "Machine", "Garden", "Signal", "Harbour", "Comet", "Orchard", "Station", "Mirror", "Valley", "Engine", "Circus", "Island", "Letter", "Thunder" };
    array<string> third = { "of Dawn", "Road", "Blues", "Parade", "in June", "Theory", "at Sea", "Waltz", "Revisited", "for Two" };

    string name(int i) { return first[uint(i * 7) % first.length()] + " " + second[uint(i * 13 + i / 16) % second.length()] + " " + third[uint(i * 3 + i / 160) % third.length()]; }

    void onEnter()
    {
        Widget@ page = Ui::root;
        page.padding = 44;
        page.gap = 14;
        Widget@ top = page.row();
        top.label("Long list", "title").grow = 1;
        @field = top.field("", "Find", WidgetEvent(this.onFind));
        field.width = 360;
        @list = page.list(0, 58, WidgetRow(this.fill));
        list.columns = 2;
        list.onClick(WidgetEvent(this.onClick));
        @status = page.label("", "small");
        find("");
        list.focus();
    }

    void find(const string &in what)
    {
        found.resize(0);
        for (int i = 0; i < 10000; i++)
            if (what == "" || lower(name(i)).findFirst(lower(what)) >= 0)
                found.insertLast(i);
        list.count = found.length();
    }

    string lower(const string &in text)
    {
        string small = text;
        for (uint i = 0; i < small.length(); i++)
            if (small[i] >= 65 && small[i] <= 90)
                small[i] = small[i] + 32;
        return small;
    }

    void fill(Widget@ row, int i)
    {
        made++;
        int which = found[uint(i)];
        Widget@ swatch = row.custom(WidgetDraw(this.swatch));
        swatch.width = 34;
        swatch.height = 34;
        swatch.tag = which;
        row.label(name(which)).grow = 1;
        row.label("#" + formatInt(which + 1), "small");
    }

    void swatch(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place;
        c.roundRect(p.x, p.y, 34, 34, 8, hsv(float(w.tag % 97) / 97.0f, 0.6f, 0.85f));
        c.circle(p.x + 17, p.y + 17, 6 + float(w.tag % 5), Color(1, 1, 1, 0.5f));
    }

    void onFind(Widget@ w) { find(w.text); }
    void onClick(Widget@ w) { Ui::toast("Played " + name(found[uint(w.chosen)])); }

    void update(float dt)
    {
        status.text = formatInt(int(found.length())) + " rows, " + formatInt(int(list.children)) + " of them real, filled " + formatInt(made) + " times";
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        c.gradient(0, 0, c.width, 720, Color(0.08f, 0.08f, 0.13f), Color(0.03f, 0.03f, 0.06f));
        Ui::draw(c);
    }
}
