// A scene editor, written as any screen is. What it makes is a file that Space::load reads.

class Kind
{
    string label, key, name;
    Vec3 low, high;
    Kind(const string &in l, const string &in k, const string &in n, const Vec3 &in a, const Vec3 &in b)
    {
        label = l; key = k; name = n; low = a; high = b;
    }
}

class Thing
{
    Json@ json;
    Entity@ entity;
    Thing(Json@ j) { @json = j; }
}

class EditorScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 20);
    string file = "asset:scene.json";
    array<Kind@> kinds = {
        Kind("House", "model", "house", Vec3(-3.5f, -0.4f, -3.1f), Vec3(3.5f, 6, 4.2f)),
        Kind("Well", "model", "well", Vec3(-1.2f, -0.4f, -1), Vec3(1.2f, 3.2f, 1)),
        Kind("Lantern", "model", "lantern", Vec3(-0.3f, -0.2f, -0.3f), Vec3(0.3f, 3.4f, 0.3f)),
        Kind("Campfire", "model", "campfire", Vec3(-0.9f, -0.1f, -0.9f), Vec3(0.9f, 0.5f, 0.9f)),
        Kind("Gate", "model", "gate", Vec3(-4.9f, -4.9f, -0.4f), Vec3(4.9f, 4.9f, 0.4f)),
        Kind("Oak", "model", "oak", Vec3(-1.8f, -0.4f, -1.9f), Vec3(2, 5.1f, 1.9f)),
        Kind("Pine", "model", "pine", Vec3(-1.7f, -0.4f, -1.8f), Vec3(1.7f, 6, 1.7f)),
        Kind("Bush", "model", "bush", Vec3(-0.9f, -0.2f, -0.9f), Vec3(1, 0.8f, 0.6f)),
        Kind("Rock", "model", "rock", Vec3(-1, -0.3f, -1), Vec3(1, 0.9f, 1.1f)),
        Kind("Mushroom", "model", "mushroom", Vec3(-0.3f, -0.1f, -0.3f), Vec3(0.3f, 0.6f, 0.3f)),
        Kind("Crystal", "model", "crystal", Vec3(-0.6f, -0.1f, -0.6f), Vec3(0.7f, 1.2f, 0.3f)),
        Kind("Robot", "model", "robot", Vec3(-0.5f, 0, -0.3f), Vec3(0.5f, 2.1f, 0.3f)),
        Kind("Skimmer", "model", "skimmer", Vec3(-1.5f, -0.3f, -1.8f), Vec3(1.5f, 0.9f, 2)),
        Kind("Box", "shape", "box", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)),
        Kind("Ball", "shape", "sphere", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)),
        Kind("Cylinder", "shape", "cylinder", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)),
        Kind("Cone", "shape", "cone", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)),
        Kind("Ring", "shape", "torus", Vec3(-0.5f, -0.2f, -0.5f), Vec3(0.5f, 0.2f, 0.5f)),
        Kind("Capsule", "shape", "capsule", Vec3(-0.5f, -1, -0.5f), Vec3(0.5f, 1, 0.5f)),
        Kind("Light", "glow", "", Vec3(-0.4f, -0.4f, -0.4f), Vec3(0.4f, 0.4f, 0.4f))
    };
    array<Model@> models;
    array<Color> colors = { Color(1, 1, 1), Color(0.35f, 0.37f, 0.42f), Color(0.9f, 0.3f, 0.26f), Color(0.97f, 0.62f, 0.2f), Color(0.98f, 0.86f, 0.35f),
        Color(0.38f, 0.75f, 0.36f), Color(0.3f, 0.75f, 0.85f), Color(0.3f, 0.48f, 0.95f), Color(0.66f, 0.4f, 0.9f), Color(0.95f, 0.5f, 0.72f) };
    array<string> grounds = { "Flat", "Hills", "Island" };
    array<string> hours = { "Day", "Evening", "Night" };
    array<string> tools = { "Move", "Turn", "Size" };

    array<Thing@> things;
    array<Entity@> thrown;
    int chosen = -1, under = -1;
    int ground = 0, hour = 0, tool = 0;
    bool snap = true, playing = false, viewing = false, flying = false, dirty = false;

    // What there was, as text.
    array<string> before, after;
    string now, lastKey;
    float lastAt = 0;
    uint most = 40;

    Vec3 eye(0, 7, 17);
    float yaw = 0, pitch = -20;
    Vec2 mouse;
    bool left = false, carrying = false;
    int axis = -1, hover = -1;   // 0 to 2; 3 is the middle
    bool dragging = false;
    Vec3 offset, startPlace, startAngles, startSize;
    Vec2 startMouse;
    float startAlong = 0;
    array<bool> keys = { false, false, false, false, false, false };
    array<bool> pads = { false, false, false, false };
    Vec2 crossAt;
    float shownFor = 0;

    Widget@ last;
    Widget@ inspector;
    Widget@ nothing;
    Widget@ title;
    array<Widget@> places;
    Widget@ turn;
    Widget@ size;
    Widget@ range;
    Widget@ rangeRow;
    Widget@ onLand;
    Widget@ solid;
    Widget@ falls;
    Widget@ glows;
    Widget@ toolButton;
    Widget@ groundChoice;
    Widget@ hourChoice;
    Widget@ count;
    Widget@ undoButton;
    Widget@ redoButton;

    EditorScreen()
    {
        for (uint i = 0; i < kinds.length(); i++)
            models.insertLast(kinds[i].key == "model" ? Assets::model("global:model/" + kinds[i].name + ".glb") : null);
        most = App::freeKilobytes > 0 && App::freeKilobytes < 64000 ? 12 : 40;
    }

    void onEnter()
    {
        Ui::theme("asset:theme.json");
        build();
        Json j;
        string error;
        if (!j.parse(Assets::read(file), error))
            Ui::toast(error);
        read(j);
        eye.y += Space::height(0, 0);
        now = write().write(true);
        select(-1);
    }

    // --- The panels ---

    void build()
    {
        Widget@ page = Ui::root;
        page.padding = 14;
        page.gap = 10;
        Widget@ top = page.row(8);
        @toolButton = top.button(tools[0], WidgetEvent(this.onTool));
        toolButton.width = 110;
        @undoButton = top.button("Undo", WidgetEvent(this.onUndo));
        @redoButton = top.button("Redo", WidgetEvent(this.onRedo));
        top.space();
        @count = top.label("", "plain");
        top.button("Play", WidgetEvent(this.onPlay));
        top.button("Save", WidgetEvent(this.onSave));

        Widget@ sides = page.row(0);
        sides.grow = 1;
        sides.align = PlaceStretch;
        Widget@ first = sides.panel();
        first.style = "side";
        first.width = 216;
        Widget@ tabs = first.tabs();
        tabs.grow = 1;
        Widget@ add = tabs.tab("Add");
        Widget@ list = add.list(kinds.length(), 42, WidgetRow(this.fill));
        list.grow = 1;
        list.onClick(WidgetEvent(this.onAdd));
        Widget@ scene = tabs.tab("Scene");
        scene.label("Ground", "small");
        @groundChoice = scene.choice(grounds, 0, WidgetEvent(this.onGround));
        scene.label("Time", "small");
        @hourChoice = scene.choice(hours, 0, WidgetEvent(this.onHour));
        scene.toggle("Snap", true, WidgetEvent(this.onSnap));
        scene.button("As saved", WidgetEvent(this.onRevert));
        scene.button("Clear", WidgetEvent(this.onClear));

        sides.space();
        Widget@ other = sides.panel();
        other.style = "side";
        other.width = 286;
        @nothing = other.paragraph("Add something, or choose something in the view.", "small");
        @inspector = other.scroll(8);
        inspector.grow = 1;
        @title = inspector.label("", "heading");
        Widget@ row = inspector.row(6);
        for (uint i = 0; i < 3; i++)
        {
            Widget@ f = row.field("", "", WidgetEvent(this.onPlace));
            f.style = "cell";
            f.numeric = true;
            f.grow = 1;
            f.tag = int(i);
            f.onDone(WidgetEvent(this.onPlace));
            places.insertLast(f);
        }
        inspector.label("Turn", "small");
        @turn = inspector.slider(0, 0, 345, WidgetEvent(this.onTurn));
        turn.step = 15;
        inspector.label("Size", "small");
        @size = inspector.slider(1, 0.1f, 6, WidgetEvent(this.onSize));
        size.step = 0.1f;
        @rangeRow = inspector.column(6);
        rangeRow.label("Reach of its light", "small");
        @range = rangeRow.slider(8, 2, 24, WidgetEvent(this.onRange));
        range.step = 1;
        Widget@ swatches = inspector.grid(5, 6);
        for (uint i = 0; i < colors.length(); i++)
        {
            Widget@ b = swatches.button("", WidgetEvent(this.onColor));
            b.style = "swatch";
            b.tag = int(i);
            Widget@ c = b.custom(WidgetDraw(this.swatch));
            c.height = 22;
            c.grow = 1;
        }
        @onLand = inspector.toggle("On the land", true, WidgetEvent(this.onToggle));
        @solid = inspector.toggle("Solid", false, WidgetEvent(this.onToggle));
        @falls = inspector.toggle("Falls", false, WidgetEvent(this.onToggle));
        @glows = inspector.toggle("Glows", false, WidgetEvent(this.onToggle));
        Widget@ two = inspector.row(8);
        Widget@ copy = two.button("Copy", WidgetEvent(this.onCopy));
        copy.grow = 1;
        Widget@ remove = two.button("Delete", WidgetEvent(this.onDelete));
        remove.grow = 1;
        list.focus();
    }

    void fill(Widget@ row, int i) { row.label(kinds[uint(i)].label); }

    void swatch(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place, s = w.size;
        c.roundRect(p.x, p.y, s.x, s.y, 5, colors[uint(w.parent.tag)]);
    }

    // What the panel says, from what is chosen.
    void show()
    {
        count.text = "" + things.length() + " things" + (dirty ? " *" : "") + "  " ;
        undoButton.enabled = before.length() > 0;
        redoButton.enabled = after.length() > 0;
        toolButton.text = tools[uint(tool)];
        inspector.visible = chosen >= 0;
        nothing.visible = chosen < 0;
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        title.text = kindOf(j).label;
        Vec3 p = j["place"].vec3();
        places[0].text = number(p.x);
        places[1].text = number(p.y);
        places[2].text = number(p.z);
        turn.value = wrapped(angles(j).y);
        size.value = sizes(j).x;
        rangeRow.visible = j.has("light");
        range.value = float(j["range"].number(8));
        onLand.checked = j["onLand"].flag();
        solid.checked = j["wall"].flag();
        falls.checked = j["mass"].number() > 0;
        glows.checked = j["glowing"].number() > 0;
        bool thing = !j.has("glow");
        solid.visible = thing;
        falls.visible = thing;
        glows.visible = thing;
    }

    string number(float v) { return formatFloat(floor(v * 100 + 0.5f) / 100, "", 0, 2); }
    float wrapped(float a) { a = a % 360; return a < 0 ? a + 360 : a; }

    void onTool(Widget@ w) { tool = (tool + 1) % 3; show(); }
    void onSnap(Widget@ w) { snap = w.checked; }
    void onUndo(Widget@ w) { undo(); }
    void onRedo(Widget@ w) { redo(); }
    void onPlay(Widget@ w) { play(true); }
    void onAdd(Widget@ w) { add(uint(w.chosen)); }
    void onGround(Widget@ w) { ground = w.chosen; land(); place(); changed("ground"); }
    void onHour(Widget@ w) { hour = w.chosen; light(); changed("hour"); }
    void onCopy(Widget@ w) { copy(); }
    void onDelete(Widget@ w) { remove(); }

    void onSave(Widget@ w)
    {
        if (!Assets::write(file, write().write()))
        {
            Ui::toast("It couldn't be saved");
            return;
        }
        dirty = false;
        Ui::toast(App::development ? "Saved" : "Saved, on this machine");
        show();
    }

    void onClear(Widget@ w) { Ui::dialog("Clear", "Take everything away? It can be undone.", array<string> = { "Clear", "Keep" }, WidgetAnswer(this.clear)); }
    void clear(int answer)
    {
        if (answer == 0)
        {
            Json j;
            j.set("ground", ground);
            j.set("hour", hour);
            read(j);
            changed("clear");
        }
    }

    void onRevert(Widget@ w)
    {
        Json j;
        string error;
        if (j.parse(Assets::read(file), error))
        {
            read(j);
            changed("revert");
            dirty = false;
            show();
        }
    }

    void onPlace(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        j.set("place", Vec3(parseFloat(places[0].text), parseFloat(places[1].text), parseFloat(places[2].text)));
        put(things[uint(chosen)]);
        changed("place", false);
    }

    void onTurn(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        Vec3 a = angles(j);
        a.y = w.value;
        j.set("angles", a);
        put(things[uint(chosen)]);
        changed("turn", false);
    }

    void onSize(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        Vec3 s = sizes(j);
        s = s * (w.value / (s.x > 0.01f ? s.x : 1.0f));
        resize(j, s);
        put(things[uint(chosen)]);
        changed("size", false);
    }

    void onRange(Widget@ w)
    {
        if (chosen < 0)
            return;
        things[uint(chosen)].json.set("range", w.value);
        make(uint(chosen));
        changed("range", false);
    }

    void onColor(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        Color c = colors[uint(w.tag)];
        if (j.has("light"))
            j.set("light", c);
        j.set("color", j.has("glow") ? fade(c, 0.6f) : c);
        make(uint(chosen));
        changed("color");
    }

    void onToggle(Widget@ w)
    {
        if (chosen < 0)
            return;
        Thing@ t = things[uint(chosen)];
        Json@ j = t.json;
        if (onLand.checked != j["onLand"].flag())
        {
            // It stays where it is.
            Vec3 p = j["place"].vec3();
            p.y += (onLand.checked ? -1 : 1) * Space::height(p.x, p.z);
            j.set("place", p);
            j.set("onLand", onLand.checked);
        }
        setIf(j, "wall", solid.checked);
        setNumberIf(j, "mass", falls.checked, 2);
        setNumberIf(j, "glowing", glows.checked, 0.8f);
        make(uint(chosen));
        changed("toggle");
    }

    void setIf(Json@ j, const string &in key, bool on)
    {
        if (on)
            j.set(key, true);
        else
            j.remove(key);
    }

    void setNumberIf(Json@ j, const string &in key, bool on, float value)
    {
        if (on != (j[key].number() > 0))
        {
            j.remove(key);
            if (on)
                j.set(key, value);
        }
    }

    // --- What there is ---

    Kind@ kindOf(Json@ j)
    {
        string model = j["model"].text(), shape = j["shape"].text();
        for (uint i = 0; i < kinds.length(); i++)
        {
            Kind@ k = kinds[i];
            if (k.key == "model" ? model == "global:model/" + k.name + ".glb" : k.key == "shape" && shape == k.name)
                return k;
        }
        return kinds[kinds.length() - 1];
    }

    Vec3 angles(Json@ j) { return j["angles"].isNumber ? Vec3(0, float(j["angles"].number()), 0) : j["angles"].vec3(); }
    Vec3 sizes(Json@ j)
    {
        if (j.has("glow"))
            return Vec3(1, 1, 1) * float(j["glow"].number(1));
        return j["size"].isNumber ? Vec3(1, 1, 1) * float(j["size"].number()) : j["size"].vec3(Vec3(1, 1, 1));
    }
    void resize(Json@ j, Vec3 s)
    {
        s = Vec3(clamp(s.x, 0.05f, 40), clamp(s.y, 0.05f, 40), clamp(s.z, 0.05f, 40));
        if (j.has("glow"))
            j.set("glow", s.x);
        else
            j.set("size", s);
    }

    Vec3 worldPlace(Json@ j)
    {
        Vec3 p = j["place"].vec3();
        if (j["onLand"].flag())
            p.y += Space::height(p.x, p.z);
        return p;
    }

    Json@ write()
    {
        Json all;
        all.set("ground", ground);
        all.set("hour", hour);
        Json list;
        for (uint i = 0; i < things.length(); i++)
            list.add(things[i].json);
        all.set("entities", list);
        return all;
    }

    void read(Json@ all)
    {
        for (uint i = 0; i < things.length(); i++)
            if (things[i].entity !is null)
                things[i].entity.destroy();
        things.resize(0);
        chosen = -1;
        ground = int(clamp(float(all["ground"].number()), 0, 2));
        hour = int(clamp(float(all["hour"].number()), 0, 2));
        groundChoice.chosen = ground;
        hourChoice.chosen = hour;
        land();
        light();
        Json@ list = all["entities"];
        for (uint i = 0; i < list.count; i++)
        {
            things.insertLast(Thing(list[i]));
            make(i);
        }
        show();
    }

    // Makes its entity again. While editing it only looks like what it is, and has something round it to point at.
    void make(uint i)
    {
        Thing@ t = things[i];
        if (t.entity !is null)
            t.entity.destroy();
        Json j;
        j.copy(t.json);
        Kind@ k = kindOf(j);
        Vec3 s = sizes(j);
        Vec3 wide((k.high.x - k.low.x) * s.x, (k.high.y - k.low.y) * s.y, (k.high.z - k.low.z) * s.z);
        Vec3 middle((k.high.x + k.low.x) * 0.5f * s.x, (k.high.y + k.low.y) * 0.5f * s.y, (k.high.z + k.low.z) * 0.5f * s.z);
        if (!playing)
        {
            array<string> still = { "mass", "walker", "gravity", "wall", "sphere", "cube", "capsule", "behaviour", "group", "hits", "colliderAt", "friction", "bounce", "drag" };
            for (uint n = 0; n < still.length(); n++)
                j.remove(still[n]);
            @t.entity = Space::make(j);
            t.entity.cube(j.has("glow") ? Vec3(1, 1, 1) : wide, 1, 0);
            t.entity.colliderAt = j.has("glow") ? Vec3() : middle;
            return;
        }
        @t.entity = Space::make(j);
        if (j["wall"].flag() || j["mass"].number() > 0)
        {
            if (j["shape"].text() == "sphere")
                t.entity.sphere(wide.x * 0.5f, 0, 0);
            else
                t.entity.cube(wide, 0, 0);
            t.entity.colliderAt = middle;
            t.entity.wall = true;
            if (j["mass"].number() > 0)
            {
                t.entity.wall = false;
                t.entity.mass = float(j["mass"].number());
                t.entity.gravity = 1;
                t.entity.friction = 0.6f;
                t.entity.bounce = j["shape"].text() == "sphere" ? 0.5f : 0.1f;
            }
        }
    }

    // Puts its entity where it is.
    void put(Thing@ t)
    {
        t.entity.place = worldPlace(t.json);
        t.entity.angles = angles(t.json);
        t.entity.size = sizes(t.json);
    }

    void place()
    {
        for (uint i = 0; i < things.length(); i++)
            put(things[i]);
    }

    void land()
    {
        if (ground == 0)
        {
            Space::land(1, 32, 4, 0.001f);
            Space::landColors(Color(0.42f, 0.56f, 0.34f), Color(0.42f, 0.56f, 0.34f), Color(0.42f, 0.56f, 0.34f), Color(0.4f, 0.4f, 0.4f), -1, 1);
        }
        else
        {
            Space::land(ground == 1 ? 7 : 12, 64, 2, ground == 1 ? 7 : 12, 0.45f, ground == 2);
            Space::landColors(Color(0.78f, 0.7f, 0.48f), Color(0.36f, 0.52f, 0.28f), Color(0.5f, 0.56f, 0.36f), Color(0.45f, 0.42f, 0.4f), ground == 2 ? 0.8f : -20, 7);
            // Room to build on.
            Space::flatten(0, 0, 24, ground == 2 ? 2.5f : Space::height(0, 0));
        }
        Space::water(ground == 2 ? 0.0f : -60, Color(0.16f, 0.4f, 0.5f, 0.8f));
    }

    void light()
    {
        Color top = hour == 0 ? Color(0.25f, 0.5f, 0.85f) : hour == 1 ? Color(0.25f, 0.24f, 0.45f) : Color(0.015f, 0.02f, 0.06f);
        Color low = hour == 0 ? Color(0.72f, 0.83f, 0.92f) : hour == 1 ? Color(0.95f, 0.6f, 0.4f) : Color(0.07f, 0.09f, 0.17f);
        Space::sky(top, low);
        Space::fog(low, 60, 170);
        Space::farthest(180);
        Space::sun(hour == 1 ? Vec3(0.8f, 0.3f, -0.4f) : Vec3(0.45f, 0.8f, 0.4f), hour == 0 ? Color(0.95f, 0.9f, 0.8f) : hour == 1 ? Color(0.9f, 0.5f, 0.3f) : Color(0.16f, 0.2f, 0.32f));
        Space::ambient(hour == 0 ? Color(0.42f, 0.46f, 0.55f) : hour == 1 ? Color(0.34f, 0.3f, 0.4f) : Color(0.12f, 0.14f, 0.24f), hour == 0 ? Color(0.25f, 0.24f, 0.2f) : Color(0.1f, 0.09f, 0.1f));
        Space::shadows(hour == 2 ? 0.35f : 0.6f, 34);
    }

    // --- Undoing ---

    // Once for each change. What goes on changing, such as a slider, is one.
    void changed(const string &in key, bool apart = true)
    {
        string text = write().write(true);
        if (text == now)
        {
            show();
            return;
        }
        string named = key + chosen;
        if (apart || named != lastKey || App::time - lastAt > 1.5f || before.length() == 0)
        {
            before.insertLast(now);
            if (before.length() > most)
                before.removeAt(0);
        }
        lastKey = apart ? "" : named;
        lastAt = App::time;
        now = text;
        after.resize(0);
        dirty = true;
        show();
    }

    void back(const string &in text)
    {
        int was = chosen;
        Json j;
        string error;
        if (j.parse(text, error))
        {
            read(j);
            now = text;
            dirty = true;
            lastKey = "";
            select(was < int(things.length()) ? was : -1);
        }
    }

    void undo()
    {
        if (before.length() == 0)
            return;
        after.insertLast(now);
        string text = before[before.length() - 1];
        before.removeLast();
        back(text);
    }

    void redo()
    {
        if (after.length() == 0)
            return;
        before.insertLast(now);
        string text = after[after.length() - 1];
        after.removeLast();
        back(text);
    }

    // --- Doing things ---

    void select(int i)
    {
        chosen = i;
        show();
    }

    void add(uint which)
    {
        if (things.length() >= 150)
        {
            Ui::toast("That is enough for one scene");
            return;
        }
        Kind@ k = kinds[which];
        Vec3 p;
        Vec3 ahead = look();
        if (!onGround(eye, ahead, p) || (p - eye).length() > 40)
            p = eye + Vec3(ahead.x, 0, ahead.z).normalized() * 14;
        Json j;
        if (k.key == "model")
            j.set("model", "global:model/" + k.name + ".glb");
        else if (k.key == "shape")
        {
            j.set("shape", k.name);
            j.set("color", Color(0.97f, 0.62f, 0.2f));
        }
        else
        {
            j.set("glow", 1.2f);
            j.set("color", Color(1, 0.8f, 0.5f, 0.6f));
            j.set("light", Color(1, 0.75f, 0.45f));
            j.set("range", 9);
        }
        j.set("place", snapped(Vec3(p.x, k.key == "model" ? 0.0f : k.key == "shape" ? -k.low.y : 1.5f, p.z)));
        j.set("onLand", true);
        things.insertLast(Thing(j));
        make(things.length() - 1);
        select(int(things.length()) - 1);
        changed("add");
    }

    void copy()
    {
        if (chosen < 0 || things.length() >= 150)
            return;
        Json j;
        j.copy(things[uint(chosen)].json);
        Kind@ k = kindOf(j);
        j.set("place", j["place"].vec3() + Vec3((k.high.x - k.low.x) * sizes(j).x + 0.3f, 0, 0));
        things.insertLast(Thing(j));
        make(things.length() - 1);
        select(int(things.length()) - 1);
        changed("copy");
    }

    void remove()
    {
        if (chosen < 0)
            return;
        things[uint(chosen)].entity.destroy();
        things.removeAt(uint(chosen));
        select(-1);
        changed("remove");
    }

    void play(bool on)
    {
        playing = on;
        for (uint i = 0; i < thrown.length(); i++)
            thrown[i].destroy();
        thrown.resize(0);
        for (uint i = 0; i < things.length(); i++)
            make(i);
        shownFor = 0;
    }

    void throwBall()
    {
        if (thrown.length() >= 12)
        {
            thrown[0].destroy();
            thrown.removeAt(0);
        }
        Entity@ e = Space::spawn(eye + look() * 1.5f);
        e.shape(SolidSphere, colors[2 + thrown.length() % 8]);
        e.size = Vec3(0.7f, 0.7f, 0.7f);
        e.sphere(0.35f, 0, 0);
        e.mass = 3;
        e.gravity = 1;
        e.bounce = 0.5f;
        e.friction = 0.5f;
        e.motion = look() * 22;
        thrown.insertLast(e);
    }

    Vec3 look()
    {
        float y = yaw * 0.0174533f, p = pitch * 0.0174533f;
        return Vec3(sin(y) * cos(p), sin(p), -cos(y) * cos(p));
    }

    bool onGround(const Vec3 &in from, const Vec3 &in along, Vec3 &out hit)
    {
        Vec3 normal;
        return Space::raycast(from, from + along * 220, hit, normal, 1);
    }

    Vec3 snapped(Vec3 p)
    {
        if (snap)
        {
            p.x = floor(p.x * 2 + 0.5f) * 0.5f;
            p.z = floor(p.z * 2 + 0.5f) * 0.5f;
        }
        return p;
    }

    int at(const Vec3 &in along)
    {
        Vec3 hit;
        Entity@ e = Space::pick(eye, eye + along * 160, hit, 2);
        for (uint i = 0; e !is null && i < things.length(); i++)
            if (things[i].entity is e)
                return int(i);
        return -1;
    }

    // --- Moving about ---

    bool tapped(uint which, const string &in name)
    {
        bool down = Input::key(name), was = keys[which];
        keys[which] = down;
        return down && !was;
    }

    bool padTapped(uint which, uint button)
    {
        bool down = Input::padButton(0, button), was = pads[which];
        pads[which] = down;
        return down && !was;
    }

    void fly(const Vec2 &in move, float up, float dt)
    {
        Vec3 ahead = look();
        Vec3 right = ahead.cross(Vec3(0, 1, 0)).normalized();
        eye += (right * move.x - ahead * move.y + Vec3(0, up, 0)) * (dt * 12);
        eye = Vec3(clamp(eye.x, -110, 110), clamp(eye.y, -2, 60), clamp(eye.z, -110, 110));
        float least = Space::height(eye.x, eye.z) + 0.6f;
        eye.y = eye.y < least ? least : eye.y;
    }

    void turnBy(float x, float y)
    {
        yaw += x;
        pitch = clamp(pitch + y, -86, 70);
    }

    void update(float dt)
    {
        shownFor += dt;
        Vec2 m = Input::mouse;
        Vec2 moved = m - mouse;
        mouse = m;
        bool right = Input::mouseDown(1) && Input::hasMouse, pressed = Input::mouseDown(0) && !left;
        left = Input::mouseDown(0);
        if (right && !Ui::busy)
            turnBy(moved.x * 0.22f, -moved.y * 0.22f);
        Vec2 stick = Input::padRight(0);
        turnBy(stick.x * dt * 110, stick.y * dt * 80);
        Vec2 triggers = Input::padTriggers(0);

        // With the right button held, keys move the camera instead.
        Vec2 move = Input::move;
        bool wasFlying = flying;
        flying = right && (wasFlying || move.x != 0 || move.y != 0);
        bool free = viewing || playing;
        if (free || flying)
            fly(move, free ? triggers.y - triggers.x : 0.0f, dt);
        if (!Ui::busy && overView(mouse) && Input::wheel != 0)
            eye += look() * (Input::wheel * 1.5f);
        if (Input::mouseDown(2) && Input::hasMouse && !Ui::busy)
        {
            Vec3 side = look().cross(Vec3(0, 1, 0)).normalized();
            eye += side * (-moved.x * 0.03f) + Vec3(0, moved.y * 0.03f, 0);
        }
        bool panels = !free && !flying;
        if (Ui::root.visible && !panels)
            @last = Ui::focused;
        if (panels && !Ui::root.visible)
        {
            Ui::root.visible = true;
            if (last !is null)
                last.focus();
        }
        Ui::root.visible = panels;
        Space::camera(eye, eye + look(), 60);

        if (playing)
        {
            if (Input::pressed("accept"))
                throwBall();
            if (Input::pressed("cancel") || Input::pressed("alternate"))
                play(false);
            return;
        }
        if (Ui::busy || Ui::typing)
            return;
        shortcuts();
        if (viewing)
        {
            inView(dt);
            return;
        }
        if (Input::pressed("alternate") && !right && !Input::key("Shift"))
        {
            enterView(true);
            return;
        }
        if (tapped(5, "Tab"))
        {
            enterView(true);
            return;
        }
        withMouse(pressed);
    }

    void enterView(bool on)
    {
        viewing = on;
        carrying = false;
        shownFor = 0;
        if (!on)
            show();
    }

    void shortcuts()
    {
        bool control = Input::key("Control");
        bool z = tapped(0, "Z"), y = tapped(1, "Y"), d = tapped(2, "C");
        if (control && z)
            undo();
        if (control && y)
            redo();
        if (control && d)
            copy();
        if (control && tapped(3, "X"))
            remove();
        for (uint i = 0; i < 3; i++)
            if (Input::key("" + (i + 1)) && tool != int(i))
            {
                tool = int(i);
                toolButton.text = tools[uint(tool)];
            }
    }

    // With a gamepad: what is in the middle of the picture is taken, carried and put down.
    void inView(float dt)
    {
        Vec3 ahead = look();
        under = carrying ? chosen : at(ahead);
        if (Input::pressed("alternate") || tapped(5, "Tab"))
        {
            if (carrying)
                changed("carry");
            enterView(false);
            return;
        }
        if (Input::pressed("accept"))
        {
            if (carrying)
            {
                carrying = false;
                changed("carry");
            }
            else
            {
                select(under);
                carrying = under >= 0;
                Vec3 p;
                if (carrying)
                {
                    Vec3 hit;
                    startPlace = things[uint(chosen)].json["place"].vec3();
                    offset = onGround(eye, ahead, hit) && (hit - eye).length() < 60 ? worldPlace(things[uint(chosen)].json) - hit : Vec3();
                    if (offset.length() > 12)
                        offset = Vec3();
                }
            }
        }
        if (Input::pressed("cancel"))
        {
            if (carrying)
            {
                // Back where it was.
                carrying = false;
                things[uint(chosen)].json.set("place", startPlace);
                put(things[uint(chosen)]);
            }
            else if (chosen >= 0)
                select(-1);
        }
        bool turnLeft = padTapped(0, 12), turnRight = padTapped(1, 13), again = padTapped(2, 11);
        if (chosen >= 0 && (turnLeft || turnRight))
        {
            Json@ j = things[uint(chosen)].json;
            Vec3 a = angles(j);
            a.y = wrapped(a.y + (turnLeft ? 15 : -15));
            j.set("angles", a);
            put(things[uint(chosen)]);
            if (!carrying)
                changed("turn", false);
        }
        if (again && !carrying)
            copy();
        if (carrying)
        {
            Vec3 hit;
            if (onGround(eye, ahead, hit) && (hit - eye).length() < 70)
            {
                Json@ j = things[uint(chosen)].json;
                Vec3 p = snapped(hit + offset);
                p.y = j["place"].vec3().y;
                j.set("place", p);
                put(things[uint(chosen)]);
            }
        }
    }

    bool overView(const Vec2 &in p) { return p.y > 82 && p.x > 240 && p.x < wide - 308; }
    float wide = 1280;

    void withMouse(bool pressed)
    {
        if (!Input::hasMouse)
            return;
        if (dragging)
        {
            if (Input::mouseDown(0))
                drag();
            else
            {
                dragging = false;
                changed("drag");
            }
            return;
        }
        hover = chosen >= 0 ? handleAt(mouse) : -1;
        if (!overView(mouse) && !(hover >= 0))
            return;
        if (!pressed || !overView(mouse))
            return;
        Vec3 along = Space::ray(mouse);
        if (hover < 0)
        {
            select(at(along));
            hover = 3;
            if (chosen < 0)
                return;
        }
        Json@ j = things[uint(chosen)].json;
        axis = hover;
        dragging = true;
        startMouse = mouse;
        startPlace = j["place"].vec3();
        startAngles = angles(j);
        startSize = sizes(j);
        Vec3 hit;
        offset = onGround(eye, along, hit) ? worldPlace(j) - hit : Vec3();
        startAlong = axis < 3 ? alongAxis(worldPlace(j), unit(axis), along) : 0.0f;
    }

    Vec3 unit(int i) { return Vec3(i == 0 ? 1 : 0, i == 1 ? 1 : 0, i == 2 ? 1 : 0); }

    // How far along an axis a ray comes closest to it.
    float alongAxis(const Vec3 &in origin, const Vec3 &in a, const Vec3 &in d)
    {
        Vec3 w = origin - eye;
        float b = a.dot(d), n = 1 - b * b;
        return n > 0.001f ? (b * d.dot(w) - a.dot(w)) / n : 0.0f;
    }

    void drag()
    {
        Thing@ t = things[uint(chosen)];
        Vec3 along = Space::ray(mouse);
        Vec2 moved = mouse - startMouse;
        if (moved.dot(moved) < 9 && axis == 3)
            return;
        if (tool == 0)
        {
            Vec3 p = startPlace;
            if (axis == 3)
            {
                Vec3 hit;
                if (!onGround(eye, along, hit) || (hit - eye).length() > 120)
                    return;
                p = snapped(hit + offset);
                p.y = startPlace.y;
            }
            else
            {
                Vec3 base = worldPlace(t.json);
                Vec3 origin = startPlace + (base - t.json["place"].vec3());
                float by = alongAxis(origin, unit(axis), along) - startAlong;
                by = snap ? floor(by * 4 + 0.5f) * 0.25f : by;
                p = startPlace + unit(axis) * clamp(by, -60, 60);
            }
            t.json.set("place", p);
        }
        else if (tool == 1)
        {
            float by = moved.x * 0.6f;
            by = snap ? floor(by / 15 + 0.5f) * 15 : by;
            t.json.set("angles", startAngles + unit(axis == 3 ? 1 : axis) * by);
        }
        else
        {
            float by = clamp(1 + (moved.x - moved.y) * 0.008f, 0.05f, 20);
            Vec3 s = startSize;
            if (axis == 3 || t.json.has("glow"))
                s = s * by;
            else
                s += unit(axis) * ((axis == 0 ? s.x : axis == 1 ? s.y : s.z) * (by - 1));
            resize(t.json, s);
        }
        put(t);
        show();
    }

    // --- Drawing ---

    float reach() { return clamp((worldPlace(things[uint(chosen)].json) - eye).length() * 0.16f, 0.5f, 8); }

    int handleAt(const Vec2 &in p)
    {
        Vec3 o = worldPlace(things[uint(chosen)].json);
        Vec2 from;
        if (!Space::toScreen(o, from))
            return -1;
        for (int i = 0; i < 3; i++)
        {
            Vec2 to;
            if (Space::toScreen(o + unit(i) * reach(), to) && near(p, from + (to - from) * 0.25f, to + (to - from) * 0.12f) < 10)
                return i;
        }
        Vec2 d = p - from;
        return d.dot(d) < 144 ? 3 : -1;
    }

    float near(const Vec2 &in p, const Vec2 &in a, const Vec2 &in b)
    {
        Vec2 ab = b - a, ap = p - a;
        float l = ab.dot(ab);
        float t = l > 0.01f ? clamp(ap.dot(ab) / l, 0, 1) : 0.0f;
        Vec2 d = ap - ab * t;
        return sqrt(d.dot(d));
    }

    void box(Canvas@ c, Thing@ t, const Color &in color)
    {
        if (t.entity is null || !t.entity.alive)
            return;
        Kind@ k = kindOf(t.json);
        bool glow = t.json.has("glow");
        array<Vec2> at(8);
        for (uint i = 0; i < 8; i++)
        {
            Vec3 p((i & 1) != 0 ? k.high.x : k.low.x, (i & 2) != 0 ? k.high.y : k.low.y, (i & 4) != 0 ? k.high.z : k.low.z);
            if (glow)
                p = p * (1 / (t.entity.size.x > 0.1f ? t.entity.size.x : 0.1f));
            if (!Space::toScreen(t.entity.toSpace(p), at[i]))
                return;
        }
        for (uint i = 0; i < 8; i++)
            for (uint b = 1; b < 8; b *= 2)
                if ((i & b) == 0)
                    c.line(at[i].x, at[i].y, at[i | b].x, at[i | b].y, 1.5f, color);
    }

    void handles(Canvas@ c)
    {
        Vec3 o = worldPlace(things[uint(chosen)].json);
        Vec2 from;
        if (!Space::toScreen(o, from))
            return;
        array<Color> own = { Color(0.95f, 0.35f, 0.32f), Color(0.45f, 0.85f, 0.4f), Color(0.4f, 0.6f, 1) };
        for (int i = 0; i < 3; i++)
        {
            Vec2 to;
            if (!Space::toScreen(o + unit(i) * reach(), to))
                continue;
            bool on = dragging ? axis == i : hover == i;
            Color color = on ? Color(1, 0.95f, 0.5f) : own[uint(i)];
            c.line(from.x, from.y, to.x, to.y, on ? 5 : 3, color);
            if (tool == 0)
            {
                Vec2 d = to - from;
                float l = sqrt(d.dot(d));
                if (l > 6)
                {
                    d = d / l;
                    Vec2 side(-d.y, d.x);
                    c.triangle(to + d * 15, to + side * 7, to - side * 7, color, color, color);
                }
            }
            else if (tool == 1)
                c.ring(to.x, to.y, 9, 3, color);
            else
                c.rect(to.x - 6, to.y - 6, 12, 12, color);
        }
        bool on = dragging ? axis == 3 : hover == 3;
        c.circle(from.x, from.y, 7, on ? Color(1, 0.95f, 0.5f) : White);
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        wide = c.width;
        Space::draw(c);
        if (!playing)
        {
            if (viewing && under >= 0 && under != chosen && under < int(things.length()))
                box(c, things[uint(under)], Color(1, 1, 1, 0.5f));
            if (chosen >= 0)
            {
                box(c, things[uint(chosen)], Color(1, 0.75f, 0.25f, 0.9f));
                if (!viewing)
                    handles(c);
            }
        }
        if (viewing || playing)
        {
            float x = wide * 0.5f;
            c.line(x - 11, 360, x - 4, 360, 2, Color(1, 1, 1, 0.8f));
            c.line(x + 4, 360, x + 11, 360, 2, Color(1, 1, 1, 0.8f));
            c.line(x, 349, x, 356, 2, Color(1, 1, 1, 0.8f));
            c.line(x, 364, x, 371, 2, Color(1, 1, 1, 0.8f));
            string text = playing ? "Accept throws a ball      Cancel goes back to editing"
                : carrying ? "Accept puts it down      Shoulders turn it      Cancel puts it back"
                : "Accept takes what is in the middle      Alternate brings the panels back";
            Vec2 s = font.measure(text);
            c.roundRect(x - s.x * 0.5f - 18, 660, s.x + 36, 38, 19, Color(0, 0, 0, 0.5f));
            c.text(font, text, x, 667, Color(0.9f, 0.94f, 1), AlignCenter);
        }
        Ui::draw(c);
    }
}
