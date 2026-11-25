// A grid to choose from, what was chosen turning in space, and numbers that follow. The view is a widget like any other.

class Item
{
    string name, about, model;
    int strength, speed, worth;
    Item(const string &in n, const string &in m, int a, int b, int c, const string &in t)
    {
        name = n; model = m; strength = a; speed = b; worth = c; about = t;
    }
}

class InventoryScreen : Screen
{
    array<Item@> items = {
        Item("Robot", "robot", 60, 70, 900, "It waves at everybody, and means it."),
        Item("Skimmer", "skimmer", 45, 98, 2400, "Never touches the ground it crosses."),
        Item("Lantern", "lantern", 10, 5, 60, "Lights itself when it gets dark."),
        Item("Crystal", "crystal", 80, 20, 1200, "Hums very quietly. Nobody knows why."),
        Item("Campfire", "campfire", 25, 0, 15, "Warm on one side."),
        Item("Mushroom", "mushroom", 5, 0, 3, "Best left where it grows."),
        Item("House", "house", 95, 0, 8000, "Someone is in. There is smoke."),
        Item("Well", "well", 70, 0, 300, "Make a wish. It can't hurt."),
        Item("Gate", "gate", 50, 0, 500, "Go through the middle."),
        Item("Oak", "oak", 65, 0, 120, "A hundred years to make."),
        Item("Pine", "pine", 55, 0, 90, "Green all winter."),
        Item("Rock", "rock", 99, 0, 1, "It is a rock.")
    };
    array<Model@> models;
    array<bool> worn;
    Widget@ list;
    Widget@ name;
    Widget@ about;
    array<Widget@> bars;
    Widget@ wear;
    Entity@ shown;
    float turn = 0, swell = 0;

    InventoryScreen()
    {
        for (uint i = 0; i < items.length(); i++)
        {
            models.insertLast(Assets::model("global:model/" + items[i].model + ".glb"));
            worn.insertLast(false);
        }
    }

    void onEnter()
    {
        Space::sky(Color(0.1f, 0.13f, 0.22f), Color(0.22f, 0.24f, 0.34f));
        Space::ambient(Color(0.5f, 0.52f, 0.6f), Color(0.3f, 0.28f, 0.3f));
        Space::sun(Vec3(0.5f, 0.8f, 0.6f), Color(0.8f, 0.76f, 0.7f));
        Entity@ stand = Space::spawn(Vec3(0, -0.1f, 0));
        stand.shape(SolidCylinder, Color(0.22f, 0.25f, 0.36f));
        stand.size = Vec3(4.4f, 0.2f, 4.4f);
        stand.shine = 0.7f;
        @shown = Space::spawn(Vec3(0, 0, 0));
        Space::shadows(0.6f, 8);

        Widget@ page = Ui::root;
        page.padding = 40;
        page.gap = 16;
        page.label("Inventory", "title");
        Widget@ sides = page.row(24);
        sides.grow = 1;
        sides.align = PlaceStretch;
        Widget@ left = sides.panel();
        left.grow = 1.15f;
        @list = left.list(items.length(), 84, WidgetRow(this.fill));
        list.columns = 2;
        list.onFocus(WidgetEvent(this.onLook));
        list.onClick(WidgetEvent(this.onWear));
        Widget@ right = sides.panel();
        right.grow = 1;
        right.custom(WidgetDraw(this.view)).grow = 1;
        @name = right.label("", "heading");
        @about = right.paragraph("", "small");
        array<string> names = { "Strength", "Speed" };
        for (uint i = 0; i < names.length(); i++)
        {
            Widget@ row = right.row();
            Widget@ label = row.label(names[i]);
            label.width = 130;
            Widget@ bar = row.progress(0);
            bar.grow = 1;
            bars.insertLast(bar);
        }
        @wear = right.button("", WidgetEvent(this.onWear));
        list.focus();
        look();
    }

    void fill(Widget@ row, int i)
    {
        Item@ item = items[uint(i)];
        Widget@ side = row.column(2);
        side.grow = 1;
        side.label(item.name);
        side.label(formatInt(item.worth) + " coins", "small");
        if (worn[uint(i)])
            row.label("in use", "small");
    }

    void onLook(Widget@ w) { look(); }

    void look()
    {
        uint i = uint(list.chosen);
        name.text = items[i].name;
        about.text = items[i].about;
        bars[0].value = float(items[i].strength) / 100;
        bars[1].value = float(items[i].speed) / 100;
        wear.text = worn[i] ? "Put away" : "Use";
        shown.model(models[i]);
        swell = 0;
    }

    void onWear(Widget@ w)
    {
        uint i = uint(list.chosen);
        worn[i] = !worn[i];
        Ui::toast(items[i].name + (worn[i] ? " is in use" : " was put away"));
        list.refresh();
        look();
    }

    void view(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place, s = w.size;
        Space::draw(c, p.x, p.y, s.x, s.y);
    }

    void update(float dt)
    {
        turn += dt * 40;
        swell += (1 - swell) * clamp(dt * 9, 0, 1);
        float high = models[uint(list.chosen)].radius;
        float size = 1.5f / (high > 0.2f ? high : 1.0f) * swell;
        shown.size = Vec3(size, size, size);
        shown.angles = Vec3(0, turn, 0);
        if (list.chosen == 0)
            shown.animate("idle");
        Space::camera(Vec3(0, 2.2f, 5.2f), Vec3(0, 1, 0), 42);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        c.gradient(0, 0, c.width, 720, Color(0.09f, 0.08f, 0.14f), Color(0.03f, 0.03f, 0.06f));
        Ui::draw(c);
    }
}
