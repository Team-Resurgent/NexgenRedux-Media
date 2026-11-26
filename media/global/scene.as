// Loads what the scene editor makes, for any screen: #include "global:scene.as"
//
//     Level level;
//     level.load("asset:village.json");
//     ...each update: string out = level.update(dt, player);    // the way out that was gone through, if any
//
// A thing with a name can be found, shown, hidden and switched on and off. Triggers do what the editor says, and tell the
// screen too, through onTouch. Ways out lead to another scene, to the arrival of a name there.

funcdef void LevelTouch(const string &in name, Entity@ who);

// A track: it goes through its points, and lies on the land.
class Road
{
    array<Vec3> points;
    float width = 7;
    bool closed = false;
    Entity@ entity;
    array<Vec3> path;

    Vec3 point(int i)
    {
        int n = int(points.length());
        return points[uint(closed ? (i % n + n) % n : i < 0 ? 0 : i >= n ? n - 1 : i)];
    }

    // Smooth, and about 2 metres from one to the next.
    void follow()
    {
        path.resize(0);
        int n = int(points.length());
        if (n < 2)
            return;
        int parts = closed && n > 2 ? n : n - 1;
        for (int i = 0; i < parts && path.length() < 900; i++)
        {
            Vec3 a = point(i - 1), b = point(i), c = point(i + 1), d = point(i + 2);
            int steps = int(clamp((c - b).length() * 0.5f, 1, 60));
            for (int k = 0; k < steps; k++)
            {
                float t = float(k) / steps;
                path.insertLast((b * 2 + (c - a) * t + (a * 2 - b * 5 + c * 4 - d) * (t * t) + (b * 3 - a - c * 3 + d) * (t * t * t)) * 0.5f);
            }
        }
        if (!(closed && n > 2))
            path.insertLast(points[uint(n - 1)]);
    }

    Vec3 at(int i)
    {
        int n = int(path.length());
        return path[uint(closed ? (i % n + n) % n : i < 0 ? 0 : i >= n ? n - 1 : i)];
    }

    Vec3 side(int i)
    {
        Vec3 way = at(i + 1) - at(i - 1);
        way.y = 0;
        return way.length() > 0.001f ? way.normalized().cross(Vec3(0, 1, 0)) : Vec3(1, 0, 0);
    }

    // How far a place is from it, and where along it that is.
    float distance(const Vec3 &in p, int &out index)
    {
        float best = 1e9f;
        index = 0;
        for (uint i = 0; i < path.length(); i++)
        {
            Vec3 d = path[i] - p;
            d.y = 0;
            float far = d.dot(d);
            if (far < best)
            {
                best = far;
                index = int(i);
            }
        }
        return sqrt(best);
    }

    // Lies on the land as it is now; a little higher for each road before it, where they cross.
    void make(int index)
    {
        if (entity !is null)
            entity.destroy();
        @entity = null;
        follow();
        int n = int(path.length());
        if (n < 2)
            return;
        Mesh@ m = Mesh();
        array<float> offsets = { -0.5f, -0.46f, -0.2f, 0.2f, 0.46f, 0.5f };
        Color road(0.23f, 0.24f, 0.26f), red(0.8f, 0.25f, 0.22f), white(0.92f, 0.92f, 0.9f);
        int rows = closed && points.length() > 2 ? n + 1 : n;
        for (int i = 0; i < rows; i++)
        {
            Vec3 middle = at(i), across = side(i);
            for (uint k = 0; k < 6; k++)
            {
                Vec3 p = middle + across * (offsets[k] * width);
                // The highest that is near, so that no bump of the land between comes through.
                float y = -10000;
                for (int q = 0; q < 9; q++)
                {
                    float h = Space::height(p.x + (q % 3 - 1) * 1.1f, p.z + (q / 3 - 1) * 1.1f);
                    y = h > y ? h : y;
                }
                p.y = (y < -1000 ? middle.y : y) + 0.1f + index * 0.012f;
                bool kerb = k == 0 || k == 5;
                m.vertex(p, Vec3(0, 1, 0), kerb ? ((i / 2) % 2 == 0 ? white : red) : road);
            }
        }
        for (int i = 0; i + 1 < rows; i++)
            for (uint k = 0; k < 5; k++)
            {
                uint a = uint(i) * 6 + k, b = a + 1, c = a + 6, d = a + 7;
                m.triangle(a, d, b);
                m.triangle(a, c, d);
            }
        @entity = Space::spawn(Vec3());
        entity.mesh(m);
        entity.twoSided = true;
        entity.shadow = false;
    }
}

// Something that is shown or hidden over a time.
class Change
{
    uint index;
    float time, seconds;
    bool showing;
    string how;
}

class Level
{
    Json data;                 // the whole file
    array<Json@> things;
    array<Entity@> made;       // for each of those, or null while it isn't there
    array<bool> hidden;        // by the game, or until it is shown
    array<bool> on;            // triggers and ways out
    array<bool> inside;        // whoever it is, last time
    array<Road@> roads;
    array<Entity@> caps;
    array<Change@> changes;
    array<string> valueNames, valueTexts;   // for the HUD
    array<float> valueNumbers;
    LevelTouch@ onTouch;
    string file;
    int ground = 1, across = 1, hour = 0;
    bool endless = false;
    Texture@ skyPicture;
    Model@ capModel = Assets::model("global:model/cave-cap.glb");
    Font@ hudFont = Assets::font("global:freesans.sfn", 22);
    Font@ hudBig = Assets::font("global:freesans.sfn", 34);
    string message;
    float messageFor = 0;

    // --- Loading ---

    bool load(const string &in name)
    {
        Json j;
        string error;
        if (!j.parse(Assets::read(name), error))
            return false;
        file = name;
        build(j);
        return true;
    }

    // Everything in it, made again.
    void build(Json@ all)
    {
        clear();
        data.copy(all);
        makeLand(data);
        makeSky(data);
        Json@ list = data["entities"];
        for (uint i = 0; i < list.count; i++)
        {
            Json@ j = Json();
            j.copy(list[i]);
            things.insertLast(j);
            made.insertLast(null);
            hidden.insertLast(j["hidden"].flag());
            on.insertLast(j["on"].flag(true));
            inside.insertLast(false);
        }
        readRoads(data["roads"]);
        for (uint i = 0; i < things.length(); i++)
            if (!endless)
                spawn(i);
        closeEnds();
    }

    void clear()
    {
        messageFor = 0;
        for (uint i = 0; i < made.length(); i++)
            if (made[i] !is null)
                made[i].destroy();
        for (uint i = 0; i < roads.length(); i++)
            if (roads[i].entity !is null)
                roads[i].entity.destroy();
        for (uint i = 0; i < caps.length(); i++)
            caps[i].destroy();
        things.resize(0);
        made.resize(0);
        hidden.resize(0);
        on.resize(0);
        inside.resize(0);
        roads.resize(0);
        caps.resize(0);
        changes.resize(0);
    }

    // What only the editor and this file know of: the engine is given the rest.
    array<string> own = { "trigger", "does", "target", "when", "once", "to", "arrive", "arrival", "hidden", "appear", "on", "pool", "message", "noise" };

    Entity@ spawn(uint i)
    {
        Json@ j = things[i];
        if (made[i] !is null && made[i].alive)
            return made[i];
        @made[i] = null;
        if (hidden[i] || j.has("trigger") || j.has("arrival") || j.has("to"))
            return null;
        Json plain;
        plain.copy(j);
        for (uint k = 0; k < own.length(); k++)
            plain.remove(own[k]);
        @made[i] = Space::make(plain);
        if (endless && made[i] !is null)
            made[i].streamed = true;
        return made[i];
    }

    // --- The land and the sky ---

    void makeLand(Json@ all)
    {
        ground = int(all["ground"].number(1));
        across = int(all["across"].number(1));
        endless = ground == 3;
        uint squares = uint(32) << uint(clamp(float(across), 0, 3));
        if (endless)
            Space::endlessLand(7, 2, 9, 0.45f, App::freeKilobytes > 0 && App::freeKilobytes < 64000 ? 3 : 4);
        else if (ground == 0)
        {
            Space::land(1, squares, 2, 0.001f);
            Space::landColors(Color(0.42f, 0.56f, 0.34f), Color(0.42f, 0.56f, 0.34f), Color(0.42f, 0.56f, 0.34f), Color(0.4f, 0.4f, 0.4f), -1, 1);
        }
        else
            Space::land(ground == 1 ? 7 : 12, squares, 2, ground == 1 ? 7 : 12, 0.45f, ground == 2);
        if (ground > 0)
        {
            Space::landColors(Color(0.78f, 0.7f, 0.48f), Color(0.36f, 0.52f, 0.28f), Color(0.5f, 0.56f, 0.36f), Color(0.45f, 0.42f, 0.4f), ground == 2 ? 0.8f : -20, 7);
            // Room to build on.
            if (!endless)
                Space::flatten(0, 0, across == 0 ? 14.0f : 24.0f, ground == 2 ? 2.5f : Space::height(0, 0));
        }
        Space::edges = !endless && all["edges"].flag(true);
        // Grass near the camera, and far trees as pictures of themselves; less of both where memory is short.
        bool small = App::freeKilobytes > 0 && App::freeKilobytes < 64000;
        float grass = float(all["grass"].number());
        Space::grass(grass > 0 ? Assets::model("global:model/grass.glb") : null, grass * (small ? 0.25f : 1.0f), small ? 16 : 36);
        Space::impostors = small ? 45 : 75;
        Space::restoreLand(all["land"].text());
    }

    // As the time of day has it, unless it was set otherwise.
    void makeSky(Json@ all)
    {
        hour = int(all["hour"].number());
        Json@ sky = all["sky"];
        Color top = hour == 0 ? Color(0.25f, 0.5f, 0.85f) : hour == 1 ? Color(0.25f, 0.24f, 0.45f) : Color(0.015f, 0.02f, 0.06f);
        Color low = hour == 0 ? Color(0.72f, 0.83f, 0.92f) : hour == 1 ? Color(0.95f, 0.6f, 0.4f) : Color(0.07f, 0.09f, 0.17f);
        Vec3 sun = hour == 1 ? Vec3(0.8f, 0.3f, -0.4f) : Vec3(0.45f, 0.8f, 0.4f);
        if (sky.has("mist"))
            low = sky["mist"].color();
        if (sky.has("sunHigh"))
        {
            float a = float(sky["sunTurn"].number()) * 0.0174533f, h = float(sky["sunHigh"].number()) * 0.0174533f;
            sun = Vec3(sin(a) * cos(h), sin(h), cos(a) * cos(h));
        }
        float from = float(sky["fogFrom"].number(60)), to = float(sky["fogTo"].number(170));
        to = to > from + 5 ? to : from + 5;
        @skyPicture = sky["picture"].text() == "" ? null : Assets::texture(sky["picture"].text());
        Space::skyPicture(skyPicture);
        Space::sky(top, low);
        Space::fog(low, from, to);
        Space::farthest(to + 15);
        Space::sun(sun, hour == 0 ? Color(0.95f, 0.9f, 0.8f) : hour == 1 ? Color(0.9f, 0.5f, 0.3f) : Color(0.16f, 0.2f, 0.32f));
        Space::ambient(hour == 0 ? Color(0.42f, 0.46f, 0.55f) : hour == 1 ? Color(0.34f, 0.3f, 0.4f) : Color(0.12f, 0.14f, 0.24f), hour == 0 ? Color(0.25f, 0.24f, 0.2f) : Color(0.1f, 0.09f, 0.1f));
        Space::shadows(hour == 2 ? 0.35f : 0.6f, 34);
        bool sea = sky["sea"].flag(ground == 2);
        Space::water(sea ? float(sky["seaHigh"].number(0)) : -200.0f, Color(0.16f, 0.4f, 0.5f, 0.8f));
    }

    void readRoads(Json@ all)
    {
        for (uint i = 0; i < all.count && i < 8; i++)
        {
            Road@ r = Road();
            r.width = clamp(float(all[i]["width"].number(7)), 2, 20);
            r.closed = all[i]["closed"].flag(false);
            for (uint k = 0; k < all[i]["points"].count && k < 64; k++)
                r.points.insertLast(all[i]["points"][k].vec3());
            roads.insertLast(r);
            r.make(int(i));
        }
    }

    // --- Caves ---

    // Where each way in or out of a cave piece is, from its middle: by its name, "cave-tunnel" or one of your own like it.
    array<Vec3>@ exitsOf(const string &in model)
    {
        array<Vec3> list;
        int at = model.findFirst("cave-");
        if (at < 0)
            return list;
        string n = model.substr(uint(at) + 5);
        if (n.findFirst("cross") == 0 || n.findFirst("fork") == 0 || n.findFirst("hall") == 0)
        {
            float far = n.findFirst("hall") == 0 ? 8.0f : 4.0f;
            list.insertLast(Vec3(0, 0, far));
            list.insertLast(Vec3(0, 0, -far));
            if (n.findFirst("hall") != 0)
                list.insertLast(Vec3(4, 0, 0));
            if (n.findFirst("cross") == 0)
                list.insertLast(Vec3(-4, 0, 0));
            return list;
        }
        bool big = n.findFirst("room") == 0, falls = n.findFirst("slope") == 0 || n.findFirst("mouth") == 0;
        list.insertLast(Vec3(0, 0, big ? 8 : 4));
        if (n.findFirst("bend") == 0)
            list.insertLast(Vec3(4, 0, 0));
        else if (n.findFirst("end") != 0 && n.findFirst("cap") != 0)
            list.insertLast(Vec3(0, falls ? -5 : 0, big ? -8 : -4));
        if (big)
        {
            list.insertLast(Vec3(8, 0, 0));
            list.insertLast(Vec3(-8, 0, 0));
        }
        return list;
    }

    Vec3 spun(const Vec3 &in v, float degrees)
    {
        float a = degrees * 0.0174533f;
        return Vec3(v.x * cos(a) + v.z * sin(a), v.y, v.z * cos(a) - v.x * sin(a));
    }

    Vec3 placeOf(Json@ j)
    {
        Vec3 p = j["place"].vec3();
        if (j["onLand"].flag())
            p.y += Space::height(p.x, p.z);
        return p;
    }

    float turnOf(Json@ j) { return j["angles"].isNumber ? float(j["angles"].number()) : j["angles"].vec3().y; }

    // Ends of caves that nothing is on are walled off.
    void closeEnds(array<Json@>@ list = null)
    {
        for (uint i = 0; i < caps.length(); i++)
            caps[i].destroy();
        caps.resize(0);
        array<Json@>@ from = list is null ? things : list;
        array<Vec3> ends, ways;
        array<uint> whose;
        for (uint i = 0; i < from.length(); i++)
        {
            string model = from[i]["model"].text();
            array<Vec3>@ exits = exitsOf(model);
            Vec3 base = placeOf(from[i]);
            float turned = turnOf(from[i]);
            for (uint e = model.findFirst("cave-mouth") >= 0 ? 1 : 0; e < exits.length(); e++)
            {
                ends.insertLast(base + spun(exits[e], turned));
                ways.insertLast(spun(Vec3(exits[e].x, 0, exits[e].z).normalized(), turned));
                whose.insertLast(i);
            }
        }
        for (uint i = 0; i < ends.length() && caps.length() < 40; i++)
        {
            bool open = true;
            for (uint n = 0; n < ends.length() && open; n++)
                open = whose[n] == whose[i] || (ends[n] - ends[i]).length() > 0.6f;
            if (!open)
                continue;
            Entity@ c = Space::spawn(ends[i]);
            c.model(capModel);
            c.angles = Vec3(0, atan2(-ways[i].x, -ways[i].z) * 57.29578f, 0);
            c.twoSided = true;
            c.exact(0, 0);
            c.wall = true;
            caps.insertLast(c);
        }
    }

    // --- What a game does with it ---

    int indexOf(const string &in name)
    {
        for (uint i = 0; i < things.length(); i++)
            if (things[i]["name"].text() == name)
                return int(i);
        return -1;
    }

    Entity@ find(const string &in name)
    {
        int i = indexOf(name);
        return i < 0 ? null : made[uint(i)];
    }

    // Triggers and ways out: whether they do anything.
    void switchOn(const string &in name, bool now)
    {
        int i = indexOf(name);
        if (i >= 0)
            on[uint(i)] = now;
    }

    bool isOn(const string &in name)
    {
        int i = indexOf(name);
        return i >= 0 && on[uint(i)];
    }

    // In, over some seconds: "grow", "rise" from the ground, or "drop" from above.
    void show(const string &in name, float seconds = 0.6f, const string &in how = "")
    {
        int i = indexOf(name);
        if (i < 0)
            return;
        hidden[uint(i)] = false;
        Entity@ e = spawn(uint(i));
        Change c;
        c.index = uint(i);
        c.seconds = seconds;
        c.showing = true;
        c.how = how == "" ? things[uint(i)]["appear"].text("grow") : how;
        if (e !is null && seconds > 0)
        {
            changes.insertLast(c);
            step(c, 0);
        }
    }

    void hide(const string &in name, float seconds = 0.4f)
    {
        int i = indexOf(name);
        if (i < 0 || made[uint(i)] is null)
            return;
        hidden[uint(i)] = true;
        Change c;
        c.index = uint(i);
        c.seconds = seconds;
        c.showing = false;
        c.how = things[uint(i)]["appear"].text("grow");
        if (seconds <= 0)
        {
            made[uint(i)].destroy();
            @made[uint(i)] = null;
            return;
        }
        changes.insertLast(c);
    }

    // Where to begin, and which way to face: an arrival of that name, or the first.
    bool arrival(const string &in name, Vec3 &out place, float &out turned)
    {
        for (uint i = 0; i < things.length(); i++)
            if (things[i].has("arrival") && (name == "" || things[i]["arrival"].text() == name))
            {
                place = placeOf(things[i]);
                turned = turnOf(things[i]);
                return true;
            }
        return false;
    }

    // For the HUD: what it shows by name.
    int valueAt(const string &in name)
    {
        int i = valueNames.find(name);
        if (i < 0)
        {
            valueNames.insertLast(name);
            valueTexts.insertLast("");
            valueNumbers.insertLast(0);
            i = int(valueNames.length()) - 1;
        }
        return i;
    }
    void set(const string &in name, float value)
    {
        int i = valueAt(name);
        valueNumbers[uint(i)] = value;
        valueTexts[uint(i)] = "" + int(value);
    }
    void set(const string &in name, const string &in value) { valueTexts[uint(valueAt(name))] = value; }
    float number(const string &in name)
    {
        int i = valueNames.find(name);
        return i < 0 ? 0.0f : valueNumbers[uint(i)];
    }
    string text(const string &in name)
    {
        int i = valueNames.find(name);
        return i < 0 ? "" : valueTexts[uint(i)];
    }
    void say(const string &in text, float seconds = 3)
    {
        message = text;
        messageFor = seconds;
    }

    // --- Each update ---

    void step(Change@ c, float dt)
    {
        c.time += dt;
        Entity@ e = made[c.index];
        if (e is null)
            return;
        float t = c.seconds > 0 ? clamp(c.time / c.seconds, 0, 1) : 1;
        float k = c.showing ? t : 1 - t;
        float eased = k * k * (3 - 2 * k);
        Json@ j = things[c.index];
        Vec3 size = j["size"].isNumber ? Vec3(1, 1, 1) * float(j["size"].number()) : j["size"].vec3(Vec3(1, 1, 1));
        Vec3 place = placeOf(j);
        if (c.how == "rise")
            e.place = place - Vec3(0, (1 - eased) * 4, 0);
        else if (c.how == "drop")
            e.place = place + Vec3(0, (1 - eased) * 10, 0);
        else
            e.size = size * (0.02f + eased * 0.98f);
    }

    // Shows and hides what is changing, does what triggers do (when someone goes into one, or a shot lands in it), and
    // gives back the way out that someone went through:
    // its scene's file and the arrival there, as "file|arrival", or "".
    string update(float dt, Entity@ who = null, bool shot = false, const Vec3 &in shotAt = Vec3())
    {
        messageFor -= dt;
        for (uint i = 0; i < changes.length();)
        {
            Change@ c = changes[i];
            step(c, dt);
            if (c.time >= c.seconds)
            {
                if (!c.showing && made[c.index] !is null)
                {
                    made[c.index].destroy();
                    @made[c.index] = null;
                }
                changes.removeAt(i);
                continue;
            }
            i++;
        }
        if (endless)
            stream();
        string goes;
        Vec3 at = who !is null && who.alive ? who.place + Vec3(0, 0.9f, 0) : Vec3(0, -9999, 0);
        for (uint i = 0; i < things.length(); i++)
        {
            Json@ j = things[i];
            bool trigger = j.has("trigger");
            bool way = j.has("to");
            if (!trigger && !way)
                continue;
            bool now = within(j, at);
            bool entered = now && !inside[i];
            inside[i] = now;
            // A trigger that is shot is one with what was hit inside it.
            bool byShot = shot && j["when"].text() == "shot" && within(j, shotAt);
            if (!on[i] || !(byShot || (entered && j["when"].text("enter") == "enter")))
                continue;
            if (way)
                goes = j["to"].text() + "|" + j["arrive"].text();
            else
                act(j, who);
            if (j["once"].flag())
                on[i] = false;
            if (onTouch !is null)
                onTouch(j["name"].text(), who);
        }
        return goes;
    }

    // Whether a place is in a trigger's box, which turns with it.
    bool within(Json@ j, const Vec3 &in p)
    {
        Vec3 d = spun(p - placeOf(j), -turnOf(j));
        Vec3 size = j["size"].vec3(Vec3(3, 3, 3));
        return abs(d.x) < size.x * 0.5f && abs(d.z) < size.z * 0.5f && d.y > -0.5f && d.y < size.y;
    }

    void act(Json@ j, Entity@ who)
    {
        string does = j["does"].text(), target = j["target"].text();
        if (does == "show")
            show(target);
        else if (does == "hide")
            hide(target);
        else if (does == "open")
            switchOn(target, true);
        else if (does == "close")
            switchOn(target, false);
        else if (does == "sound")
        {
            Sound@ s = Assets::sound(j["noise"].text("global:sound/bell.wav"));
            s.playAt(placeOf(j), 1, 30);
        }
        if (j["message"].text() != "")
            say(j["message"].text());
    }

    // On endless land, what is in each region comes and goes with it.
    void stream()
    {
        int x, z;
        bool arrived;
        while (Space::nextRegion(x, z, arrived))
        {
            if (!arrived)
                continue;
            float size = Space::regionSize;
            for (uint i = 0; i < things.length(); i++)
            {
                Vec3 p = things[i]["place"].vec3();
                if (int(floor(p.x / size)) == x && int(floor(p.z / size)) == z)
                    spawn(i);
            }
        }
    }

    // --- The HUD: what the file says to show, from what the game has set ---

    void drawHud(Canvas@ c)
    {
        Json@ all = data["hud"];
        c.designHeight(720);
        float wide = c.width;
        array<float> heights = { 0, 0, 0, 0 };
        for (uint i = 0; i < all.count; i++)
        {
            Json@ h = all[i];
            string kind = h["kind"].text("text"), name = h["name"].text();
            int corner = int(h["corner"].number());
            Color color = h["color"].color(kind == "bar" ? Color(0.4f, 0.85f, 0.45f) : Color(1, 1, 1));
            bool right = corner == 1 || corner == 3, low = corner >= 2;
            float x = right ? wide - 30 : 30.0f;
            float y = low ? 690 - heights[uint(corner)] - 34 : 26 + heights[uint(corner)];
            if (kind == "cross")
            {
                float m = wide * 0.5f;
                c.line(m - 11, 360, m - 4, 360, 2, color);
                c.line(m + 4, 360, m + 11, 360, 2, color);
                c.line(m, 349, m, 356, 2, color);
                c.line(m, 364, m, 371, 2, color);
                continue;
            }
            string label = h["label"].text(name);
            if (kind == "bar")
            {
                float most = float(h["most"].number(100));
                float t = clamp(number(name) / (most > 0 ? most : 1), 0, 1);
                float bx = right ? x - 240 : x;
                c.text(hudFont, label, bx + 2, y, Color(0, 0, 0, 0.55f));
                c.text(hudFont, label, bx, y - 2, Color(1, 1, 1, 0.9f));
                c.roundRect(bx, y + 24, 240, 14, 7, Color(0, 0, 0, 0.45f));
                c.roundRect(bx + 2, y + 26, 236 * t, 10, 5, color);
                heights[uint(corner)] += 52;
            }
            else
            {
                string value = text(name);
                string shown = label + (label != "" && value != "" ? "  " : "") + value;
                // A soft shadow, so it can be read over a bright sky.
                c.text(kind == "big" ? hudBig : hudFont, shown, x + 2, y + 2, Color(0, 0, 0, 0.55f), right ? AlignRight : AlignLeft);
                c.text(kind == "big" ? hudBig : hudFont, shown, x, y, color, right ? AlignRight : AlignLeft);
                heights[uint(corner)] += kind == "big" ? 44 : 32;
            }
        }
        if (messageFor > 0 && message != "")
        {
            float a = clamp(messageFor * 2, 0, 1);
            Vec2 s = hudBig.measure(message);
            c.roundRect(wide * 0.5f - s.x * 0.5f - 24, 150, s.x + 48, 56, 14, Color(0, 0, 0, 0.5f * a));
            c.text(hudBig, message, wide * 0.5f, 158, Color(1, 1, 1, a), AlignCenter);
        }
    }
}
