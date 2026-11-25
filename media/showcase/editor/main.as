#include "global:scene.as"

// A scene editor, written as any screen is. What it makes is a file that Space::load reads.

// Where a cave piece goes on.
class Exit
{
    Vec3 place;
    Exit(const Vec3 &in p) { place = p; }
}

class Kind
{
    string group, label, key, name;
    Vec3 low, high;
    float size = 1;            // it starts at
    int collider = 0;          // it starts with
    float stem = 0;            // how thick a pill is, if that isn't from its size
    Model@ own;                // until its size is known
    array<Exit@> exits;        // the first is the way in
    Kind(const string &in g, const string &in l, const string &in k, const string &in n, const Vec3 &in a, const Vec3 &in b, int c = 0, float thick = 0)
    {
        stem = thick;
        group = g; label = l; key = k; name = n; low = a; high = b; collider = c;
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
        Kind("Platforms", "Platform", "model", "platform", Vec3(-2, 0, -2), Vec3(2, 0.53f, 2), 1),
        Kind("Platforms", "Round one", "model", "platform-round", Vec3(-2, 0, -2), Vec3(2, 0.5f, 2), 1),
        Kind("Platforms", "Moving one", "moving", "platform", Vec3(-2, 0, -2), Vec3(2, 0.53f, 2), 1),
        Kind("Platforms", "Lift", "lift", "platform-round", Vec3(-2, 0, -2), Vec3(2, 0.5f, 2), 1),
        Kind("Platforms", "Ramp", "model", "ramp", Vec3(-1.5f, 0, -2.5f), Vec3(1.5f, 2, 2.5f), 4),
        Kind("Platforms", "Stairs", "model", "stairs", Vec3(-1.5f, 0, -2), Vec3(1.5f, 2, 2), 4),
        Kind("Platforms", "Bridge", "model", "bridge", Vec3(-1.4f, -0.23f, -5), Vec3(1.4f, 1.1f, 5), 4),
        Kind("Roads", "Straight", "model", "road-straight", Vec3(-4, 0, -4), Vec3(4, 0.12f, 4)),
        Kind("Roads", "Corner", "model", "road-bend", Vec3(-4, 0, -4), Vec3(4, 0.12f, 4)),
        Kind("Roads", "Junction", "model", "road-t", Vec3(-4, 0, -4), Vec3(4, 0.12f, 4)),
        Kind("Roads", "Crossroads", "model", "road-cross", Vec3(-4, 0, -4), Vec3(4, 0.12f, 4)),
        Kind("Roads", "Dead end", "model", "road-end", Vec3(-4, 0, -4), Vec3(4, 0.12f, 4)),
        Kind("Nature", "Oak", "model", "oak", Vec3(-1.8f, -0.4f, -1.9f), Vec3(2, 5.1f, 1.9f), 3, 0.35f),
        Kind("Nature", "Pine", "model", "pine", Vec3(-1.7f, -0.4f, -1.8f), Vec3(1.7f, 6, 1.7f), 3, 0.3f),
        Kind("Nature", "Bush", "model", "bush", Vec3(-0.9f, -0.2f, -0.9f), Vec3(1, 0.8f, 0.6f)),
        Kind("Nature", "Rock", "model", "rock", Vec3(-1, -0.3f, -1), Vec3(1, 0.9f, 1.1f), 2),
        Kind("Nature", "Mushroom", "model", "mushroom", Vec3(-0.3f, -0.1f, -0.3f), Vec3(0.3f, 0.6f, 0.3f)),
        Kind("Nature", "Crystal", "model", "crystal", Vec3(-0.6f, -0.1f, -0.6f), Vec3(0.7f, 1.2f, 0.3f), 1),
        Kind("Nature", "Pool", "water", "", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)),
        Kind("Buildings", "House", "model", "house", Vec3(-3.5f, -0.4f, -3.1f), Vec3(3.5f, 6, 4.2f), 1),
        Kind("Buildings", "Well", "model", "well", Vec3(-1.2f, -0.4f, -1), Vec3(1.2f, 3.2f, 1), 1),
        Kind("Buildings", "Lantern", "model", "lantern", Vec3(-0.3f, -0.2f, -0.3f), Vec3(0.3f, 3.4f, 0.3f), 3),
        Kind("Buildings", "Campfire", "model", "campfire", Vec3(-0.9f, -0.1f, -0.9f), Vec3(0.9f, 0.5f, 0.9f)),
        Kind("Buildings", "Gate", "model", "gate", Vec3(-4.9f, -4.9f, -0.4f), Vec3(4.9f, 4.9f, 0.4f), 4),
        Kind("Buildings", "Wall", "model", "wall", Vec3(-2, 0, -0.2f), Vec3(2, 2.5f, 0.2f), 1),
        Kind("Buildings", "Column", "model", "column", Vec3(-0.55f, 0, -0.55f), Vec3(0.55f, 3.9f, 0.55f), 3),
        Kind("Caves", "Way down", "model", "cave-mouth", Vec3(-3.4f, -5, -4), Vec3(3.4f, 4.4f, 4.9f), 4),
        Kind("Caves", "Mine", "model", "cave-mouth-mine", Vec3(-3.4f, -5, -4), Vec3(3.4f, 4.4f, 4.9f), 4),
        Kind("Caves", "Tunnel", "model", "cave-tunnel", Vec3(-2.6f, 0, -4), Vec3(2.6f, 3.6f, 4), 4),
        Kind("Caves", "Bend", "model", "cave-bend", Vec3(-2.6f, 0, -2.6f), Vec3(4, 3.6f, 4), 4),
        Kind("Caves", "Slope", "model", "cave-slope", Vec3(-2.6f, -5, -4), Vec3(2.6f, 3.6f, 4), 4),
        Kind("Caves", "Room", "model", "cave-room", Vec3(-8, 0, -8), Vec3(8, 4.9f, 8), 4),
        Kind("Caves", "Fork", "model", "cave-fork", Vec3(-4.5f, 0, -4.5f), Vec3(4.5f, 4.9f, 4.5f), 4),
        Kind("Caves", "Crossing", "model", "cave-cross", Vec3(-4.5f, 0, -4.5f), Vec3(4.5f, 4.9f, 4.5f), 4),
        Kind("Caves", "Hall", "model", "cave-hall", Vec3(-8, 0, -8), Vec3(8, 4.9f, 8), 4),
        Kind("Caves", "Rough tunnel", "model", "cave-tunnel-2", Vec3(-2.6f, 0, -4), Vec3(2.6f, 3.6f, 4), 4),
        Kind("Caves", "Rough bend", "model", "cave-bend-2", Vec3(-2.6f, 0, -2.6f), Vec3(4, 3.6f, 4), 4),
        Kind("Caves", "End", "model", "cave-end", Vec3(-2.6f, 0, -1), Vec3(2.6f, 3.6f, 4), 4),
        Kind("Shapes", "Box", "shape", "box", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f), 1),
        Kind("Shapes", "Ball", "shape", "sphere", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f), 2),
        Kind("Shapes", "Cylinder", "shape", "cylinder", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f), 1),
        Kind("Shapes", "Cone", "shape", "cone", Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f), 1),
        Kind("Shapes", "Ring", "shape", "torus", Vec3(-0.5f, -0.2f, -0.5f), Vec3(0.5f, 0.2f, 0.5f)),
        Kind("Shapes", "Capsule", "shape", "capsule", Vec3(-0.5f, -1, -0.5f), Vec3(0.5f, 1, 0.5f), 3),
        Kind("Others", "Robot", "model", "robot", Vec3(-0.5f, 0, -0.3f), Vec3(0.5f, 2.1f, 0.3f), 3),
        Kind("Others", "Skimmer", "model", "skimmer", Vec3(-1.5f, -0.3f, -1.8f), Vec3(1.5f, 0.9f, 2), 1),
        Kind("Others", "Waves", "sound", "global:sound/waves.wav", Vec3(-0.4f, -0.4f, -0.4f), Vec3(0.4f, 0.4f, 0.4f)),
        Kind("Others", "Fire", "sound", "global:sound/fire.wav", Vec3(-0.4f, -0.4f, -0.4f), Vec3(0.4f, 0.4f, 0.4f)),
        Kind("Others", "Engine", "sound", "global:sound/engine.wav", Vec3(-0.4f, -0.4f, -0.4f), Vec3(0.4f, 0.4f, 0.4f)),
        Kind("Logic", "Way out", "way", "", Vec3(-0.5f, 0, -0.5f), Vec3(0.5f, 1, 0.5f)),
        Kind("Logic", "Arrival", "arrival", "", Vec3(-0.4f, 0, -0.4f), Vec3(0.4f, 1.6f, 0.4f)),
        Kind("Logic", "Trigger", "trigger", "", Vec3(-0.5f, 0, -0.5f), Vec3(0.5f, 1, 0.5f)),
        Kind("Others", "Light", "glow", "", Vec3(-0.4f, -0.4f, -0.4f), Vec3(0.4f, 0.4f, 0.4f))
    };
    array<string> groups = { "Everything", "Platforms", "Roads", "Nature", "Buildings", "Caves", "Shapes", "Logic", "Others", "Mine" };
    int group = 0;
    array<uint> listed;
    array<string> pictures = { "" }, pictureNames = { "None" };   // for things, and for the sky
    array<Model@> models;
    Level level;               // what a game would make of it: for Play, and for what both have to agree on
    uint builtIn = 0;          // how many kinds there are besides the player's own
    Widget@ addList;
    array<Color> colors = { Color(1, 1, 1), Color(0.35f, 0.37f, 0.42f), Color(0.9f, 0.3f, 0.26f), Color(0.97f, 0.62f, 0.2f), Color(0.98f, 0.86f, 0.35f),
        Color(0.38f, 0.75f, 0.36f), Color(0.3f, 0.75f, 0.85f), Color(0.3f, 0.48f, 0.95f), Color(0.66f, 0.4f, 0.9f), Color(0.95f, 0.5f, 0.72f) };
    array<string> grounds = { "Flat", "Hills", "Island", "Endless" };
    array<string> hours = { "Day", "Evening", "Night" };
    array<string> brushes = { "Raise", "Lower", "Smooth", "Level", "Paint", "Wipe paint", "Hole", "Close hole" };
    array<string> tools = { "Move", "Turn", "Size" };

    array<Thing@> things;
    array<Entity@> thrown;
    int chosen = -1, under = -1;
    int ground = 0, hour = 0, tool = 0;
    array<string> acrosses = { "64 m", "128 m", "256 m", "512 m" };
    int across = 1;            // of those
    bool edges = true;
    Json sky;                  // what is different from the time of day's own
    Json hud;                  // what is shown over Play
    array<Road@> roads;
    int road = -1;
    array<string> colliders = { "None", "Box", "Sphere", "Pill", "Exact" };
    array<string> ways = { "Walk", "Drive", "Fly", "Shoot" };
    int way = 0;
    string sceneName = "Village";
    Json scenes;
    Widget@ popup;
    int made = -1;             // the ground there is now
    string landText;           // what was done to it by hand
    int brush = 0;
    float brushSize = 6, brushForce = 0.5f, levelTo = 0;
    Color brushColor(0.55f, 0.42f, 0.28f);
    int paintWith = 0;
    bool stroking = false, hasSpot = false;
    Vec3 spot;
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

    Widget@ tabs;
    Widget@ brushChoice;
    array<Color> earths = { Color(0.55f, 0.42f, 0.28f), Color(0.78f, 0.7f, 0.48f), Color(0.36f, 0.52f, 0.28f), Color(0.2f, 0.36f, 0.2f), Color(0.45f, 0.42f, 0.4f),
        Color(0.92f, 0.94f, 0.97f), Color(0.25f, 0.22f, 0.22f), Color(0.75f, 0.35f, 0.22f), Color(0.62f, 0.66f, 0.3f), Color(0.4f, 0.4f, 0.48f) };
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
    Widget@ groupChoice;
    Widget@ nameField;
    Widget@ logicRow;
    Widget@ doesLabel;
    Widget@ doesChoice;
    Widget@ targetChoice;
    Widget@ whenChoice;
    Widget@ onceToggle;
    Widget@ startsOff;
    Widget@ messageField;
    Widget@ wayRow;
    Widget@ toChoice;
    Widget@ arriveField;
    Widget@ animationRow;
    Widget@ animationChoice;
    Widget@ startsHidden;
    Widget@ appearChoice;
    array<string> doings = { "Tells the game", "Shows a thing", "Hides a thing", "Switches on", "Switches off", "Plays a sound" };
    array<string> doingKeys = { "", "show", "hide", "open", "close", "sound" };
    array<string> whens = { "When gone into", "When shot" };
    array<string> appears = { "Grows", "Rises", "Drops" };
    array<string> appearKeys = { "grow", "rise", "drop" };
    array<string> targets, sceneFiles, animations_;
    Widget@ acrossChoice;
    Widget@ edgeToggle;
    Widget@ skyChoice;
    Widget@ sunTurn;
    Widget@ sunHigh;
    Widget@ fogFrom;
    Widget@ fogTo;
    Widget@ waterToggle;
    Widget@ waterHigh;
    Widget@ roadLabel;
    Widget@ hudKind;
    Widget@ hudName;
    Widget@ hudCorner;
    Widget@ hudList;
    array<string> hudKinds = { "Bar", "Text", "Big text", "Crosshair" };
    array<string> hudKindKeys = { "bar", "text", "big", "cross" };
    array<string> corners = { "Top left", "Top right", "Bottom left", "Bottom right" };
    Widget@ roadClosed;
    Widget@ roadWidth;
    Widget@ rangeLabel;
    Widget@ lookRow;
    Widget@ skinChoice;
    Widget@ colliderChoice;
    Widget@ moves;
    Widget@ moveRow;
    Widget@ seconds;
    array<Widget@> movers;
    Model@ carModel;
    Model@ heroModel;
    Sound@ splash;
    Sound@ hop;
    Sound@ bang;
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
        {
            Kind@ k = kinds[i];
            bool model = k.key == "model" || k.key == "moving" || k.key == "lift";
            models.insertLast(model ? Assets::model("global:model/" + k.name + ".glb") : null);
            giveExits(k);
        }
        @carModel = Assets::model("global:model/skimmer.glb");
        @heroModel = Assets::model("global:model/robot.glb");
        @splash = Assets::sound("global:sound/splash.wav");
            @hop = Assets::sound("global:sound/whoosh.wav");
        @bang = Assets::sound("global:sound/hit.wav");
        builtIn = kinds.length();
        most = App::freeKilobytes > 0 && App::freeKilobytes < 64000 ? 12 : 40;
    }

    void onEnter()
    {
        Ui::theme("asset:theme.json");
        findOwn();
        build();
        string error;
        if (!scenes.parse(Assets::read("asset:scenes.json"), error))
            Ui::toast(error);
        openLast();
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
        top.button("Scenes", WidgetEvent(this.onScenes));
        top.button(ways[uint(way)], WidgetEvent(this.onWay)).width = 90;
        top.button("Play", WidgetEvent(this.onPlay));
        top.button("Save", WidgetEvent(this.onSave));

        Widget@ sides = page.row(0);
        sides.grow = 1;
        sides.align = PlaceStretch;
        Widget@ first = sides.panel();
        first.style = "side";
        first.width = 310;
        @tabs = first.tabs();
        tabs.grow = 1;
        Widget@ add = tabs.tab("Add");
        @groupChoice = add.choice(groups, group, WidgetEvent(this.onGroup));
        Widget@ list = @addList = add.list(0, 42, WidgetRow(this.fill));
        listKinds();
        list.grow = 1;
        list.onClick(WidgetEvent(this.onAdd));
        Widget@ scene = tabs.tab("Scene");
        Widget@ things = scene.scroll(8);
        things.grow = 1;
        things.label("Ground", "small");
        @groundChoice = things.choice(grounds, 0, WidgetEvent(this.onGround));
        things.label("How large", "small");
        bool small = App::freeKilobytes > 0 && App::freeKilobytes < 64000;
        if (small)
            acrosses.removeLast();
        @acrossChoice = things.choice(acrosses, across, WidgetEvent(this.onAcross));
        @edgeToggle = things.toggle("Walls at its edge", true, WidgetEvent(this.onEdges));
        things.toggle("Snap", true, WidgetEvent(this.onSnap));
        things.toggle("Wireframe", false, WidgetEvent(this.onLines));
        things.button("As saved", WidgetEvent(this.onRevert));
        things.button("Clear", WidgetEvent(this.onClear));
        if (!App::development)
            things.button("Start again", WidgetEvent(this.onFresh));

        Widget@ above = tabs.tab("Sky").scroll(8);
        above.grow = 1;
        above.label("Time", "small");
        @hourChoice = above.choice(hours, 0, WidgetEvent(this.onHour));
        above.label("Picture", "small");
        @skyChoice = above.choice(pictureNames, 0, WidgetEvent(this.onSkyPicture));
        above.label("The sun: which way, how high", "small");
        @sunTurn = above.slider(0, 0, 345, WidgetEvent(this.onSky));
        sunTurn.step = 15;
        @sunHigh = above.slider(45, 5, 90, WidgetEvent(this.onSky));
        sunHigh.step = 5;
        above.label("Fog: where from, where to", "small");
        @fogFrom = above.slider(60, 0, 300, WidgetEvent(this.onSky));
        fogFrom.step = 5;
        @fogTo = above.slider(170, 20, 500, WidgetEvent(this.onSky));
        fogTo.step = 10;
        Widget@ mists = above.grid(5, 6);
        for (uint i = 0; i < colors.length(); i++)
        {
            Widget@ b = mists.button("", WidgetEvent(this.onMist));
            b.style = "swatch";
            b.tag = int(i);
            Widget@ c = b.custom(WidgetDraw(this.swatch));
            c.height = 18;
            c.grow = 1;
        }
        above.button("Its own colours", WidgetEvent(this.onSkyFresh));
        @waterToggle = above.toggle("Sea", false, WidgetEvent(this.onWater));
        @waterHigh = above.slider(0, -8, 12, WidgetEvent(this.onWater));
        waterHigh.step = 0.5f;
        Widget@ earth = tabs.tab("Land");
        @brushChoice = earth.choice(brushes, 0, WidgetEvent(this.onBrush));
        earth.label("Size", "small");
        Widget@ wideOf = earth.slider(brushSize, 2, 24, WidgetEvent(this.onBrushSize));
        wideOf.step = 1;
        earth.label("Force", "small");
        Widget@ force = earth.slider(brushForce, 0.1f, 1, WidgetEvent(this.onBrushForce));
        force.step = 0.1f;
        earth.label("Paint", "small");
        Widget@ paints = earth.grid(5, 6);
        for (uint i = 0; i < earths.length(); i++)
        {
            Widget@ b = paints.button("", WidgetEvent(this.onEarth));
            b.style = "swatch";
            b.tag = int(i);
            Widget@ c = b.custom(WidgetDraw(this.earthSwatch));
            c.height = 22;
            c.grow = 1;
        }
        earth.button("As it was made", WidgetEvent(this.onLandFresh));
        earth.paragraph("Hold on the land to change it.", "small");

        Widget@ shown_ = tabs.tab("HUD").scroll(8);
        shown_.grow = 1;
        shown_.paragraph("What Play shows over everything. A game sets each by its name: level.set(\"health\", 80).", "small");
        @hudKind = shown_.choice(hudKinds, 0);
        @hudName = shown_.field("health", "Its name");
        @hudCorner = shown_.choice(corners, 0);
        shown_.button("Add", WidgetEvent(this.onHudAdd));
        @hudList = shown_.column(6);

        Widget@ track = tabs.tab("Road");
        @roadLabel = track.label("", "plain");
        track.button("New road", WidgetEvent(this.onRoadNew));
        track.button("Next road", WidgetEvent(this.onRoadNext));
        @roadClosed = track.toggle("Goes round", false, WidgetEvent(this.onRoad));
        track.label("How wide", "small");
        @roadWidth = track.slider(7, 3, 16, WidgetEvent(this.onRoad));
        roadWidth.step = 1;
        track.button("Shape the land", WidgetEvent(this.onRoadLand));
        track.button("Take a point back", WidgetEvent(this.onRoadBack));
        track.button("Delete road", WidgetEvent(this.onRoadDelete));
        track.paragraph("Press on the land for each point; drag one to move it; press on the road to put one between. With Drive, Play is a race against the clock.", "small");

        sides.space();
        Widget@ other = sides.panel();
        other.style = "side";
        other.width = 286;
        @nothing = other.paragraph("Add something, or choose something in the view.", "small");
        @inspector = other.scroll(8);
        inspector.grow = 1;
        @title = inspector.label("", "heading");
        @nameField = inspector.field("", "Its name, for a game to find it", WidgetEvent(this.onName));
        nameField.onDone(WidgetEvent(this.onName));
        @logicRow = inspector.column(6);
        @doesLabel = logicRow.label("What it does", "small");
        @doesChoice = logicRow.choice(doings, 0, WidgetEvent(this.onLogic));
        @targetChoice = logicRow.choice(array<string> = { "(nothing)" }, 0, WidgetEvent(this.onLogic));
        @whenChoice = logicRow.choice(whens, 0, WidgetEvent(this.onLogic));
        @onceToggle = logicRow.toggle("Only once", false, WidgetEvent(this.onLogic));
        @startsOff = logicRow.toggle("Off until switched on", false, WidgetEvent(this.onLogic));
        @messageField = logicRow.field("", "Something to say", WidgetEvent(this.onLogic));
        messageField.onDone(WidgetEvent(this.onLogic));
        @wayRow = inspector.column(6);
        wayRow.label("Goes to", "small");
        @toChoice = wayRow.choice(array<string> = { "(nowhere)" }, 0, WidgetEvent(this.onLogic));
        @arriveField = wayRow.field("", "Where there: an arrival's name", WidgetEvent(this.onLogic));
        arriveField.onDone(WidgetEvent(this.onLogic));
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
        @rangeLabel = rangeRow.label("", "small");
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
        @lookRow = inspector.column(6);
        lookRow.label("Picture", "small");
        @skinChoice = lookRow.choice(pictureNames, 0, WidgetEvent(this.onSkin));
        lookRow.label("Collider", "small");
        @colliderChoice = lookRow.choice(colliders, 0, WidgetEvent(this.onCollider));
        @animationRow = lookRow.column(6);
        animationRow.label("Animation", "small");
        @animationChoice = animationRow.choice(array<string> = { "None" }, 0, WidgetEvent(this.onAnimation));
        @startsHidden = lookRow.toggle("Hidden until shown", false, WidgetEvent(this.onToggle));
        @appearChoice = lookRow.choice(appears, 0, WidgetEvent(this.onToggle));
        @onLand = inspector.toggle("On the land", true, WidgetEvent(this.onToggle));
        @falls = inspector.toggle("Falls", false, WidgetEvent(this.onToggle));
        @glows = inspector.toggle("Glows", false, WidgetEvent(this.onToggle));
        @moves = inspector.toggle("Moves to and fro", false, WidgetEvent(this.onToggle));
        @moveRow = inspector.column(6);
        moveRow.label("How far: across, up, along", "small");
        Widget@ far = moveRow.row(6);
        for (uint i = 0; i < 3; i++)
        {
            Widget@ f = far.field("", "", WidgetEvent(this.onMove));
            f.style = "cell";
            f.numeric = true;
            f.grow = 1;
            f.onDone(WidgetEvent(this.onMove));
            movers.insertLast(f);
        }
        moveRow.label("Seconds there and back", "small");
        @seconds = moveRow.slider(6, 1, 30, WidgetEvent(this.onMove));
        seconds.step = 1;
        Widget@ two = inspector.row(8);
        Widget@ copy = two.button("Copy", WidgetEvent(this.onCopy));
        copy.grow = 1;
        Widget@ remove = two.button("Delete", WidgetEvent(this.onDelete));
        remove.grow = 1;
        list.focus();
    }

    void closeEnds()
    {
        array<Json@> list;
        for (uint i = 0; i < things.length(); i++)
            list.insertLast(things[i].json);
        level.closeEnds(list);
    }

    bool isMouth(Kind@ k) { return k.name.findFirst("cave-mouth") >= 0; }

    // By its name, so that other entrances, tunnels and rooms join as well: "cave-mouth-ice", "cave-room-2".
    void giveExits(Kind@ k)
    {
        array<Vec3>@ found = level.exitsOf(k.name);
        if (found.length() == 0)
            return;
        k.group = "Caves";
        for (uint i = 0; i < found.length(); i++)
            k.exits.insertLast(Exit(found[i]));
        k.collider = 4;
    }

    // --- Models that the player brought ---

    bool isModel(const string &in file)
    {
        array<string> endings = { ".glb", ".gltf", ".fbx", ".obj", ".stl", ".ply" };
        for (uint i = 0; i < endings.length(); i++)
            if (file.length() > endings[i].length() && file.substr(file.length() - endings[i].length()) == endings[i])
                return true;
        return false;
    }

    void findOwn()
    {
        array<string> folders = { "asset:model/", "asset:picture/", "asset:sound/", "global:picture/", "own:" };
        for (uint f = 0; f < folders.length(); f++)
        {
            array<string>@ files = Assets::list(folders[f]);
            for (uint i = 0; i < files.length(); i++)
                addOwn(folders[f] + files[i], files[i]);
        }
    }

    bool ends(const string &in file, const array<string> &in endings)
    {
        for (uint i = 0; i < endings.length(); i++)
            if (file.length() > endings[i].length() && file.substr(file.length() - endings[i].length()) == endings[i])
                return true;
        return false;
    }

    // True if it is something new.
    bool addOwn(const string &in path, const string &in file)
    {
        string label = file.substr(0, file.findLast("."));
        label = label.length() > 18 ? label.substr(0, 17) + "..." : label;
        if (ends(file, array<string> = { ".png", ".jpg", ".jpeg", ".tga", ".bmp" }))
        {
            if (pictures.find(path) >= 0 || pictures.length() >= 40)
                return false;
            pictures.insertLast(path);
            pictureNames.insertLast(label);
            return true;
        }
        bool sound = ends(file, array<string> = { ".wav", ".ogg", ".mp3" });
        if ((!sound && !isModel(file)) || kinds.length() >= builtIn + 60)
            return false;
        for (uint i = 0; i < kinds.length(); i++)
            if (kinds[i].name == path)
                return false;
        kinds.insertLast(Kind("Mine", label, sound ? "sound" : "own", path, Vec3(-0.5f, -0.5f, -0.5f), Vec3(0.5f, 0.5f, 0.5f)));
        if (!sound)
        {
            @kinds[kinds.length() - 1].own = Assets::model(path);
            giveExits(kinds[kinds.length() - 1]);
        }
        return true;
    }

    // As they arrive: how big each is. Those made in other units are brought to a size that can be seen.
    void measureOwn()
    {
        for (uint i = builtIn; i < kinds.length(); i++)
        {
            Kind@ k = kinds[i];
            if (k.own is null || !(k.own.ready || k.own.failed))
                continue;
            if (!k.own.failed)
            {
                k.low = k.own.low;
                k.high = k.own.high;
                Vec3 s = k.high - k.low;
                float longest = s.x > s.y ? s.x : s.y;
                longest = s.z > longest ? s.z : longest;
                if (k.exits.length() == 0 && (longest > 15 || longest < 0.2f))
                    k.size = 3 / (longest > 0.0001f ? longest : 1.0f);
            }
            else
                Ui::toast(k.label + " can't be used: see the log");
            models.insertLast(k.own);
            @k.own = null;
            for (uint n = 0; n < things.length(); n++)
                if (kindOf(things[n].json) is k)
                    make(n);
        }
    }

    void takeDropped()
    {
        array<string>@ files = Assets::dropped();
        uint added = 0;
        for (uint i = 0; i < files.length(); i++)
            added += addOwn("own:" + files[i], files[i]) ? 1 : 0;
        if (files.length() == 0)
            return;
        if (added == 0)
        {
            Ui::toast("Nothing new to add in that");
            return;
        }
        skinChoice.items(pictureNames);
        skyChoice.items(pictureNames);
        group = int(groups.length()) - 1;
        groupChoice.chosen = group;
        listKinds();
        Ui::toast(added == 1 ? "One more of your own" : "" + added + " more of your own");
        show();
    }

    void listKinds()
    {
        listed.resize(0);
        for (uint i = 0; i < kinds.length(); i++)
            if (group == 0 || kinds[i].group == groups[uint(group)])
                listed.insertLast(i);
        addList.count = listed.length();
    }
    void onGroup(Widget@ w) { group = w.chosen; listKinds(); }

    void fill(Widget@ row, int i) { row.label(kinds[listed[uint(i)]].label); }

    void swatch(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place, s = w.size;
        c.roundRect(p.x, p.y, s.x, s.y, 5, colors[uint(w.parent.tag)]);
    }

    void earthSwatch(Canvas@ c, Widget@ w)
    {
        Vec2 p = w.place, s = w.size;
        c.roundRect(p.x, p.y, s.x, s.y, 5, earths[uint(w.parent.tag)]);
        if (w.parent.tag == paintWith)
            c.circle(p.x + s.x * 0.5f, p.y + s.y * 0.5f, 4, White);
    }

    bool sculpting { get { return tabs.chosen == 3 && !playing; } }
    bool roading { get { return tabs.chosen == 5 && !playing; } }

    // What the panel says, from what is chosen.
    void show()
    {
        showRoad();
        count.text = sceneName + ":  " + things.length() + " things" + (dirty ? " *" : "") + "  " ;
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
        bool sound = j.has("sound");
        rangeRow.visible = j.has("light") || sound;
        rangeLabel.text = sound ? "How far it is heard" : "Reach of its light";
        range.value = float(sound ? j["reach"].number(12) : j["range"].number(8));
        onLand.checked = j["onLand"].flag();
        falls.checked = j["mass"].number() > 0;
        glows.checked = j["glowing"].number() > 0;
        bool logic = j.has("trigger") || j.has("to") || j.has("arrival");
        bool thing = !j.has("glow") && !sound && !logic, water = j["pool"].flag();
        lookRow.visible = thing && !water;
        falls.visible = thing && !water;
        glows.visible = thing && !water;
        moves.visible = thing && !water;
        moves.checked = j.has("moves");
        moveRow.visible = thing && j.has("moves");
        Vec3 far = j["moves"].vec3();
        movers[0].text = number(far.x);
        movers[1].text = number(far.y);
        movers[2].text = number(far.z);
        seconds.value = float(j["seconds"].number(6));
        colliderChoice.chosen = colliderOf(j);
        int picture = pictures.find(j["skin"].text());
        skinChoice.chosen = picture < 0 ? 0 : picture;
        nameField.text = j.has("arrival") ? j["arrival"].text() : j["name"].text();
        bool trigger = j.has("trigger"), goes = j.has("to");
        logicRow.visible = trigger;
        wayRow.visible = goes;
        startsHidden.checked = j["hidden"].flag();
        appearChoice.visible = startsHidden.checked;
        appearChoice.chosen = appearKeys.find(j["appear"].text("grow")) < 0 ? 0 : appearKeys.find(j["appear"].text("grow"));
        if (trigger)
        {
            targets.resize(0);
            targets.insertLast("(nothing)");
            for (uint i = 0; i < things.length(); i++)
                if (int(i) != chosen && things[i].json["name"].text() != "")
                    targets.insertLast(things[i].json["name"].text());
            targetChoice.items(targets);
            doesChoice.chosen = doingKeys.find(j["does"].text()) < 0 ? 0 : doingKeys.find(j["does"].text());
            int target = targets.find(j["target"].text());
            targetChoice.chosen = target < 0 ? 0 : target;
            targetChoice.visible = doesChoice.chosen >= 1 && doesChoice.chosen <= 4;
            whenChoice.chosen = j["when"].text() == "shot" ? 1 : 0;
            onceToggle.checked = j["once"].flag();
            startsOff.checked = !j["on"].flag(true);
            messageField.text = j["message"].text();
        }
        if (goes)
        {
            array<string> names = { "(nowhere)" };
            sceneFiles.resize(0);
            sceneFiles.insertLast("");
            for (uint i = 0; i < scenes["scenes"].count; i++)
            {
                names.insertLast(scenes["scenes"][i]["name"].text());
                sceneFiles.insertLast("asset:" + scenes["scenes"][i]["file"].text() + ".json");
            }
            toChoice.items(names);
            int to = sceneFiles.find(j["to"].text());
            toChoice.chosen = to < 0 ? 0 : to;
            arriveField.text = j["arrive"].text();
        }
        // Those of its model.
        animations_.resize(0);
        animations_.insertLast("None");
        Kind@ k = kindOf(j);
        int at = kinds.findByRef(k);
        Model@ m = at >= 0 && uint(at) < models.length() ? models[uint(at)] : null;
        for (uint i = 0; m !is null && i < m.animations; i++)
            animations_.insertLast(m.animation(i));
        animationRow.visible = animations_.length() > 1;
        animationChoice.items(animations_);
        int playing_ = animations_.find(j["animate"].text());
        animationChoice.chosen = playing_ < 0 ? 0 : playing_;
    }

    void onName(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        if (j.has("arrival"))
            j.set("arrival", w.text);
        else if (w.text == "")
            j.remove("name");
        else
            j.set("name", w.text);
        changed("name", false);
    }

    void onLogic(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        if (j.has("trigger"))
        {
            j.set("does", doingKeys[uint(doesChoice.chosen)]);
            j.set("target", targetChoice.chosen > 0 ? targets[uint(targetChoice.chosen)] : "");
            j.set("when", whenChoice.chosen == 1 ? "shot" : "enter");
            j.set("once", onceToggle.checked);
            j.set("message", messageField.text);
            if (startsOff.checked)
                j.set("on", false);
            else
                j.remove("on");
        }
        if (j.has("to"))
        {
            j.set("to", sceneFiles[uint(toChoice.chosen)]);
            j.set("arrive", arriveField.text);
        }
        changed("logic", false);
    }

    void onAnimation(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        if (w.chosen > 0)
            j.set("animate", animations_[uint(w.chosen)]);
        else
            j.remove("animate");
        make(uint(chosen));
        changed("animation");
    }

    string number(float v) { return formatFloat(floor(v * 100 + 0.5f) / 100, "", 0, 2); }
    float wrapped(float a) { a = a % 360; return a < 0 ? a + 360 : a; }

    void onTool(Widget@ w) { tool = (tool + 1) % 3; show(); }
    void onSnap(Widget@ w) { snap = w.checked; }
    void onUndo(Widget@ w) { undo(); }
    void onRedo(Widget@ w) { redo(); }
    void onPlay(Widget@ w) { play(true); }
    void onAdd(Widget@ w)
    {
        if (w.chosen >= 0 && uint(w.chosen) < listed.length())
            add(listed[uint(w.chosen)]);
    }
    void onWay(Widget@ w) { way = (way + 1) % int(ways.length()); w.text = ways[uint(way)]; }
    void onAcross(Widget@ w) { across = w.chosen; landText = ""; land(); place(); changed("across"); }
    void onEdges(Widget@ w) { edges = w.checked; Space::edges = edges; changed("edges"); }
    void onGround(Widget@ w) { ground = w.chosen; acrossChoice.enabled = ground != 3; land(); place(); changed("ground"); }
    void onLines(Widget@ w) { Space::lines = w.checked; }
    void onBrush(Widget@ w) { brush = w.chosen; }
    void onBrushSize(Widget@ w) { brushSize = w.value; }
    void onBrushForce(Widget@ w) { brushForce = w.value; }
    void onEarth(Widget@ w)
    {
        paintWith = w.tag;
        brushColor = earths[uint(w.tag)];
        brush = 4;
        brushChoice.chosen = 4;
    }
    void onLandFresh(Widget@ w)
    {
        landText = "";
        Space::restoreLand("");
        place();
        changed("land");
    }
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

    // Back to what came with it.
    void onFresh(Widget@ w) { Ui::dialog("Start again", "Go back to the first scene? What was saved is lost. Undo brings back what is here now.", array<string> = { "Start again", "Keep" }, WidgetAnswer(this.fresh)); }
    void fresh(int answer)
    {
        if (answer == 0 && file != "asset:scene.json")
            clear(0);
        else if (answer == 0)
        {
            Assets::forget(file);
            onRevert(null);
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
        Json@ j = things[uint(chosen)].json;
        j.set(j.has("sound") ? "reach" : "range", w.value);
        make(uint(chosen));
        changed("range", false);
    }

    void onSkin(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        if (w.chosen > 0)
            j.set("skin", pictures[uint(w.chosen)]);
        else
            j.remove("skin");
        make(uint(chosen));
        changed("skin");
    }

    void onCollider(Widget@ w)
    {
        if (chosen < 0)
            return;
        setCollider(things[uint(chosen)].json, w.chosen);
        make(uint(chosen));
        changed("collider");
    }

    void onMove(Widget@ w)
    {
        if (chosen < 0)
            return;
        Json@ j = things[uint(chosen)].json;
        j.set("moves", Vec3(parseFloat(movers[0].text), parseFloat(movers[1].text), parseFloat(movers[2].text)));
        j.set("seconds", seconds.value);
        changed("moves", false);
    }

    // --- Colliders ---

    int colliderOf(Json@ j) { return j.has("cube") ? 1 : j.has("sphere") ? 2 : j.has("capsule") ? 3 : j["exact"].flag() ? 4 : 0; }

    void setCollider(Json@ j, int which)
    {
        array<string> all = { "cube", "sphere", "capsule", "exact", "colliderAt", "wall" };
        for (uint i = 0; i < all.length(); i++)
            j.remove(all[i]);
        Kind@ k = kindOf(j);
        Vec3 wide = k.high - k.low, middle = (k.high + k.low) * 0.5f;
        float round = wide.x > wide.z ? wide.x : wide.z;
        if (which == 1)
            j.set("cube", wide);
        else if (which == 2)
            j.set("sphere", (round > wide.y ? round : wide.y) * 0.5f);
        else if (which == 3)
        {
            float thick = k.stem > 0 ? k.stem * 2 : round;
            Json size;
            size.add(thick * 0.5f);
            size.add(wide.y > thick ? wide.y : thick);
            j.set("capsule", size);
        }
        else if (which == 4)
            j.set("exact", true);
        if (which == 0)
        {
            // Kept, so that the kind's own isn't given it again.
            j.remove("mass");
            j.set("wall", false);
            return;
        }
        if (which != 4 && middle.length() > 0.001f)
            j.set("colliderAt", middle);
        if (!j.has("mass"))
            j.set("wall", true);
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
        if (falls.checked != (j["mass"].number() > 0))
        {
            setNumberIf(j, "mass", falls.checked, 2);
            setNumberIf(j, "bounce", falls.checked, j["shape"].text() == "sphere" ? 0.5f : 0.1f);
            int which = colliderOf(j);
            setCollider(j, falls.checked && (which == 0 || which == 4) ? j["shape"].text() == "sphere" ? 2 : 1 : which);
        }
        if (startsHidden.checked != j["hidden"].flag())
        {
            if (startsHidden.checked)
                j.set("hidden", true);
            else
                j.remove("hidden");
        }
        if (startsHidden.checked)
            j.set("appear", appearKeys[uint(appearChoice.chosen)]);
        else
            j.remove("appear");
        if (moves.checked != j.has("moves"))
        {
            if (moves.checked)
            {
                j.set("moves", Vec3(8, 0, 0));
                j.set("seconds", 6);
                if (colliderOf(j) == 0)
                    setCollider(j, 1);
            }
            else
            {
                j.remove("moves");
                j.remove("seconds");
            }
        }
        setNumberIf(j, "glowing", glows.checked, 0.8f);
        make(uint(chosen));
        changed("toggle");
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
        string model = j["model"].text(), shape = j["shape"].text(), sound = j["sound"].text();
        if (j["pool"].flag())
            shape = "";
        for (uint i = 0; i < kinds.length(); i++)
        {
            Kind@ k = kinds[i];
            bool same = k.key == "own" ? model == k.name : k.key == "model" ? model == "global:model/" + k.name + ".glb" : k.key == "sound" ? sound == k.name && sound != ""
                : k.key == "shape" ? shape == k.name : k.key == "water" ? j["pool"].flag() : k.key == "way" ? j.has("to") : k.key == "arrival" ? j.has("arrival") : k.key == "trigger" && j.has("trigger");
            if (same)
                return k;
        }
        return kinds[builtIn - 1];
    }

    Vec3 angles(Json@ j) { return j["angles"].isNumber ? Vec3(0, float(j["angles"].number()), 0) : j["angles"].vec3(); }
    Vec3 sizes(Json@ j)
    {
        if (j.has("glow"))
            return Vec3(1, 1, 1) * float(j["glow"].number(1));
        if (j.has("sound"))
            return Vec3(0.8f, 0.8f, 0.8f);
        return j["size"].isNumber ? Vec3(1, 1, 1) * float(j["size"].number()) : j["size"].vec3(Vec3(1, 1, 1));
    }
    void resize(Json@ j, Vec3 s)
    {
        s = Vec3(clamp(s.x, 0.0005f, 400), clamp(s.y, 0.0005f, 400), clamp(s.z, 0.0005f, 400));
        if (j.has("sound"))
            return;
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
        all.set("across", across);
        all.set("edges", edges);
        if (sky.count > 0)
            all.set("sky", sky);
        if (roads.length() > 0)
        {
            Json tracks;
            for (uint i = 0; i < roads.length(); i++)
            {
                Json one, points;
                one.set("width", roads[i].width);
                one.set("closed", roads[i].closed);
                for (uint k = 0; k < roads[i].points.length(); k++)
                    points.add(roads[i].points[k]);
                one.set("points", points);
                tracks.add(one);
            }
            all.set("roads", tracks);
        }
        if (landText != "")
            all.set("land", landText);
        if (hud.count > 0)
            all.set("hud", hud);
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
        ground = int(clamp(float(all["ground"].number()), 0, 3));
        hour = int(clamp(float(all["hour"].number()), 0, 2));
        across = int(clamp(float(all["across"].number(1)), 0, float(acrosses.length()) - 1));
        edges = all["edges"].flag(true);
        Json empty;
        sky.copy(all["sky"].isNull ? empty : all["sky"]);
        groundChoice.chosen = ground;
        acrossChoice.chosen = across;
        acrossChoice.enabled = ground != 3;
        hud.copy(all["hud"].isNull ? empty : all["hud"]);
        edgeToggle.checked = edges;
        hourChoice.chosen = hour;
        readRoads(all["roads"]);
        showHud();
        landText = all["land"].text();
        land();
        light();
        Json@ list = all["entities"];
        for (uint i = 0; i < list.count; i++)
        {
            things.insertLast(Thing(list[i]));
            Json@ j = things[i].json;
            if (j["name"].text() == "water" && j["shape"].text() == "box")
            {
                j.remove("name");
                j.set("pool", true);
            }
            // Those from before there were others, and those that never had one: what their kind has. "wall": false
            // is one that was given none.
            if (colliderOf(j) == 0 && (j["wall"].flag(true) || j["mass"].number() > 0))
            {
                Kind@ k = kindOf(j);
                int which = k.collider > 0 ? k.collider : j["wall"].flag() || j["mass"].number() > 0 ? (j["shape"].text() == "sphere" ? 2 : 1) : 0;
                if (which > 0 && !j.has("glow") && !j.has("sound") && !j["pool"].flag() && !j.has("trigger") && !j.has("to") && !j.has("arrival"))
                    setCollider(j, which);
            }
            make(i);
        }
        for (uint i = 0; i < roads.length(); i++)
            makeRoad(roads[i]);
        closeEnds();
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
        if (playing)
        {
            @t.entity = Space::make(j);
            return;
        }
        Kind@ k = kindOf(j);
        array<string> still = { "mass", "walker", "gravity", "wall", "sphere", "cube", "capsule", "exact", "behaviour", "group", "hits", "colliderAt", "friction", "bounce", "drag", "moves", "seconds", "pathTime", "sound", "reach", "volume" };
        for (uint n = 0; n < still.length(); n++)
            j.remove(still[n]);
        if (t.json.has("sound"))
        {
            j.set("glow", 0.8f);
            j.set("color", Color(0.35f, 0.7f, 1, 0.8f));
        }
        // What can't be seen in a game is a box that can be seen through, or a marker.
        bool logic = t.json.has("to") || t.json.has("trigger");
        if (logic)
        {
            j.set("shape", "box");
            j.set("color", t.json.has("to") ? Color(0.3f, 0.6f, 1, 0.3f) : Color(1, 0.8f, 0.2f, 0.3f));
        }
        if (t.json.has("arrival"))
        {
            j.set("shape", "cone");
            j.set("size", Vec3(0.7f, 1.4f, 0.7f));
            j.set("color", Color(0.4f, 1, 0.5f));
        }
        for (uint n = 0; n < level.own.length(); n++)
            j.remove(level.own[n]);
        if (logic)
            j.set("place", worldPlace(t.json) + Vec3(0, sizes(t.json).y * 0.5f, 0) - Vec3(0, t.json["onLand"].flag() ? Space::height(worldPlace(t.json).x, worldPlace(t.json).z) : 0.0f, 0));
        @t.entity = Space::make(j);
        if (t.json["hidden"].flag())
        {
            // Seen while editing, but faint.
            t.entity.glowing = 0.3f;
        }
        bool soft = t.json.has("glow") || t.json.has("sound");
        t.entity.cube(soft ? Vec3(1, 1, 1) : logic || t.json.has("arrival") ? Vec3(1, 1, 1) : k.high - k.low, 1, 0);
        t.entity.colliderAt = soft || logic ? Vec3() : t.json.has("arrival") ? Vec3(0, 0, 0) : (k.high + k.low) * 0.5f;
    }

    // Puts its entity where it is.
    void put(Thing@ t)
    {
        bool logic = t.json.has("to") || t.json.has("trigger");
        t.entity.place = worldPlace(t.json) + (logic ? Vec3(0, sizes(t.json).y * 0.5f, 0) : Vec3());
        t.entity.angles = angles(t.json);
        t.entity.size = sizes(t.json);
    }

    void place()
    {
        for (uint i = 0; i < things.length(); i++)
            put(things[i]);
    }

    // Made only when it is another, as that takes a while; what was done by hand is put back each time.
    void land()
    {
        int wanted = ground * 10 + across;
        if (made != wanted)
            level.makeLand(write());
        made = wanted;
        Space::edges = edges && ground != 3;
        if (!Space::restoreLand(landText))
        {
            landText = "";
            Space::restoreLand("");
        }
    }

    void light()
    {
        Color top = hour == 0 ? Color(0.25f, 0.5f, 0.85f) : hour == 1 ? Color(0.25f, 0.24f, 0.45f) : Color(0.015f, 0.02f, 0.06f);
        Color low = hour == 0 ? Color(0.72f, 0.83f, 0.92f) : hour == 1 ? Color(0.95f, 0.6f, 0.4f) : Color(0.07f, 0.09f, 0.17f);
        Vec3 sun = hour == 1 ? Vec3(0.8f, 0.3f, -0.4f) : Vec3(0.45f, 0.8f, 0.4f);
        if (sky.has("mist"))
            low = sky["mist"].color();
        sunTurn.value = wrapped(floor(atan2(sun.x, sun.z) * 57.29578f / 15 + 0.5f) * 15);
        sunHigh.value = floor(atan2(sun.y, sqrt(sun.x * sun.x + sun.z * sun.z)) * 57.29578f / 5 + 0.5f) * 5;
        if (sky.has("sunHigh"))
        {
            sunTurn.value = float(sky["sunTurn"].number());
            sunHigh.value = float(sky["sunHigh"].number());
            float a = sunTurn.value * 0.0174533f, h = sunHigh.value * 0.0174533f;
            sun = Vec3(sin(a) * cos(h), sin(h), cos(a) * cos(h));
        }
        fogFrom.value = float(sky["fogFrom"].number(60));
        fogTo.value = float(sky["fogTo"].number(170));
        bool sea = sky["sea"].flag(ground == 2);
        waterToggle.checked = sea;
        waterHigh.value = float(sky["seaHigh"].number(0));
        int picture = pictures.find(sky["picture"].text());
        skyChoice.chosen = picture < 0 ? 0 : picture;
        level.makeSky(write());
    }

    void onSky(Widget@ w)
    {
        if (w is sunTurn || w is sunHigh)
        {
            sky.set("sunTurn", sunTurn.value);
            sky.set("sunHigh", sunHigh.value);
        }
        else
        {
            sky.set("fogFrom", fogFrom.value);
            sky.set("fogTo", fogTo.value);
        }
        light();
        changed("sky", false);
    }
    void onMist(Widget@ w) { sky.set("mist", colors[uint(w.tag)]); light(); changed("mist"); }
    void onSkyFresh(Widget@ w)
    {
        Json empty;
        sky.copy(empty);
        light();
        changed("sky");
    }
    void onSkyPicture(Widget@ w)
    {
        if (w.chosen > 0)
            sky.set("picture", pictures[uint(w.chosen)]);
        else
            sky.remove("picture");
        light();
        changed("picture");
    }
    void onWater(Widget@ w)
    {
        sky.set("sea", waterToggle.checked);
        sky.set("seaHigh", waterHigh.value);
        light();
        changed("sea", false);
    }

    // --- Scenes ---

    string path(const string &in name) { return "asset:" + name + ".json"; }

    int sceneNow()
    {
        for (uint i = 0; i < scenes["scenes"].count; i++)
            if (path(scenes["scenes"][i]["file"].text()) == file)
                return int(i);
        return 0;
    }

    void openLast()
    {
        int last = int(scenes["last"].number());
        openScene(last >= 0 && last < int(scenes["scenes"].count) ? last : 0);
    }

    void openScene(int which)
    {
        Json@ one = scenes["scenes"][uint(which)];
        file = path(one["file"].text("scene"));
        sceneName = one["name"].text("Village");
        Json j;
        string error;
        if (!j.parse(Assets::read(file), error))
            Ui::toast(error);
        read(j);
        before.resize(0);
        after.resize(0);
        now = write().write(true);
        dirty = false;
        select(-1);
    }

    void keepScenes(int last)
    {
        scenes.set("last", last);
        Assets::write("asset:scenes.json", scenes.write());
    }

    int wantScene = -1;
    void goTo(int which)
    {
        wantScene = which;
        if (dirty)
            Ui::dialog("Not saved", sceneName + " has changed since it was saved.", array<string> = { "Save", "Don't save", "Stay" }, WidgetAnswer(this.onLeave));
        else
            onLeave(1);
    }
    void onLeave(int answer)
    {
        if (answer < 0 || answer == 2)
            return;
        if (answer == 0)
            onSave(null);
        if (popup !is null)
            popup.close();
        @popup = null;
        openScene(wantScene);
        keepScenes(wantScene);
    }

    void onScenes(Widget@ w)
    {
        @popup = Ui::popup();
        popup.label("Scenes", "heading");
        Widget@ all = popup.scroll(6);
        all.height = 250;
        all.width = 380;
        int here = sceneNow();
        for (uint i = 0; i < scenes["scenes"].count; i++)
        {
            Widget@ b = all.button(scenes["scenes"][i]["name"].text() + (int(i) == here ? "  (open)" : ""), WidgetEvent(this.onScene));
            b.tag = int(i);
        }
        Widget@ row = popup.row(8);
        row.button("New", WidgetEvent(this.onNew)).grow = 1;
        row.button("Copy", WidgetEvent(this.onCopyScene)).grow = 1;
        Widget@ other = popup.row(8);
        other.button("Rename", WidgetEvent(this.onRename)).grow = 1;
        other.button("Delete", WidgetEvent(this.onDeleteScene)).grow = 1;
        popup.button("Close", WidgetEvent(this.onClosePopup));
    }
    void onClosePopup(Widget@ w) { if (popup !is null) popup.close(); @popup = null; }
    void onScene(Widget@ w) { goTo(w.tag); }

    int naming = 0;   // 0 a new one, 1 a copy, 2 another name
    Widget@ sceneNameField;
    void askName(int what, const string &in text)
    {
        naming = what;
        onClosePopup(null);
        @popup = Ui::popup();
        popup.label(what == 0 ? "A new scene" : what == 1 ? "A copy" : "Another name", "heading");
        @sceneNameField = popup.field(text, "Its name");
        sceneNameField.width = 340;
        Widget@ row = popup.row(8);
        row.button("All right", WidgetEvent(this.onNamed)).grow = 1;
        row.button("Cancel", WidgetEvent(this.onClosePopup)).grow = 1;
    }
    void onNew(Widget@ w)
    {
        if (dirty)
        {
            Ui::toast("Save this one first");
            return;
        }
        askName(0, "Scene " + (scenes["scenes"].count + 1));
    }
    void onCopyScene(Widget@ w) { askName(1, sceneName + " 2"); }
    void onRename(Widget@ w) { askName(2, sceneName); }

    void onNamed(Widget@ w)
    {
        string name = sceneNameField.text;
        if (name.length() > 30)
            name = name.substr(0, 30);
        if (name == "")
            return;
        onClosePopup(null);
        if (naming == 2)
        {
            scenes["scenes"][uint(sceneNow())].set("name", name);
            sceneName = name;
            keepScenes(sceneNow());
            show();
            return;
        }
        if (scenes["scenes"].count >= 12)
        {
            Ui::toast("That is enough scenes");
            return;
        }
        // The first number that no other has.
        string named;
        for (int n = 2; named == ""; n++)
        {
            named = "scene" + n;
            for (uint i = 0; i < scenes["scenes"].count; i++)
                if (scenes["scenes"][i]["file"].text() == named)
                    named = "";
        }
        Json fresh, one;
        if (naming == 0)
        {
            fresh.set("ground", 1);
            fresh.set("hour", 0);
        }
        else
            fresh.copy(write());
        if (!Assets::write(path(named), fresh.write()))
        {
            Ui::toast("It couldn't be made");
            return;
        }
        one.set("name", name);
        one.set("file", named);
        scenes["scenes"].add(one);
        int last = int(scenes["scenes"].count) - 1;
        openScene(last);
        keepScenes(last);
        Ui::toast(name);
    }

    void onDeleteScene(Widget@ w)
    {
        if (scenes["scenes"].count < 2)
        {
            Ui::toast("There must be one");
            return;
        }
        Ui::dialog("Delete", "Delete " + sceneName + "? This can't be undone.", array<string> = { "Delete", "Keep" }, WidgetAnswer(this.deleteScene));
    }
    void deleteScene(int answer)
    {
        if (answer != 0)
            return;
        onClosePopup(null);
        Assets::forget(file);
        scenes["scenes"].remove(uint(sceneNow()));
        openScene(0);
        keepScenes(0);
    }

    // --- Roads ---

    void readRoads(Json@ all)
    {
        for (uint i = 0; i < roads.length(); i++)
            if (roads[i].entity !is null)
                roads[i].entity.destroy();
        roads.resize(0);
        for (uint i = 0; i < all.count && i < 8; i++)
        {
            Road@ r = Road();
            r.width = clamp(float(all[i]["width"].number(7)), 2, 20);
            r.closed = all[i]["closed"].flag(false);
            for (uint k = 0; k < all[i]["points"].count && k < 64; k++)
                r.points.insertLast(all[i]["points"][k].vec3());
            roads.insertLast(r);
        }
        if (road >= int(roads.length()))
            road = int(roads.length()) - 1;
    }

    // Lies on the land as it is now.
    void makeRoad(Road@ r) { r.make(roads.findByRef(r)); }

    Road@ roadNow() { return road >= 0 && road < int(roads.length()) ? roads[uint(road)] : null; }

    void showRoad()
    {
        Road@ r = roadNow();
        roadLabel.text = r is null ? "No road yet" : "Road " + (road + 1) + " of " + roads.length() + ": " + r.points.length() + " points";
        roadClosed.checked = r !is null && r.closed;
        roadWidth.value = r is null ? 7.0f : r.width;
    }

    void showHud()
    {
        hudList.clear();
        for (uint i = 0; i < hud.count; i++)
        {
            Widget@ b = hudList.button(hudKinds[uint(hudKindKeys.find(hud[i]["kind"].text()) < 0 ? 1 : hudKindKeys.find(hud[i]["kind"].text()))] + ": " + hud[i]["name"].text() + "  (" + corners[uint(clamp(float(hud[i]["corner"].number()), 0, 3))] + ")   - take away", WidgetEvent(this.onHudRemove));
            b.tag = int(i);
        }
    }

    void onHudAdd(Widget@ w)
    {
        if (hud.count >= 12)
            return;
        Json one;
        one.set("kind", hudKindKeys[uint(hudKind.chosen)]);
        one.set("name", hudName.text);
        one.set("label", hudName.text);
        one.set("corner", hudCorner.chosen);
        if (hudKind.chosen == 0)
            one.set("color", Color(0.4f, 0.85f, 0.45f));
        hud.add(one);
        showHud();
        changed("hud");
    }

    void onHudRemove(Widget@ w)
    {
        hud.remove(uint(w.tag));
        showHud();
        changed("hud");
    }

    void onRoadNew(Widget@ w)
    {
        if (roads.length() >= 8)
        {
            Ui::toast("That is enough roads");
            return;
        }
        roads.insertLast(Road());
        road = int(roads.length()) - 1;
        showRoad();
    }
    void onRoadNext(Widget@ w)
    {
        road = roads.length() > 0 ? (road + 1) % int(roads.length()) : -1;
        showRoad();
    }
    void onRoad(Widget@ w)
    {
        Road@ r = roadNow();
        if (r is null)
            return;
        r.closed = roadClosed.checked;
        r.width = roadWidth.value;
        makeRoad(r);
        changed("road", false);
    }
    void onRoadBack(Widget@ w)
    {
        Road@ r = roadNow();
        if (r is null || r.points.length() == 0)
            return;
        r.points.removeLast();
        makeRoad(r);
        changed("road");
    }
    void onRoadDelete(Widget@ w)
    {
        Road@ r = roadNow();
        if (r is null)
            return;
        if (r.entity !is null)
            r.entity.destroy();
        roads.removeAt(uint(road));
        road = int(roads.length()) - 1;
        changed("road");
    }

    // The land under it is brought to its height, which is smooth.
    void onRoadLand(Widget@ w)
    {
        Road@ r = roadNow();
        if (r is null || r.path.length() < 2)
            return;
        int n = int(r.path.length());
        array<float> heights(n), wanted(n);
        for (int i = 0; i < n; i++)
            heights[uint(i)] = Space::height(r.path[uint(i)].x, r.path[uint(i)].z);
        for (int i = 0; i < n; i++)
        {
            float sum = 0, count = 0;
            for (int k = -8; k <= 8; k++)
            {
                int at = r.closed ? ((i + k) % n + n) % n : i + k < 0 ? 0 : i + k >= n ? n - 1 : i + k;
                if (heights[uint(at)] > -1000)
                {
                    sum += heights[uint(at)];
                    count += 1;
                }
            }
            wanted[uint(i)] = count > 0 ? sum / count : 0;
        }
        for (int i = 0; i < n; i++)
            Space::level(r.path[uint(i)].x, r.path[uint(i)].z, r.width * 0.95f + 2, wanted[uint(i)], 0.9f);
        landText = Space::landEdits;
        place();
        for (uint i = 0; i < roads.length(); i++)
            makeRoad(roads[i]);
        changed("land");
    }

    int held = -1;   // a point of the road that is being moved

    // Takes the nearest point, if one is near: true if it did.
    bool takePoint(const Vec3 &in p)
    {
        Road@ r = roadNow();
        held = -1;
        for (uint i = 0; r !is null && i < r.points.length(); i++)
            if (Vec3(r.points[i].x - p.x, 0, r.points[i].z - p.z).length() < 2.5f && (held < 0 || (r.points[i] - p).length() < (r.points[uint(held)] - p).length()))
                held = int(i);
        return held >= 0;
    }

    void movePoint(const Vec3 &in p)
    {
        Road@ r = roadNow();
        if (r is null || held < 0)
            return;
        r.points[uint(held)] = Vec3(floor(p.x * 2 + 0.5f) * 0.5f, 0, floor(p.z * 2 + 0.5f) * 0.5f);
        makeRoad(r);
    }

    void putPoint()
    {
        if (held < 0)
            return;
        held = -1;
        changed("road");
    }

    // On the road between two points, it goes between them; elsewhere at the end.
    void addPoint(const Vec3 &in p)
    {
        Road@ r0 = roadNow();
        if (r0 !is null && r0.points.length() >= 2 && r0.points.length() < 64)
        {
            int at = 0;
            if (r0.distance(p, at) < r0.width * 0.5f)
            {
                // Which points it is between, as the path goes.
                uint before = 0;
                for (uint i = 1; i < r0.points.length(); i++)
                {
                    int there = 0;
                    r0.distance(r0.points[i], there);
                    if (there <= at)
                        before = i;
                }
                if (before + 1 < r0.points.length() || r0.closed)
                {
                    r0.points.insertAt(before + 1, Vec3(floor(p.x * 2 + 0.5f) * 0.5f, 0, floor(p.z * 2 + 0.5f) * 0.5f));
                    makeRoad(r0);
                    held = int(before) + 1;
                    hop.play(0.15f, 0, 1.6f);
                    return;
                }
            }
        }
        if (roadNow() is null)
            onRoadNew(null);
        Road@ r = roadNow();
        if (r is null || r.points.length() >= 64)
        {
            Ui::toast("That is enough points");
            return;
        }
        r.points.insertLast(Vec3(floor(p.x * 2 + 0.5f) * 0.5f, 0, floor(p.z * 2 + 0.5f) * 0.5f));
        makeRoad(r);
        changed("road");
        hop.play(0.15f, 0, 1.6f);
    }

    // --- Undoing ---

    // Once for each change. What goes on changing, such as a slider, is one.
    void changed(const string &in key, bool apart = true)
    {
        closeEnds();
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

    int indexOf(const string &in name)
    {
        for (uint i = 0; i < things.length(); i++)
            if (things[i].json["name"].text() == name || things[i].json["arrival"].text() == name)
                return int(i);
        return -1;
    }

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
        bool built = k.key == "model" || k.key == "moving" || k.key == "lift";
        bool cave = k.group == "Caves";
        float y = built ? 0.0f : k.key == "own" ? -k.low.y * k.size : k.key == "shape" ? -k.low.y : 1.5f;
        if (built)
            j.set("model", "global:model/" + k.name + ".glb");
        else if (k.key == "own")
        {
            j.set("model", k.name);
            if (k.size != 1)
                j.set("size", Vec3(k.size, k.size, k.size));
        }
        else if (k.key == "shape")
        {
            j.set("shape", k.name);
            j.set("color", Color(0.97f, 0.62f, 0.2f));
        }
        else if (k.key == "water")
        {
            j.set("shape", "box");
            j.set("pool", true);
            j.set("size", Vec3(8, 1, 8));
            j.set("color", Color(0.16f, 0.45f, 0.6f, 0.65f));
            j.set("shine", 0.8f);
            y = -0.3f;
        }
        else if (k.key == "way" || k.key == "trigger")
        {
            int n = 1;
            while (indexOf((k.key == "way" ? "way " : "trigger ") + n) >= 0)
                n++;
            j.set("name", (k.key == "way" ? "way " : "trigger ") + n);
            j.set("size", Vec3(4, 3, 4));
            if (k.key == "way")
            {
                j.set("to", "");
                j.set("arrive", "");
            }
            else
            {
                j.set("trigger", true);
                j.set("does", "");
                j.set("when", "enter");
            }
            y = 0;
        }
        else if (k.key == "arrival")
        {
            int n = 1;
            while (indexOf("start " + n) >= 0)
                n++;
            j.set("arrival", n == 1 ? "start" : "start " + n);
            y = 0;
        }
        else if (k.key == "sound")
        {
            j.set("sound", k.name);
            j.set("reach", 14);
        }
        else
        {
            j.set("glow", 1.2f);
            j.set("color", Color(1, 0.8f, 0.5f, 0.6f));
            j.set("light", Color(1, 0.75f, 0.45f));
            j.set("range", 9);
        }
        if (k.key == "moving" || k.key == "lift")
        {
            j.set("moves", k.key == "lift" ? Vec3(0, 6, 0) : Vec3(8, 0, 0));
            j.set("seconds", 6);
            y = 1;
        }
        if (k.collider > 0)
            setCollider(j, k.collider);
        if (k.group == "Roads")
        {
            // On a grid of 8 metres, the land flat under it; and on from the chosen one, where it is a road too.
            Vec3 at(floor(p.x / 8 + 0.5f) * 8, 0, floor(p.z / 8 + 0.5f) * 8);
            float turned = 0;
            if (chosen >= 0 && kindOf(things[uint(chosen)].json).group == "Roads")
            {
                Json@ c = things[uint(chosen)].json;
                turned = angles(c).y;
                at = worldPlace(c) + spun(Vec3(0, 0, -8), turned);
            }
            else
                at.y = Space::height(at.x, at.z);
            for (int q = 0; q < 9; q++)
                Space::level(at.x + (q % 3 - 1) * 3.5f, at.z + (q / 3 - 1) * 3.5f, 5, at.y - 0.05f, 1);
            landText = Space::landEdits;
            place();
            j.set("place", Vec3(at.x, at.y, at.z));
            j.set("angles", Vec3(0, turned, 0));
            j.set("shadow", false);
            things.insertLast(Thing(j));
            make(things.length() - 1);
            select(int(things.length()) - 1);
            changed("add");
            return;
        }
        if (cave)
        {
            Vec3 at, turned;
            if (!join(k, at, turned))
            {
                at = Vec3(floor(p.x / 4 + 0.5f) * 4, 0, floor(p.z / 4 + 0.5f) * 4);
                at.y = floor(Space::height(at.x, at.z) * 4) * 0.25f;
            }
            j.set("place", at);
            j.set("angles", turned);
            things.insertLast(Thing(j));
            make(things.length() - 1);
            select(int(things.length()) - 1);
            if (isMouth(k))
                openMouth(at, turned.y);
            else
                cover(k, at, turned.y);
            changed("add");
            return;
        }
        j.set("place", snapped(Vec3(p.x, y, p.z)));
        j.set("onLand", true);
        things.insertLast(Thing(j));
        make(things.length() - 1);
        select(int(things.length()) - 1);
        changed("add");
    }

    // Where the next piece goes: on from the first way out of the chosen one that nothing is on.
    bool join(Kind@ k, Vec3 &out at, Vec3 &out turned)
    {
        if (chosen < 0)
            return false;
        Kind@ from = kindOf(things[uint(chosen)].json);
        if (from.group != "Caves")
            return false;
        Thing@ t = things[uint(chosen)];
        Vec3 base = worldPlace(t.json), a = angles(t.json);
        for (uint i = 0; i < from.exits.length(); i++)
        {
            Vec3 local = from.exits[i].place;
            Vec3 out_ = base + spun(local, a.y);
            // A way down is gone into from the land.
            if (i == 0 && isMouth(from))
                continue;
            bool taken = false;
            for (uint n = 0; n < things.length() && !taken; n++)
            {
                if (int(n) == chosen)
                    continue;
                Kind@ o = kindOf(things[n].json);
                for (uint e = 0; e < o.exits.length(); e++)
                    taken = taken || (worldPlace(things[n].json) + spun(o.exits[e].place, angles(things[n].json).y) - out_).length() < 0.6f;
            }
            if (taken)
                continue;
            Vec3 way_ = spun(Vec3(local.x, 0, local.z).normalized(), a.y);
            // Its own way in is towards z.
            turned = Vec3(0, wrapped(floor(atan2(-way_.x, -way_.z) * 57.29578f + 0.5f)), 0);
            at = out_ - spun(k.exits[0].place, turned.y);
            at = Vec3(floor(at.x * 4 + 0.5f) * 0.25f, floor(at.y * 4 + 0.5f) * 0.25f, floor(at.z * 4 + 0.5f) * 0.25f);
            return true;
        }
        return false;
    }

    Vec3 spun(const Vec3 &in v, float degrees)
    {
        float a = degrees * 0.0174533f;
        return Vec3(v.x * cos(a) + v.z * sin(a), v.y, v.z * cos(a) - v.x * sin(a));
    }

    // Lets the land be gone under there.
    void openMouth(const Vec3 &in at, float turned)
    {
        for (int i = -2; i <= 1; i++)
        {
            Vec3 p = at + spun(Vec3(0, 0, i * 3), turned);
            Space::level(p.x, p.z, 9, at.y, 1);
        }
        for (int i = 0; i <= 1; i++)
        {
            Vec3 p = at + spun(Vec3(0, 0, i * 2), turned);
            Space::hole(p.x, p.z, 1.5f, true);
        }
        Vec3 front = at + spun(Vec3(0, 0, 6), turned);
        Space::level(front.x, front.z, 6, at.y, 0.9f);
        landText = Space::landEdits;
    }

    // Banks the land up where it would come through a roof.
    void cover(Kind@ k, const Vec3 &in at, float turned)
    {
        bool did = false;
        for (float x = k.low.x; x <= k.high.x + 0.1f; x += (k.high.x - k.low.x) / 4)
            for (float z = k.low.z; z <= k.high.z + 0.1f; z += (k.high.z - k.low.z) / 4)
            {
                Vec3 p = at + spun(Vec3(x, 0, z), turned);
                float roof = at.y + k.high.y + 0.5f - (k.name.findFirst("cave-slope") >= 0 ? clamp((4 - z) / 8, 0, 1) * 5 : 0.0f);
                float y = Space::height(p.x, p.z);
                // Not one that stands on the land.
                if (y > at.y && y < roof)
                {
                    Space::level(p.x, p.z, 5, roof + 0.3f, 1);
                    did = true;
                }
            }
        if (did)
        {
            landText = Space::landEdits;
            place();
        }
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
        for (uint i = 0; i < thrown.length(); i++)
            thrown[i].destroy();
        thrown.resize(0);
        if (hero !is null)
            hero.destroy();
        if (ship !is null)
            ship.destroy();
        if (gun !is null)
            gun.destroy();
        @hero = null;
        @ship = null;
        @gun = null;
        if (on && !playing)
        {
            // What there is while editing goes, and the level is made as a game makes it.
            for (uint i = 0; i < things.length(); i++)
                if (things[i].entity !is null)
                    things[i].entity.destroy();
            for (uint i = 0; i < roads.length(); i++)
                if (roads[i].entity !is null)
                    roads[i].entity.destroy();
            level.build(write());
            level.set("health", 100);
            level.set("score", 0);
            level.set("ammo", 30);
        }
        else if (!on && playing)
        {
            level.clear();
            playing = false;
            Json j;
            string error;
            j.parse(now, error);
            read(j);
        }
        playing = on;
        shownFor = 0;
        if (on && way != 2)
            enterPlay();
    }

    // --- Walking and driving ---

    Entity@ hero;
    Entity@ gun;
    string arriving;          // the arrival to begin at, after a way out
    float sinceShot = 0, flash = 0;
    Vec3 shotFrom, shotTo;
    int ammo = 30;
    Entity@ ship;              // what is seen of the one that is driven: it hovers, and lies as the land does
    Vec3 shipUp(0, 1, 0);
    float bank = 0;
    float heroYaw = 0, speed = 0, lap = 0, best = 0, sinceThrow = 0;
    int nextMark = 0;
    Vec3 safe;
    bool racing = false;

    void enterPlay()
    {
        Vec3 p, ahead = look();
        if (!onGround(eye, ahead, p) || (p - eye).length() > 60)
        {
            p = eye + Vec3(ahead.x, 0, ahead.z).normalized() * 4;
            float y = Space::height(p.x, p.z);
            p.y = y > -1000 ? y : eye.y;
        }
        heroYaw = yaw;
        racing = false;
        lap = 0;
        best = 0;
        nextMark = 1;
        speed = 0;
        for (uint i = 0; i < roads.length() && way == 1 && !racing; i++)
        {
            Road@ r = roads[i];
            if (r.path.length() < 8)
                continue;
            road = int(i);
            p = r.path[0];
            p.y = Space::height(p.x, p.z);
            Vec3 d = r.at(1) - r.at(0);
            heroYaw = atan2(d.x, -d.z) * 57.29578f;
            racing = true;
        }
        // Gone through a way out: where its arrival is.
        float turned;
        Vec3 there;
        if (arriving != "" && level.arrival(arriving == "-" ? "" : arriving, there, turned))
        {
            p = there;
            heroYaw = 180 - turned;
        }
        arriving = "";
        safe = p + Vec3(0, 0.4f, 0);
        @hero = Space::spawn(safe);
        if (way == 1)
        {
            @ship = Space::spawn(safe);
            ship.model(carModel);
            ship.shine = 0.4f;
            ship.size = Vec3(0.75f, 0.75f, 0.75f);
            shipUp = Vec3(0, 1, 0);
        }
        else if (way != 3)
            hero.model(heroModel);
        if (way == 3)
        {
            Mesh@ m = Mesh();
            // Its barrel along -z, which is the way it faces.
            m.box(Vec3(0, 0, 0), Vec3(0.06f, 0.08f, 0.26f), Color(0.22f, 0.23f, 0.26f));
            m.box(Vec3(0, -0.075f, 0.07f), Vec3(0.045f, 0.11f, 0.06f), Color(0.3f, 0.2f, 0.12f));
            m.box(Vec3(0, 0.012f, -0.2f), Vec3(0.03f, 0.03f, 0.16f), Color(0.12f, 0.12f, 0.14f));
            @gun = Space::spawn(safe);
            gun.mesh(m);
            gun.shadow = false;
            gun.shine = 0.6f;
            pitch = 0;
        }
        hero.capsule(way == 1 ? 0.75f : 0.35f, 1.6f, 1);
        hero.colliderAt = Vec3(0, 0.8f, 0);
        hero.walker = true;
        hero.mass = way == 1 ? 200 : 60;
        hero.angles = Vec3(0, 180 - heroYaw, 0);
        yaw = heroYaw;
        pitch = -14;
    }

    // How high the water is there, or far below.
    float waterAt(const Vec3 &in p)
    {
        float y = waterToggle.checked ? waterHigh.value : -1000.0f;
        for (uint i = 0; i < things.length(); i++)
        {
            Json@ j = things[i].json;
            if (!j["pool"].flag())
                continue;
            Vec3 d = spun(p - worldPlace(j), -angles(j).y), s = sizes(j);
            float top = s.y * 0.5f;
            if (abs(d.x) < s.x * 0.5f && abs(d.z) < s.z * 0.5f && d.y < top + 0.5f && d.y > -top - 3 && worldPlace(j).y + top > y)
                y = worldPlace(j).y + top;
        }
        return y;
    }

    void playOne(float dt)
    {
        sinceThrow += dt;
        Vec2 stick = Input::move;
        Vec3 m = hero.motion;
        Vec3 p = hero.place;
        float water = waterAt(p);
        bool swimming = p.y < water - 1;
        if (way == 1)
        {
            Vec2 triggers = Input::padTriggers(0);
            float go = clamp(triggers.y - triggers.x - stick.y, -1, 1);
            bool offRoad = false;
            Road@ r = racing ? roadNow() : null;
            int at = 0;
            if (r !is null)
                offRoad = r.distance(p, at) > r.width * 0.55f;
            float most = swimming ? 4.0f : offRoad ? 12.0f : 26.0f;
            speed += (go > 0 ? go * 13 : go * (speed > 0 ? 26 : 8)) * dt;
            speed -= speed * (go == 0 ? 0.7f : 0.15f) * dt;
            if (speed > most)
                speed -= (speed - most) * clamp(3 * dt, 0, 1);
            speed = clamp(speed, -7, 30);
            // Walls stop it.
            float really = Vec3(m.x, 0, m.z).length();
            if (abs(speed) > 4 && really < abs(speed) * 0.5f && shownFor > 0.6f)
                speed *= 0.7f;
            heroYaw += stick.x * clamp(speed * 0.14f, -1, 1) * (speed > 14 ? 75 : 105) * dt;
            float a = heroYaw * 0.0174533f;
            Vec3 ahead(sin(a), 0, -cos(a));
            float grip = clamp((hero.onGround ? 7 : 1) * dt, 0, 1);
            m.x += (ahead.x * speed - m.x) * grip;
            m.z += (ahead.z * speed - m.z) * grip;
            float turn_ = stick.x * clamp(speed * 0.1f, -1, 1);
            bank += (turn_ - bank) * clamp(6 * dt, 0, 1);
            yaw += wrapAngle(heroYaw - yaw) * clamp(4 * dt, 0, 1);
            if (r !is null)
                race(r, at, dt);
        }
        else if (way == 3)
            shoot(m, m, stick, dt, swimming, water);
        else
        {
            float a = yaw * 0.0174533f;
            Vec3 ahead(sin(a), 0, -cos(a)), side(cos(a), 0, sin(a));
            Vec3 wanted = (side * stick.x - ahead * stick.y) * 6;
            float grip = clamp((hero.onGround ? 12 : 3) * dt, 0, 1);
            m.x += (wanted.x - m.x) * grip;
            m.z += (wanted.z - m.z) * grip;
            if (swimming)
            {
                m.y += (clamp((water - 1.1f - p.y) * 3, -1, 2.5f) - m.y) * clamp(8 * dt, 0, 1);
                m.x *= 0.96f;
                m.z *= 0.96f;
            }
            if (Input::pressed("accept") && (hero.onGround || swimming))
            {
                m.y = 6.4f;
                hop.play(0.35f);
            }
            float going = Vec3(m.x, 0, m.z).length();
            if (wanted.length() > 0.3f)
                hero.face(wanted, clamp(12 * dt, 0, 1));
            hero.animate(!hero.onGround && !swimming && abs(m.y) > 1.5f ? "jump" : going > 4 ? "run" : going > 0.5f || swimming ? "walk" : "idle");
            hero.animationSpeed = going > 4 ? going / 6 : going > 0.5f ? going / 2.4f : 1;
            if ((Input::padTriggers(0).y > 0.6f || (Input::mouseDown(0) && Input::hasMouse)) && sinceThrow > 0.4f)
            {
                sinceThrow = 0;
                throwBall();
            }
        }
        hero.motion = m;
        if (ship !is null)
            float_(dt);
        if (p.y < -60)
        {
            hero.place = safe;
            hero.motion = Vec3();
            speed = 0;
        }
        // Ways out, triggers, and what was shot.
        string goes = level.update(dt, hero, shotNow, shotTo);
        shotNow = false;
        if (goes != "")
        {
            goThrough(goes);
            return;
        }
        if (way == 3)
        {
            Vec3 eyes = hero.place + Vec3(0, 1.6f, 0);
            eye = eyes;
            Space::camera(eyes, eyes + look(), 70);
            float a = yaw * 0.0174533f;
            Vec3 ahead = look(), right(cos(a), 0, sin(a));
            gun.place = eyes + ahead * 0.5f + right * 0.2f - Vec3(0, 0.17f, 0) + ahead * (sinceShot < 0.08f ? -0.06f : 0.0f);
            gun.angles = Vec3(-pitch, -yaw, 0);
            return;
        }
        // Behind it, and not through anything.
        Vec3 from = hero.place + Vec3(0, 1.5f, 0);
        float away = way == 1 ? 7.5f : 4.6f;
        Vec3 wantedEye = from - look() * away + Vec3(0, way == 1 ? 1.2f : 0.4f, 0);
        Vec3 hit, normal;
        if (Space::raycast(from, wantedEye, hit, normal, 0xFFFD))
            wantedEye = hit + normal * 0.2f;
        eye = wantedEye;
        Space::camera(eye, from + look() * 4, 62);
    }

    // Higher than the land under any of it, and tipped as the land is.
    void float_(float dt)
    {
        Vec3 base = hero.place;
        float a = heroYaw * 0.0174533f;
        Vec3 ahead(sin(a), 0, -cos(a)), side(cos(a), 0, sin(a));
        float nose = under_(base + ahead * 1.5f), tail = under_(base - ahead * 1.5f), right = under_(base + side * 1.3f), left_ = under_(base - side * 1.3f);
        Vec3 up(0, 1, 0);
        if (hero.onGround)
            up = (Vec3(0, 1, 0) - ahead * ((nose - tail) / 3) - side * ((right - left_) / 2.6f)).normalized();
        shipUp = (shipUp + (up - shipUp) * clamp(9 * dt, 0, 1)).normalized();
        float highest = base.y;
        array<float> all = { (nose + tail) * 0.5f, (right + left_) * 0.5f };
        for (uint i = 0; i < all.length() && hero.onGround; i++)
            highest = all[i] > highest ? all[i] : highest;
        float y = highest + 0.6f + sin(App::time * 3) * 0.05f;
        Vec3 was = ship.place;
        // Where it is at once, but gently up and down.
        float gentle = was.y + (y - was.y) * clamp(14 * dt, 0, 1);
        ship.place = Vec3(base.x, abs(y - was.y) > 3 ? y : gentle, base.z);
        float pitch_ = -atan2(-(shipUp.x * ahead.x + shipUp.z * ahead.z), shipUp.y) * 57.29578f;
        // Its own right is the other way, as it faces along z.
        float roll_ = atan2(shipUp.x * side.x + shipUp.z * side.z, shipUp.y) * 57.29578f + bank * 22;
        ship.angles = Vec3(pitch_, 180 - heroYaw, roll_);
    }

    // What is under a place, near the height of the one that drives.
    float under_(const Vec3 &in p)
    {
        Vec3 hit, normal;
        if (Space::raycast(p + Vec3(0, 1.8f, 0), p - Vec3(0, 2.5f, 0), hit, normal, 0xFFFD))
            return hit.y;
        return p.y;
    }

    bool shotNow = false;

    // First person: walking as before, looking with the mouse or the right stick, and a gun.
    void shoot(Vec3 &out m, const Vec3 &in was, const Vec2 &in stick, float dt, bool swimming, float water)
    {
        m = was;
        Vec2 moved = Input::mouse - lastMouse;
        lastMouse = Input::mouse;
        if (Input::hasMouse && shownFor > 0.3f && !Ui::busy)
            turnBy(moved.x * 0.25f, -moved.y * 0.25f);
        float a = yaw * 0.0174533f;
        Vec3 ahead(sin(a), 0, -cos(a)), side(cos(a), 0, sin(a));
        Vec3 wanted = (side * stick.x - ahead * stick.y) * 6.5f;
        float grip = clamp((hero.onGround ? 14 : 3) * dt, 0, 1);
        m.x += (wanted.x - m.x) * grip;
        m.z += (wanted.z - m.z) * grip;
        if (swimming)
            m.y += (clamp((water - 1.1f - hero.place.y) * 3, -1, 2.5f) - m.y) * clamp(8 * dt, 0, 1);
        if (Input::pressed("accept") && (hero.onGround || swimming))
        {
            m.y = 6.4f;
            hop.play(0.3f);
        }
        sinceShot += dt;
        bool fire = Input::padTriggers(0).y > 0.5f || (Input::mouseDown(0) && Input::hasMouse) || Input::key("F");
        if (fire && sinceShot > 0.16f && ammo > 0)
        {
            sinceShot = 0;
            ammo--;
            level.set("ammo", ammo);
            Vec3 from = hero.place + Vec3(0, 1.6f, 0), along = look();
            Vec3 hit, normal;
            Entity@ e = Space::pick(from + along * 0.5f, from + along * 200, hit, 0xFFFF, hero);
            if (e is null && !Space::raycast(from + along * 0.5f, from + along * 200, hit, normal, 0xFFFF))
                hit = from + along * 200;
            if (e !is null)
                e.push(along * 9, hit);
            shotFrom = gun.place + look() * 0.3f;
            shotTo = hit;
            shotNow = true;
            bang.play(0.3f, 0, random(0.9f, 1.1f));
            level.set("score", level.number("score") + (e !is null ? 1 : 0));
        }
        if (ammo == 0 && sinceShot > 1.2f)
        {
            ammo = 30;
            level.set("ammo", ammo);
        }
        hero.angles = Vec3(0, -yaw, 0);
    }
    Vec2 lastMouse;

    // Into another scene, at its arrival: "file|arrival".
    void goThrough(const string &in goes)
    {
        int bar = goes.findFirst("|");
        string to = goes.substr(0, uint(bar)), at = goes.substr(uint(bar) + 1);
        int which = -1;
        for (uint i = 0; i < scenes["scenes"].count; i++)
            if (path(scenes["scenes"][i]["file"].text()) == to)
                which = int(i);
        if (which < 0)
        {
            level.say("That way goes nowhere yet");
            return;
        }
        if (dirty)
            onSave(null);
        int keepWay = way;
        play(false);
        openScene(which);
        keepScenes(which);
        way = keepWay;
        arriving = at == "" ? "-" : at;
        play(true);
        level.say(sceneName);
    }

    float wrapAngle(float a)
    {
        a = wrapped(a);
        return a > 180 ? a - 360 : a;
    }

    // Four marks, in order, and then the line.
    void race(Road@ r, int at, float dt)
    {
        lap += dt;
        int n = int(r.path.length());
        int mark = nextMark * n / 4;
        bool last = nextMark == 4;
        int gap = last ? (at < n / 8 ? 0 : n) : at >= mark && at < mark + n / 8 ? 0 : n;
        if (!r.closed && last)
            gap = at >= n - 3 ? 0 : n;
        if (gap != 0)
            return;
        nextMark++;
        if (last)
        {
            best = best == 0 || lap < best ? lap : best;
            Ui::toast("Lap: " + formatFloat(lap, "", 0, 2) + " s");
            lap = 0;
            nextMark = 1;
        }
    }

    void throwBall()
    {
        if (thrown.length() >= 12)
        {
            thrown[0].destroy();
            thrown.removeAt(0);
        }
        Entity@ e = Space::spawn(hero !is null ? hero.place + Vec3(0, 1.4f, 0) + look() : eye + look() * 1.5f);
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
        float was = Space::height(eye.x, eye.z);
        // Through a hole it can go under, and then look about there.
        bool above = eye.y >= was;
        eye += (right * move.x - ahead * move.y + Vec3(0, up, 0)) * (dt * 12);
        float half = Space::landSize > 0 ? Space::landSize * 0.5f + 20 : 1e6f;
        eye = Vec3(clamp(eye.x, -half, half), clamp(eye.y, -60, 140), clamp(eye.z, -half, half));
        float least = Space::height(eye.x, eye.z) + 0.6f;
        if (above && eye.y < least)
            eye.y = least;
    }

    void turnBy(float x, float y)
    {
        yaw += x;
        pitch = clamp(pitch + y, -86, 70);
    }

    void update(float dt)
    {
        shownFor += dt;
        measureOwn();
        takeDropped();
        Vec2 m = Input::mouse;
        Vec2 moved = m - mouse;
        mouse = m;
        bool right = Input::mouseDown(1) && Input::hasMouse, pressed = Input::mouseDown(0) && !left;
        left = Input::mouseDown(0);
        if (right && !Ui::busy && !(playing && way == 3))
            turnBy(moved.x * 0.22f, -moved.y * 0.22f);
        Vec2 stick = Input::padRight(0);
        turnBy(stick.x * dt * 110, stick.y * dt * 80);
        Vec2 triggers = Input::padTriggers(0);

        // With the right button held, keys move the camera instead.
        Vec2 move = Input::move;
        bool wasFlying = flying;
        flying = right && (wasFlying || move.x != 0 || move.y != 0);
        bool free = viewing || playing;
        if (hero !is null)
            free = false;
        if (free || flying)
            fly(move, free ? triggers.y - triggers.x : 0.0f, dt);
        if (!Ui::busy && hero is null && overView(mouse) && Input::wheel != 0)
            eye += look() * (Input::wheel * 1.5f);
        if (Input::mouseDown(2) && Input::hasMouse && !Ui::busy)
        {
            Vec3 side = look().cross(Vec3(0, 1, 0)).normalized();
            eye += side * (-moved.x * 0.03f) + Vec3(0, moved.y * 0.03f, 0);
        }
        bool panels = !free && !flying && !playing;
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

        if (playing && hero !is null)
        {
            playOne(dt);
            if (Input::pressed("cancel") || (Input::pressed("alternate") && way != 3))
                play(false);
            return;
        }
        if (playing)
        {
            string goes = level.update(dt);
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
        withMouse(pressed, dt);
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
        if (roading)
        {
            if (Input::pressed("alternate") || tapped(5, "Tab"))
            {
                enterView(false);
                return;
            }
            aim(ahead);
            if (held >= 0 && hasSpot)
                movePoint(spot);
            if (Input::pressed("accept") && hasSpot)
            {
                if (held >= 0)
                    putPoint();
                else if (!takePoint(spot))
                    addPoint(spot);
            }
            if (Input::pressed("cancel"))
                onRoadBack(null);
            return;
        }
        if (sculpting)
        {
            if (Input::pressed("alternate") || tapped(5, "Tab"))
            {
                endStroke();
                enterView(false);
                return;
            }
            bool sooner = padTapped(0, 12), later = padTapped(1, 13);
            if (Input::pressed("cancel") || sooner || later)
            {
                endStroke();
                brush = (brush + (sooner ? brushes.length() - 1 : 1)) % brushes.length();
                brushChoice.chosen = brush;
            }
            aim(ahead);
            stroke(Input::held("accept"), dt);
            return;
        }
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

    // --- The land ---

    void aim(const Vec3 &in along)
    {
        hasSpot = onGround(eye, along, spot) && (spot - eye).length() < 120;
    }

    // While it is held down, it goes on.
    void stroke(bool held, float dt)
    {
        if (!held || !hasSpot)
        {
            if (!held)
                endStroke();
            return;
        }
        if (!stroking)
            levelTo = spot.y;
        stroking = true;
        float s = brushForce;
        if (brush < 2)
            Space::raise(spot.x, spot.z, brushSize, (brush == 0 ? 5 : -5) * s * dt);
        else if (brush == 2)
            Space::smooth(spot.x, spot.z, brushSize, clamp(s * dt * 25, 0, 1));
        else if (brush == 3)
            Space::level(spot.x, spot.z, brushSize, levelTo, clamp(s * dt * 8, 0, 1));
        else if (brush >= 6)
            Space::hole(spot.x, spot.z, brushSize * 0.5f, brush == 6);
        else
            Space::paint(spot.x, spot.z, brushSize, brush == 4 ? brushColor : Color(0, 0, 0, 0), clamp(s * dt * 10, 0, 1));
        // What is near goes with it.
        for (uint i = 0; brush < 4 && i < things.length(); i++)
        {
            Vec3 d = things[i].json["place"].vec3() - spot;
            if (d.x * d.x + d.z * d.z < (brushSize + 3) * (brushSize + 3))
                put(things[i]);
        }
    }

    void endStroke()
    {
        if (!stroking)
            return;
        stroking = false;
        landText = Space::landEdits;
        place();
        for (uint i = 0; i < roads.length(); i++)
            makeRoad(roads[i]);
        changed("land");
    }

    void ring(Canvas@ c)
    {
        Vec2 from, to;
        bool had = false;
        Color color = brush == 4 ? brushColor : brush == 1 ? Color(1, 0.6f, 0.4f) : White;
        for (int i = 0; i <= 40; i++)
        {
            float a = i * 0.15708f;
            float wideOf = roading ? (roadNow() is null ? 3.5f : roadNow().width * 0.5f) : brush >= 6 ? brushSize * 0.5f : brushSize;
            float x = spot.x + cos(a) * wideOf, z = spot.z + sin(a) * wideOf;
            float y = Space::height(x, z);
            bool has = y > -1000 && Space::toScreen(Vec3(x, y + 0.1f, z), to);
            if (has && had)
                c.line(from.x, from.y, to.x, to.y, stroking ? 3.5f : 2, color);
            from = to;
            had = has;
        }
    }

    bool overView(const Vec2 &in p) { return p.y > 82 && p.x > 334 && p.x < wide - 308; }
    float wide = 1280;

    void withMouse(bool pressed, float dt)
    {
        if (!Input::hasMouse)
        {
            hasSpot = false;
            return;
        }
        if (roading)
        {
            hover = -1;
            hasSpot = false;
            if (overView(mouse))
                aim(Space::ray(mouse));
            if (held >= 0)
            {
                if (Input::mouseDown(0) && hasSpot)
                    movePoint(spot);
                else if (!Input::mouseDown(0))
                    putPoint();
                return;
            }
            if (pressed && hasSpot && !takePoint(spot))
                addPoint(spot);
            return;
        }
        if (sculpting)
        {
            hover = -1;
            hasSpot = false;
            if (overView(mouse))
                aim(Space::ray(mouse));
            if (stroking || pressed)
                stroke(Input::mouseDown(0) && (stroking || overView(mouse)), dt);
            return;
        }
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
        bool glow = t.json.has("glow") || t.json.has("sound");
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
            if ((sculpting || roading) && hasSpot)
                ring(c);
            if (viewing && !sculpting && !roading && under >= 0 && under != chosen && under < int(things.length()))
                box(c, things[uint(under)], Color(1, 1, 1, 0.5f));
            if (roading && roadNow() !is null)
                for (uint i = 0; i < roadNow().points.length(); i++)
                {
                    Vec3 p = roadNow().points[i];
                    Vec2 at;
                    p.y = Space::height(p.x, p.z) + 0.2f;
                    if (Space::toScreen(p, at))
                        c.circle(at.x, at.y, int(i) == held ? 9 : 6, int(i) == held ? White : i == 0 ? Color(0.4f, 1, 0.5f) : Color(1, 0.9f, 0.4f));
                }
            if (chosen >= 0 && !sculpting && !roading)
            {
                Json@ j = things[uint(chosen)].json;
                Vec2 one, two;
                if (j.has("moves") && Space::toScreen(worldPlace(j), one) && Space::toScreen(worldPlace(j) + j["moves"].vec3(), two))
                {
                    c.line(one.x, one.y, two.x, two.y, 2, Color(0.5f, 0.9f, 1, 0.8f));
                    c.ring(two.x, two.y, 7, 2, Color(0.5f, 0.9f, 1));
                }
                box(c, things[uint(chosen)], Color(1, 0.75f, 0.25f, 0.9f));
                if (!viewing)
                    handles(c);
            }
        }
        if (playing)
        {
            if (way == 3 && sinceShot < 0.07f)
            {
                Vec2 a_, b_;
                if (Space::toScreen(shotFrom, a_) && Space::toScreen(shotTo, b_))
                    c.line(a_.x, a_.y, b_.x, b_.y, 2, Color(1, 0.9f, 0.5f, 0.8f));
                Vec2 m_;
                if (Space::toScreen(shotFrom, m_))
                    c.circle(m_.x, m_.y, 10, Color(1, 0.85f, 0.4f, 0.8f));
            }
            level.drawHud(c);
            c.designHeight(720);
        }
        if (viewing || playing)
        {
            float x = wide * 0.5f;
            if (hero is null || way == 3)
            {
            c.line(x - 11, 360, x - 4, 360, 2, Color(1, 1, 1, 0.8f));
            c.line(x + 4, 360, x + 11, 360, 2, Color(1, 1, 1, 0.8f));
            c.line(x, 349, x, 356, 2, Color(1, 1, 1, 0.8f));
            c.line(x, 364, x, 371, 2, Color(1, 1, 1, 0.8f));
            }
            string text = playing && way == 3 ? "Accept jumps      Trigger, mouse or F shoots      Cancel goes back to editing"
                : playing && hero !is null ? (way == 1 ? (racing ? "Lap " + formatFloat(lap, "", 0, 1) + (best > 0 ? "      Best " + formatFloat(best, "", 0, 2) : "") + "      " : "") + "Cancel goes back to editing" : "Accept jumps      Right trigger throws a ball      Cancel goes back to editing")
                : playing ? "Accept throws a ball      Cancel goes back to editing"
                : roading ? held >= 0 ? "Accept puts the point down" : "Accept adds a point, or takes one      Cancel takes the last back      Alternate brings the panels back"
                : sculpting ? brushes[uint(brush)] + "      Hold Accept to change the land      Cancel or shoulders for another brush"
                : carrying ? "Accept puts it down      Shoulders turn it      Cancel puts it back"
                : "Accept takes what is in the middle      Alternate brings the panels back";
            Vec2 s = font.measure(text);
            c.roundRect(x - s.x * 0.5f - 18, 660, s.x + 36, 38, 19, Color(0, 0, 0, 0.5f));
            c.text(font, text, x, 667, Color(0.9f, 0.94f, 1), AlignCenter);
        }
        Ui::draw(c);
    }
}
