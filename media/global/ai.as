// Helpers for those the game moves by itself: #include "global:ai.as"
//
// An Agent is something that walks (a walker entity), with a role:
//   "guard"   stands where it was put, looking the way it faced; chases what it sees, searches, then goes back
//   "patrol"  walks a route of places, waiting a moment at each, and chases what it sees as a guard does
//   "wander"  walks about near home, at random
//   "chase"   always goes after its target
//   "flee"    wanders, and runs from its target when that comes near
//   "follow"  keeps near its leader
//   "still"   doesn't move
// What it is doing now is its state: "idle", "walking", "chasing", "searching", "returning", "fleeing" or "following",
// for choosing an animation or a sound. It sees with a range and a field of view, and only what nothing is in front
// of; it hears noises the game makes with Crowd::noise. Ways round what is in the way come from Space::navigate, if
// the game has worked them out; without it, agents walk straight.
//
//     Crowd crowd;                                      // a screen's, or level.crowd
//     Agent@ guard = crowd.add(entity, "patrol");
//     ...each update: crowd.update(dt);  crowd.draw(c) shows what each can see, for working on a game.

funcdef void AgentEvent(Agent@ agent, const string &in what);   // "spotted", "lost", "caught", "heard", "arrived"

class Agent
{
    Entity@ entity;
    string role = "wander";
    string state = "idle";
    float speed = 2.2f;            // walking, metres a second
    float runSpeed = 4.6f;         // chasing or fleeing
    float sight = 14;              // how far it sees
    float fieldOfView = 110;       // degrees across
    float hearing = 12;            // how far it hears a noise of loudness 1
    float reach = 1.3f;            // how near is caught
    float memory = 3;              // seconds it goes on to where it last saw its target
    float roam = 8;                // how far a wanderer goes from home
    float keep = 2.5f;             // how near a follower stays
    array<Vec3> route;             // for a patrol
    bool loop = true;              // round the route again, or back along it
    Vec3 home;
    Vec3 homeFacing(0, 0, 1);
    Entity@ target;                // what it looks for, chases or runs from
    Entity@ leader;                // what a follower follows
    AgentEvent@ onEvent;
    bool animated = true;          // walk, run and idle animations
    bool sprite = false;           // a sprite of two frames, that flickers as it goes

    bool seesTarget = false;
    array<Vec3> fan;               // how far it sees along each line of its fan, for drawing
    array<Vec3> path;
    uint pathAt = 0;
    Vec3 goal, lastSeen, heardAt;
    bool hasGoal = false, needsPath = false;
    float sinceLook = 99;
    float sinceSeen = 99, sincePath = 99, waiting = 0, searching = 0, sinceCaught = 99, stuck = 0;
    int routeAt = 0, routeStep = 1;

    Agent(Entity@ e, const string &in r)
    {
        @entity = e;
        role = r;
        home = e.place;
        homeFacing = e.forward;
    }

    // Whether it can see something: near enough, in front, and with nothing in between.
    bool sees(Entity@ e)
    {
        if (e is null || !e.alive || entity is null)
            return false;
        Vec3 eyes = entity.place + Vec3(0, 1.5f, 0), at = e.place + Vec3(0, 1.1f, 0);
        Vec3 d = at - eyes;
        float far = d.length();
        if (far > sight)
            return false;
        Vec3 flat = Vec3(d.x, 0, d.z);
        Vec3 ahead = entity.forward;
        if (flat.length() > 0.5f && flat.normalized().dot(Vec3(ahead.x, 0, ahead.z).normalized()) < cos(fieldOfView * 0.5f * 0.0174533f))
            return false;
        Vec3 hit, normal;
        return !Space::raycast(eyes, at, hit, normal, 0xFFFD, entity);
    }

    void tell(const string &in what)
    {
        if (onEvent !is null)
            onEvent(this, what);
    }

    // Somewhere to go. The way there is worked out again if it has moved far, or now and then if it is something
    // that moves. The crowd works out one way a frame, so that many at once don't stall it; until then, straight on.
    void goTo(const Vec3 &in to, float every = -1)
    {
        if (hasGoal && (to - goal).length() < 1.2f && (every < 0 || sincePath < every))
            return;
        goal = to;
        hasGoal = true;
        sincePath = 0;
        needsPath = true;
    }

    void findWay()
    {
        needsPath = false;
        pathAt = 1;
        if (!Space::path(entity.place, goal, path) && path.length() < 2)
        {
            path.resize(0);
            path.insertLast(entity.place);
            path.insertLast(goal);
        }
    }

    void stop()
    {
        hasGoal = false;
        needsPath = false;
        path.resize(0);
    }

    bool arrived() { return !hasGoal || (!needsPath && pathAt >= path.length()); }

    // Somewhere near home that can be walked to.
    Vec3 somewhereNear(const Vec3 &in middle, float radius)
    {
        for (int tries = 0; tries < 8; tries++)
        {
            float a = random(0, 6.2832f), r = random(radius * 0.3f, radius);
            Vec3 p = Space::nearestWalkable(middle + Vec3(sin(a) * r, 0, cos(a) * r));
            if (Space::walkable(p) || tries == 7)
                return p;
        }
        return middle;
    }

    void think(float dt)
    {
        sinceSeen += dt;
        sincePath += dt;
        sinceCaught += dt;
        bool saw = seesTarget;
        // A look round ten times a second is enough.
        sinceLook += dt;
        if (sinceLook >= 0.1f)
        {
            sinceLook = 0;
            seesTarget = (role == "guard" || role == "patrol" || role == "flee") && sees(target);
        }
        if (seesTarget)
        {
            sinceSeen = 0;
            lastSeen = target.place;
            if (!saw)
                tell("spotted");
        }
        else if (saw)
            tell("lost");

        if (role == "still")
        {
            state = "idle";
            stop();
        }
        else if (role == "chase" && target !is null && target.alive)
        {
            state = "chasing";
            goTo(target.place, 0.6f);
        }
        else if (role == "follow" && leader !is null && leader.alive)
        {
            float far = (leader.place - entity.place).length();
            if (far > keep * 1.6f || (state == "following" && far > keep))
            {
                state = "following";
                goTo(leader.place, 0.8f);
            }
            else
            {
                state = "idle";
                stop();
            }
        }
        else if (role == "flee")
        {
            if (target !is null && target.alive && (target.place - entity.place).length() < sight * 0.6f)
            {
                // Away, to somewhere that can be walked to.
                Vec3 away = entity.place - target.place;
                away.y = 0;
                away = away.length() > 0.01f ? away.normalized() : Vec3(1, 0, 0);
                state = "fleeing";
                goTo(Space::nearestWalkable(entity.place + away * 8), 0.8f);
            }
            else
                wander(dt);
        }
        else if (role == "guard" || role == "patrol")
        {
            if (seesTarget || sinceSeen < memory)
            {
                state = "chasing";
                goTo(lastSeen, 0.6f);
                searching = 0;
            }
            else if (state == "chasing" || state == "searching")
            {
                // Where it was last seen, or heard, and a look round.
                state = "searching";
                goTo(lastSeen);
                if (arrived())
                {
                    searching += dt;
                    entity.face(Vec3(sin(searching * 2.2f), 0, cos(searching * 2.2f)), clamp(dt * 3, 0, 1));
                    if (searching > 3)
                    {
                        state = "returning";
                        stop();
                    }
                }
            }
            else if (role == "patrol" && route.length() > 0)
            {
                state = waiting > 0 ? "idle" : "walking";
                waiting -= dt;
                if (waiting <= 0)
                {
                    goTo(route[uint(routeAt)]);
                    if (arrived())
                    {
                        waiting = 1.2f;
                        tell("arrived");
                        if (route.length() > 1)
                        {
                            if (!loop && (routeAt + routeStep < 0 || routeAt + routeStep >= int(route.length())))
                                routeStep = -routeStep;
                            routeAt = (routeAt + routeStep + int(route.length())) % int(route.length());
                        }
                    }
                }
            }
            else
            {
                // Back where it stands guard, then facing as it was put.
                if ((home - entity.place).length() > 0.8f)
                {
                    state = "returning";
                    goTo(home);
                }
                else
                {
                    state = "idle";
                    stop();
                    entity.face(homeFacing, clamp(dt * 3, 0, 1));
                }
            }
        }
        else
            wander(dt);

        // Caught: once in a while, as long as it stays near.
        if ((state == "chasing") && target !is null && target.alive && (target.place - entity.place).length() < reach && sinceCaught > 1)
        {
            sinceCaught = 0;
            tell("caught");
        }
    }

    void wander(float dt)
    {
        if (state != "walking" && state != "idle")
            stop();
        if (arrived())
        {
            if (state == "walking")
            {
                state = "idle";
                waiting = random(1, 3.5f);
            }
            waiting -= dt;
            if (waiting <= 0)
            {
                state = "walking";
                goTo(somewhereNear(home, roam));
            }
        }
    }

    // A noise somewhere: guards and patrols go to see.
    void hear(const Vec3 &in at, float loudness)
    {
        if ((at - entity.place).length() > hearing * loudness)
            return;
        if (role == "guard" || role == "patrol")
        {
            if (state != "chasing")
            {
                lastSeen = at;
                state = "searching";
                searching = 0;
                stop();
            }
            tell("heard");
        }
        else if (role == "wander" || role == "flee")
        {
            entity.face(at - entity.place, 1);
            tell("heard");
        }
    }

    // Along the way, pushed apart from others near it.
    void move(float dt, const Vec3 &in apart)
    {
        Vec3 want;
        if (hasGoal && needsPath)
        {
            // Its way isn't worked out yet: straight there.
            Vec3 to = goal - entity.place;
            to.y = 0;
            if (to.length() > 0.35f)
                want = to.normalized() * (state == "chasing" || state == "fleeing" ? runSpeed : speed);
        }
        else if (hasGoal && pathAt < path.length())
        {
            Vec3 to = path[pathAt] - entity.place;
            to.y = 0;
            if (to.length() < (pathAt + 1 == path.length() ? 0.35f : 0.7f))
                pathAt++;
            else
                want = to.normalized() * (state == "chasing" || state == "fleeing" ? runSpeed : speed);
        }
        want = want + apart;
        Vec3 m = entity.motion;
        float grip = clamp((entity.onGround ? 10 : 2) * dt, 0, 1);
        m.x += (want.x - m.x) * grip;
        m.z += (want.z - m.z) * grip;
        // Not getting anywhere: the way is worked out again.
        float going = Vec3(m.x, 0, m.z).length();
        stuck = want.length() > 0.5f && going < 0.3f ? stuck + dt : 0;
        if (stuck > 1)
        {
            stuck = 0;
            sincePath = 99;
            if (hasGoal)
            {
                Vec3 g = goal;
                hasGoal = false;
                goTo(g);
            }
        }
        entity.motion = m;
        if (going > 0.3f)
            entity.face(Vec3(m.x, 0, m.z), clamp(dt * 8, 0, 1));
        if (sprite)
            entity.spriteFrame = uint(App::time * (going > 0.4f ? 8 : 4) + home.x) % 2;
        else if (animated)
        {
            entity.animate(going > 3.2f ? "run" : going > 0.4f ? "walk" : "idle");
            entity.animationSpeed = going > 3.2f ? going / 6 : going > 0.4f ? going / 2.4f : 1;
        }
    }
}

class Crowd
{
    array<Agent@> agents;
    uint next = 0;

    // Makes something one of them: a walker, if it isn't already.
    Agent@ add(Entity@ e, const string &in role)
    {
        if (!e.walker)
        {
            e.capsule(0.35f, 1.6f, 1);
            e.colliderAt = Vec3(0, 0.8f, 0);
            e.walker = true;
            e.mass = 60;
        }
        Agent a(e, role);
        agents.insertLast(a);
        return a;
    }

    void remove(Agent@ a)
    {
        int i = agents.findByRef(a);
        if (i >= 0)
            agents.removeAt(uint(i));
    }

    void clear() { agents.resize(0); }
    uint count() const { return agents.length(); }

    // A noise, heard by those near enough: 1 is a footstep's worth at their hearing.
    void noise(const Vec3 &in at, float loudness = 1)
    {
        for (uint i = 0; i < agents.length(); i++)
            agents[i].hear(at, loudness);
    }

    void update(float dt)
    {
        for (uint i = 0; i < agents.length();)
        {
            if (agents[i].entity is null || !agents[i].entity.alive)
            {
                agents.removeAt(i);
                continue;
            }
            i++;
        }
        for (uint i = 0; i < agents.length(); i++)
            agents[i].think(dt);
        // One way worked out a frame, taking turns.
        for (uint n = 0; n < agents.length(); n++)
        {
            next = (next + 1) % agents.length();
            if (agents[next].needsPath)
            {
                agents[next].findWay();
                break;
            }
        }
        for (uint i = 0; i < agents.length(); i++)
        {
            // Not in each other's way.
            Vec3 apart;
            Vec3 p = agents[i].entity.place;
            for (uint k = 0; k < agents.length(); k++)
            {
                if (k == i)
                    continue;
                Vec3 d = p - agents[k].entity.place;
                d.y = 0;
                float far = d.length();
                if (far < 1.4f && far > 0.001f)
                    apart = apart + d * ((1.4f - far) / far * 2.5f);
            }
            agents[i].move(dt, apart);
        }
    }

    // What each can see, as a fan on the ground, coloured by what it is doing; for working on a game. Where walls stop
    // each fan is worked out again for one of them a frame, which is enough to see by.
    uint drawn = 0;
    void draw(Canvas@ c, float alpha = 0.35f)
    {
        drawn++;
        float wide = c.width;
        for (uint i = 0; i < agents.length(); i++)
        {
            Agent@ a = agents[i];
            if (a.role == "wander" || a.role == "follow" || a.role == "still" || a.role == "chase")
                continue;
            Color color = a.state == "chasing" ? Color(1, 0.25f, 0.2f, alpha) : a.state == "searching" ? Color(1, 0.75f, 0.2f, alpha) : Color(1, 1, 0.6f, alpha * 0.6f);
            Vec3 at = a.entity.place + Vec3(0, 0.1f, 0);
            Vec3 f = a.entity.forward;
            float facing = atan2(f.x, f.z), half = a.fieldOfView * 0.5f * 0.0174533f;
            bool fresh = a.fan.length() != 13 || drawn % agents.length() == i;
            a.fan.resize(13);
            Vec2 from, last;
            if (!Space::toScreen(at, from))
                continue;
            bool had = false;
            for (int s = 0; s <= 12; s++)
            {
                float t = facing - half + half * 2 * float(s) / 12;
                if (fresh)
                {
                    // Only as far as it can see.
                    float reach = a.sight;
                    Vec3 hit, normal;
                    Vec3 eyes = at + Vec3(0, 1.4f, 0);
                    if (Space::raycast(eyes, eyes + Vec3(sin(t), 0, cos(t)) * a.sight, hit, normal, 0xFFFC, a.entity))
                        reach = (Vec3(hit.x, 0, hit.z) - Vec3(at.x, 0, at.z)).length();
                    a.fan[uint(s)] = Vec3(float(s), reach, 0);
                }
                Vec3 edge = at + Vec3(sin(t), 0, cos(t)) * a.fan[uint(s)].y;
                edge.y = Space::height(edge.x, edge.z) + 0.1f;
                Vec2 p;
                // Not behind the camera, nor so far off the screen that a line to it goes wrong.
                if (!Space::toScreen(edge, p) || abs(p.x) > wide * 3 || abs(p.y) > 2200)
                {
                    had = false;
                    continue;
                }
                if ((s == 0 || s == 12) && abs(from.x) < wide * 3 && abs(from.y) < 2200)
                    c.line(from.x, from.y, p.x, p.y, 2, color);
                if (had)
                    c.line(last.x, last.y, p.x, p.y, 2, color);
                last = p;
                had = true;
            }
            Vec2 head;
            if ((a.state == "chasing" || a.state == "searching") && Space::toScreen(a.entity.place + Vec3(0, 2.3f, 0), head))
                c.circle(head.x, head.y, 7, Color(color.r, color.g, color.b, 0.9f));
        }
    }
}
