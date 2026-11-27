// Shared entities: each player's ship, and the sparks it leaves behind, are kept alike in everyone's game. room.share
// says which are this player's; room.sync, once a frame, says where they are and moves everyone else's after them,
// asking copy() to make one of each. A spark that burns out goes from every game by itself.

const string Game = "nexgen arena";

class ArenaScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 44);
    Sound@ tick = Assets::sound("global:sound/pop.wav");
    Room@ room = Room();
    Entity@ ship;
    array<Entity@> sparks;
    array<Entity@> others;    // copies of the other players' ships
    array<string> news;
    uint chosen = 0;
    float burning = 0;
    string name = "Pilot " + formatInt(randomInt(10, 99));

    Color colorOf(int who) { return hsv(float(who < 0 ? 0 : who) * 0.137f + 0.02f, 0.7f, 1); }

    void tell(const string &in text)
    {
        news.insertLast(text);
        if (news.length() > 4)
            news.removeAt(0);
    }

    void onEnter()
    {
        Scene::gravity = Vec2(0, 0);
        @ship = Scene::spawn(Vec2(640, 380));
        ship.rect(46, 22, colorOf(0));
        ship.layer = 2;
        // Shared from the start: whoever is in a room with it later is told of it.
        room.share(ship, "ship");
    }

    // Another player's: a ship or a spark, in their colour.
    Entity@ copy(const string &in kind, int player)
    {
        Entity@ e = Scene::spawn(Vec2(0, 0));
        if (kind == "ship")
        {
            e.rect(46, 22, colorOf(player));
            e.layer = 2;
            others.insertLast(e);
        }
        else
            e.disc(7, colorOf(player));
        return e;
    }

    void update(float dt)
    {
        room.sync(Copy(this.copy));
        fly(dt);

        if (room.state == RoomIdle || room.state == RoomLost)
        {
            if (Input::pressed("accept"))
                tell(room.host(Game, name, 8) ? "Waiting for others" : "There is no network");
            else if (Input::pressed("alternate"))
            {
                chosen = 0;
                tell(room.find(Game) ? "Looking for an arena" : "There is no network");
            }
            else if (room.state == RoomLost && Input::pressed("cancel"))
                room.leave();
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
        ship.color = colorOf(room.me);
        for (int who = room.arrived(); who >= 0; who = room.arrived())
        {
            tell(room.playerName(who) + " is here");
            tick.play(0.6f);
        }
        for (int who = room.departed(); who >= 0; who = room.departed())
            tell("Pilot " + formatInt(who + 1) + " has gone");
    }

    void fly(float dt)
    {
        Vec2 move = Input::move;
        if (room.state != RoomFinding)
        {
            ship.velocity = move * 340;
            if (move.length() > 0.2f)
                ship.rotation = atan2(move.y, move.x) * 57.29578f;
        }
        else
            ship.velocity = Vec2(0, 0);
        ship.position = Vec2(clamp(ship.x, 30, 1250), clamp(ship.y, 90, 640));

        // Sparks, shared too, that fade and burn out.
        burning -= dt;
        if (Input::held("fire") && burning < 0)
        {
            burning = 0.08f;
            Entity@ s = Scene::spawn(ship.position);
            s.disc(7, colorOf(room.me));
            s.lifetime = 1.4f;
            room.share(s, "spark");
            sparks.insertLast(s);
        }
        for (uint i = 0; i < sparks.length();)
        {
            if (!sparks[i].alive)
            {
                sparks.removeAt(i);
                continue;
            }
            sparks[i].alpha = sparks[i].lifetime / 1.4f;
            i++;
        }
        for (uint i = 0; i < others.length();)
        {
            if (!others[i].alive)
                others.removeAt(i);
            else
                i++;
        }
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.08f, 0.09f, 0.14f), Color(0.03f, 0.04f, 0.07f));
        c.roundRect(20, 80, 1240, 570, 20, Color(0.12f, 0.14f, 0.2f));
        Scene::draw(c);
        for (uint i = 0; i < others.length(); i++)
        {
            int who = room.ownerOf(others[i]);
            if (who >= 0 && others[i].visible)
                c.text(font, room.playerName(who), others[i].x, others[i].y - 42, colorOf(who), AlignCenter);
        }
        c.text(font, room.state == RoomIn ? room.playerName(room.me) : name, ship.x, ship.y - 42, Color(1, 1, 1, 0.8f), AlignCenter);
        c.text(big, "Arena", 30, 18);
        string state;
        if (room.state == RoomIn)
            state = formatInt(int(room.players)) + " flying, " + formatInt(int(room.copies)) + " of theirs here" + (room.hosting ? "" : ", " + formatInt(room.ping(0)) + " ms away");
        else
            state = room.state == RoomFinding ? "Looking" : room.state == RoomJoining ? "Joining" : room.state == RoomLost ? "That didn't work" : "By yourself";
        c.text(font, state, 1250, 30, Color(0.7f, 0.8f, 0.9f), AlignRight);
        for (uint i = 0; i < news.length(); i++)
            c.text(font, news[i], 44, 630 - float(news.length() - i) * 28, Color(0.6f, 0.7f, 0.85f, 0.8f));
        if (room.state == RoomFinding)
        {
            c.roundRect(390, 190, 500, 300, 20, Color(0.1f, 0.12f, 0.18f, 0.94f));
            c.text(font, room.found == 0 ? "Nobody yet..." : "Arenas to fly in", 640, 206, White, AlignCenter);
            for (uint i = 0; i < room.found && i < 6; i++)
            {
                c.roundRect(410, 250 + float(i) * 38, 460, 34, 8, i == chosen ? Blue : Color(1, 1, 1, 0.08f));
                c.text(font, room.foundName(i) + (room.foundFar(i) ? "  (internet)" : ""), 424, 253 + float(i) * 38);
                c.text(font, formatInt(int(room.foundPlayers(i))) + " of " + formatInt(int(room.foundMost(i))), 856, 253 + float(i) * 38, Color(0.8f, 0.85f, 0.95f), AlignRight);
            }
        }
        string help = room.state == RoomIn ? "Move: fly     Fire: sparks     Cancel: leave" : room.state == RoomFinding ? "Up, down: choose     Accept: join     Cancel: stop" : "Move: fly     Accept: open an arena     Alternate: look for one";
        c.text(font, help, 640, 670, Color(0.7f, 0.75f, 0.85f), AlignCenter);
    }
}
