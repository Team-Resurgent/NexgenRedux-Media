// Animation states, as a graph: #include "global:states.as"
//
// Each state plays one of a model's animations, looping or not; one that doesn't loop may say what comes after it
// finishes. Links between states say how long the change takes, and whether to wait for the first to finish.
// travel(state) goes there the shortest way along links, playing each state between in turn: asked for "jump" while
// running, it can go run -> leap -> jump without the game asking for the leap. jump(state) goes straight there.
//
//     AnimationStates moves(robot);
//     moves.add("idle");
//     moves.add("walk");
//     moves.add("wave", "wave", false, "idle");          // waves once, then idles
//     moves.link("idle", "walk", 0.2f, true);            // and back
//     moves.link("idle", "wave");
//     moves.start("idle");
//     ...each update: moves.update(dt);  and  moves.travel(speed > 0.1f ? "walk" : "idle");

class AnimationState
{
    string name;
    string animation;
    bool loop = true;
    string next;       // after it finishes, if it doesn't loop
}

class AnimationLink
{
    string from;
    string to;
    float change = 0.25f;    // seconds
    bool atEnd = false;      // only once the first has finished
}

funcdef void AnimationEntered(const string &in state);

class AnimationStates
{
    Entity@ entity;
    array<AnimationState@> states;
    array<AnimationLink@> links;
    string state;              // where it is
    array<string> route;       // where it is going, after this
    AnimationEntered@ entered; // told of each state it comes to
    private float change = 0.25f;
    private bool started = false;   // its animation has begun: asking again for one that has finished would start it again

    AnimationStates(Entity@ entity)
    {
        @this.entity = entity;
    }

    // A state; its animation is of the same name unless told.
    void add(const string &in name, const string &in animation = "", bool loop = true, const string &in next = "")
    {
        AnimationState s;
        s.name = name;
        s.animation = animation.isEmpty() ? name : animation;
        s.loop = loop;
        s.next = next;
        states.insertLast(s);
    }

    // A way from one state to another, and back too if both.
    void link(const string &in from, const string &in to, float change = 0.25f, bool both = false, bool atEnd = false)
    {
        AnimationLink l;
        l.from = from;
        l.to = to;
        l.change = change;
        l.atEnd = atEnd;
        links.insertLast(l);
        if (both)
            link(to, from, change, false, atEnd);
    }

    AnimationState@ find(const string &in name)
    {
        for (uint i = 0; i < states.length(); i++)
            if (states[i].name == name)
                return states[i];
        return null;
    }

    AnimationLink@ linkOf(const string &in from, const string &in to)
    {
        for (uint i = 0; i < links.length(); i++)
            if (links[i].from == from && links[i].to == to)
                return links[i];
        return null;
    }

    // Straight there, changing over so many seconds.
    void jump(const string &in name, float seconds = 0.25f)
    {
        if (find(name) is null)
            return;
        route.resize(0);
        enter(name, seconds);
    }

    void start(const string &in name) { jump(name, 0); }

    // There by the shortest way along links. False if there is none; asking again for where it is going does nothing.
    bool travel(const string &in name)
    {
        if (state.isEmpty())
        {
            jump(name, 0);
            return find(name) !is null;
        }
        if ((route.length() > 0 && route[route.length() - 1] == name) || (route.length() == 0 && state == name))
            return true;
        // Breadth first: each state reached is reached the shortest way.
        array<string> seen = { state };
        array<int> from = { -1 };
        for (uint at = 0; at < seen.length(); at++)
        {
            for (uint i = 0; i < links.length(); i++)
            {
                if (links[i].from != seen[at] || seen.find(links[i].to) >= 0)
                    continue;
                seen.insertLast(links[i].to);
                from.insertLast(int(at));
                if (links[i].to == name)
                {
                    route.resize(0);
                    for (int k = int(seen.length()) - 1; k > 0; k = from[k])
                        route.insertAt(0, seen[k]);
                    return true;
                }
            }
        }
        return false;
    }

    // Whether it has stopped: in a state that doesn't loop, finished, with nowhere to go.
    bool get_finished() const property
    {
        return route.length() == 0 && started && entity.animated;
    }

    void update(float dt)
    {
        if (state.isEmpty())
            return;
        AnimationState@ now = find(state);
        // Until the model has arrived, it is asked again.
        if (!started)
            started = entity.animate(now.animation, now.loop, change);
        bool done = started && !now.loop && entity.animated;
        if (route.length() > 0)
        {
            AnimationLink@ l = linkOf(state, route[0]);
            if (l is null || !l.atEnd || done)
            {
                string to = route[0];
                route.removeAt(0);
                enter(to, l is null ? 0.25f : l.change);
            }
        }
        else if (done && !now.next.isEmpty())
        {
            AnimationLink@ l = linkOf(state, now.next);
            enter(now.next, l is null ? 0.25f : l.change);
        }
    }

    private void enter(const string &in name, float seconds)
    {
        AnimationState@ s = find(name);
        if (s is null)
            return;
        state = name;
        change = seconds;
        started = entity.animate(s.animation, s.loop, seconds);
        if (entered !is null)
            entered(name);
    }
}
