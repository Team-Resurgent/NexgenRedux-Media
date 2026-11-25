// The home screen: a tile for every other screen that was found.

class MainScreen : Screen
{
    Widget@ list;
    Widget@ status;
    array<uint> tiles;      // indices of the screens on offer
    Color accent(const string &in category)
    {
        if (category == "Drawing") return Blue;
        if (category == "Sprites") return Green;
        if (category == "Effects") return Purple;
        if (category == "Interface") return Orange;
        if (category == "Games") return Red;
        if (category == "Sound") return Yellow;
        if (category == "Scene") return Color(0.35f, 0.85f, 0.85f);
        if (category == "3D") return Color(1, 0.45f, 0.7f);
        if (category == "Network") return Color(0.55f, 0.6f, 1);
        return Gray;
    }

    void onEnter()
    {
        for (uint i = 0; i < Screens::count; i++)
            if (Screens::id(i) != "main")
                tiles.insertLast(i);

        Ui::theme("asset:theme.json");
        Widget@ page = Ui::root;
        page.pad(52, 40, 52, 14);
        page.gap = 18;
        Widget@ top = page.row();
        Widget@ names = top.column(2);
        names.grow = 1;
        names.label("Nexgen", "title");
        names.label("A showcase of the engine. Every tile is one script.", "small");
        @status = top.label("", "small");
        status.self = PlaceStart;
        @list = page.list(tiles.length(), 118, WidgetRow(this.fill));
        list.gap = 16;
        list.columnWidth = 250;
        list.onClick(WidgetEvent(this.onOpen));
        Widget@ help = page.label(Input::usingPad ? "A  open     Start  menu     Hold Back  menu from anywhere" : "Enter  open     Arrows  move     Escape  menu from anywhere", "small");
        help.self = PlaceCenter;
    }

    void fill(Widget@ row, int i)
    {
        uint screen = tiles[uint(i)];
        row.align = PlaceStretch;
        Widget@ stripe = row.custom(WidgetDraw(this.stripe));
        stripe.width = 6;
        stripe.height = 28;
        stripe.tag = i;
        Widget@ text = row.column(6);
        text.grow = 1;
        text.label(Screens::title(screen), "tile");
        text.paragraph(Screens::description(screen), "small");
    }

    void stripe(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place;
        c.roundRect(p.x, p.y + 3, 6, 25, 3, accent(Screens::category(tiles[uint(w.tag)])));
    }

    void onOpen(Widget@ w) { Screens::push(Screens::id(tiles[uint(w.chosen)])); }

    void update(float dt)
    {
        status.text = App::platform + "  |  " + App::gpu + "  |  " + formatInt(int(App::fps + 0.5f)) + " fps";
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        c.gradient(0, 0, c.width, 720, Color(0.07f, 0.09f, 0.16f), Color(0.03f, 0.03f, 0.06f));
        for (uint i = 0; i < 5; i++)
        {
            float t = App::time * 0.15f + float(i) * 1.3f;
            c.circle(c.width * 0.5f + sin(t) * 620, 360 + cos(t * 1.3f) * 330, 160, fade(hsv(0.55f + float(i) * 0.05f, 0.7f, 0.9f), 0.05f));
        }
        Ui::draw(c);
    }
}
