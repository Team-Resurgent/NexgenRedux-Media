// A wall to draw on. One player hosts it, and any on the same network who look for it can join. What is
// drawn is sent for sure; where everyone's pen is, is only sent quickly.

const string Game = "nexgen together";

class Stroke
{
    Vec2 from, to;
    int who;
}

class TogetherScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 24);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Sound@ tick = Assets::sound("global:sound/pop.wav");
    Room@ room = Room();
    array<Stroke@> strokes;
    array<Vec2> pens(8);
    array<string> news;
    Vec2 pen(640, 360), last, mouseWas;
    bool down = false;
    float quiet = 0;
    uint chosen = 0;
    string name = "Player " + formatInt(randomInt(10, 99));

    Color colorOf(int who) { return hsv(float(who) * 0.137f + 0.02f, 0.7f, 1); }

    void tell(const string &in text)
    {
        news.insertLast(text);
        if (news.length() > 5)
            news.removeAt(0);
    }

    void update(float dt)
    {
        pen += Input::move * 520 * dt;
        Vec2 mouse = Input::mouse;
        if (Input::hasMouse && mouse != mouseWas) pen = mouse;
        mouseWas = mouse;
        pen = Vec2(clamp(pen.x, 30, 1250), clamp(pen.y, 90, 640));

        if (room.state == RoomIdle || room.state == RoomLost)
        {
            if (room.state == RoomLost && Input::pressed("cancel"))
                room.leave();
            if (Input::pressed("accept"))
                tell(room.host(Game, name, 8) ? "Waiting for others" : "There is no network");
            else if (Input::pressed("alternate"))
            {
                chosen = 0;
                tell(room.find(Game) ? "Looking for a wall" : "There is no network");
            }
            draws();
            return;
        }
        if (room.state == RoomFinding)
        {
            if (Input::repeated("down") && chosen + 1 < room.found) chosen++;
            if (Input::repeated("up") && chosen > 0) chosen--;
            if (Input::pressed("accept") && room.found > chosen)
                room.join(Game, chosen, name);
            if (Input::pressed("cancel"))
                room.leave();
            return;
        }
        if (Input::pressed("cancel"))
        {
            room.leave();
            return;
        }
        draws();
        for (int who = room.arrived(); who >= 0; who = room.arrived())
        {
            tell(room.playerName(who) + " is here");
            tick.play(0.6f);
            // The host shows them what there is already.
            if (room.hosting)
                for (uint i = 0; i < strokes.length(); i++)
                    say(strokes[i], who);
        }
        for (int who = room.departed(); who >= 0; who = room.departed())
            tell("Player " + formatInt(who + 1) + " has gone");
        for (Message@ m = room.receive(); m !is null; @m = room.receive())
        {
            int kind = m.readInt();
            if (kind == 0)
                pens[uint(m.from)] = m.readVec2();
            else if (kind == 1)
            {
                Stroke@ s = Stroke();
                s.who = m.readInt();
                s.from = m.readVec2();
                s.to = m.readVec2();
                if (m.whole)
                    add(s);
            }
        }
        quiet -= dt;
        if (quiet < 0)
        {
            quiet = 0.05f;
            Message@ m = Message();
            m.writeInt(0);
            m.writeVec2(pen);
            room.send(m, false);
        }
    }

    void say(Stroke@ s, int to)
    {
        Message@ m = Message();
        m.writeInt(1);
        m.writeInt(s.who);
        m.writeVec2(s.from);
        m.writeVec2(s.to);
        room.send(m, true, to);
    }

    void add(Stroke@ s)
    {
        strokes.insertLast(s);
        if (strokes.length() > 900)
            strokes.removeAt(0);
    }

    void draws()
    {
        bool on = Input::held("fire") && !Input::held("accept") || Input::mouseDown(0);
        if (on && !down)
            last = pen;
        Vec2 d = pen - last;
        if (on && d.dot(d) > 80)
        {
            Stroke@ s = Stroke();
            s.from = last;
            s.to = pen;
            s.who = room.me < 0 ? 0 : room.me;
            add(s);
            if (room.state == RoomIn)
                say(s, -1);
            last = pen;
        }
        down = on;
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.1f, 0.12f, 0.16f), Color(0.06f, 0.07f, 0.1f));
        c.roundRect(20, 80, 1240, 570, 20, Color(0.93f, 0.92f, 0.88f));
        for (uint i = 0; i < strokes.length(); i++)
        {
            Color ink = colorOf(strokes[i].who);
            c.line(strokes[i].from.x, strokes[i].from.y, strokes[i].to.x, strokes[i].to.y, 7, ink);
            c.circle(strokes[i].to.x, strokes[i].to.y, 3.5f, ink);
        }
        for (int i = 0; i < 8; i++)
            if (room.present(i) && i != room.me)
            {
                c.circle(pens[uint(i)].x, pens[uint(i)].y, 9, colorOf(i));
                c.text(font, room.playerName(i), pens[uint(i)].x + 14, pens[uint(i)].y - 12, colorOf(i));
            }
        c.circle(pen.x, pen.y, 10, colorOf(room.me < 0 ? 0 : room.me));
        c.ring(pen.x, pen.y, 13, 2, Color(0, 0, 0, 0.5f));
        c.text(big, "Together", 30, 18);
        string state;
        if (room.state == RoomIn)
            state = formatInt(int(room.players)) + " here" + (room.hosting ? ", on your wall at " + Net::address : ", " + formatInt(room.ping(0)) + " ms away");
        else
            state = room.state == RoomFinding ? "Looking" : room.state == RoomJoining ? "Joining" : room.state == RoomLost ? "That didn't work" : "By yourself";
        c.text(font, state, 1250, 30, Color(0.7f, 0.8f, 0.9f), AlignRight);
        for (uint i = 0; i < news.length(); i++)
            c.text(font, news[i], 44, 620 - float(news.length() - i) * 30, Color(0.2f, 0.25f, 0.35f, 0.8f));
        if (room.state == RoomFinding)
        {
            c.roundRect(390, 190, 500, 300, 20, Color(0.1f, 0.12f, 0.18f, 0.94f));
            c.text(font, room.found == 0 ? "Nobody yet..." : "Walls to draw on", 640, 206, White, AlignCenter);
            for (uint i = 0; i < room.found && i < 6; i++)
            {
                c.roundRect(410, 250 + float(i) * 38, 460, 34, 8, i == chosen ? Blue : Color(1, 1, 1, 0.08f));
                c.text(font, room.foundName(i), 424, 253 + float(i) * 38);
                c.text(font, formatInt(int(room.foundPlayers(i))) + " of " + formatInt(int(room.foundMost(i))), 856, 253 + float(i) * 38, Color(0.8f, 0.85f, 0.95f), AlignRight);
            }
        }
        string help = room.state == RoomIn ? "Fire: draw     Cancel: leave" : room.state == RoomFinding ? "Up, down: choose     Accept: join     Cancel: stop" : "Fire: draw     Accept: open a wall for others     Alternate: look for one";
        c.text(font, help, 640, 670, Color(0.7f, 0.75f, 0.85f), AlignCenter);
    }
}
