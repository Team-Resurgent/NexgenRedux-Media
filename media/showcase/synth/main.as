// Sound a script makes: an arpeggio written into an AudioStream as it plays, a laser made sample by sample, and the
// effects a bus can put them through.

class Switch
{
    string name;
    bool on;
}

class SynthScreen : Screen
{
    Font@ font = Assets::font("global:freesans.sfn", 22);
    Font@ big = Assets::font("global:freesans.sfn", 34);
    AudioStream@ stream = AudioStream(48000, 1, 0.1f);
    Samples@ laser;
    array<Switch@> effects;
    uint chosen = 0;
    uint shape = 0;             // sine, square, saw
    array<string> shapes = { "Sine", "Square", "Saw" };
    array<float> notes = { 220, 261.63f, 329.63f, 392, 440, 392, 329.63f, 261.63f };
    uint note = 0;
    uint noteLeft = 0;          // frames left of the note playing
    float phase = 0;
    array<float> chunk;

    void onEnter()
    {
        array<string> names = { "Distortion", "Chorus", "Flanger", "Compressor", "Equaliser", "Band-pass", "Echo", "Reverb" };
        for (uint i = 0; i < names.length(); i++)
        {
            Switch e;
            e.name = names[i];
            e.on = false;
            effects.insertLast(e);
        }
        // A laser: a sine that falls in pitch and fades, made one sample at a time.
        @laser = Samples(12000, 48000, 1);
        float p = 0;
        for (uint i = 0; i < laser.frames; i++)
        {
            float t = float(i) / 12000;
            p += (1800 - 1500 * t) * 6.2831853f / 48000;
            laser.set(i, sin(p) * (1 - t) * 0.6f);
        }
        stream.play(0.7f);
    }

    // As much of the arpeggio as there is room for: an eighth of a second a note, each one fading.
    void fill()
    {
        uint room = stream.room;
        if (room == 0) return;
        chunk.resize(room);
        for (uint i = 0; i < room; i++)
        {
            if (noteLeft == 0)
            {
                note = (note + 1) % notes.length();
                noteLeft = 6000;
            }
            float t = 1 - float(noteLeft) / 6000;
            phase += notes[note] / 48000;
            phase -= floor(phase);
            float v = shape == 0 ? sin(phase * 6.2831853f) : shape == 1 ? (phase < 0.5f ? 0.6f : -0.6f) : (phase * 2 - 1) * 0.7f;
            chunk[i] = v * 0.5f * (1 - t) * (1 - t);
            noteLeft--;
        }
        stream.write(chunk);
    }

    void apply()
    {
        Audio::distortion(BusEffects, effects[0].on ? 0.7f : 0, 0.1f);
        Audio::chorus(BusEffects, effects[1].on ? 0.8f : 0, 1.5f, 0.1f);
        Audio::flanger(BusEffects, effects[2].on ? 0.8f : 0, 0.25f, 0.6f, 0.1f);
        Audio::compressor(BusEffects, effects[3].on ? -24 : 0, 8);
        if (effects[4].on) Audio::equalizer(BusEffects, 9, -6, 6, 0.2f);
        else Audio::equalizer(BusEffects, 0, 0, 0, 0.2f);
        if (effects[5].on) Audio::bandPass(BusEffects, 900, 1, 0.2f);
        else { Audio::lowPass(BusEffects, 20000, 0.2f); Audio::highPass(BusEffects, 0, 0.2f); }
        Audio::echo(BusEffects, effects[6].on ? 0.5f : 0, 0.25f, 0.4f, 0.1f);
        Audio::reverb(BusEffects, effects[7].on ? 0.6f : 0, 0.8f, 0.1f);
    }

    void update(float dt)
    {
        fill();
        if (Input::repeated("down")) chosen = (chosen + 1) % effects.length();
        if (Input::repeated("up")) chosen = (chosen + effects.length() - 1) % effects.length();
        if (Input::pressed("accept"))
        {
            effects[chosen].on = !effects[chosen].on;
            apply();
        }
        if (Input::pressed("alternate")) shape = (shape + 1) % shapes.length();
        if (Input::pressed("fire")) laser.play(0.8f, random(-0.5f, 0.5f), random(0.8f, 1.2f));
        if (Input::pressed("cancel")) Screens::pop();
    }

    void draw(Canvas@ c)
    {
        c.design(1280, 720);
        c.gradient(0, 0, 1280, 720, Color(0.08f, 0.07f, 0.14f), Color(0.03f, 0.03f, 0.06f));
        c.text(big, "Synth", 60, 40, White);
        c.text(font, "A " + shapes[shape] + " arpeggio, written as it plays", 60, 90, Gray);

        // What is heard, as a wave and as bands.
        array<Vec2> wave;
        for (uint i = 0; i < 256; i++)
            wave.insertLast(Vec2(60 + float(i) * 3, 300 + Audio::wave(i * 2) * 120));
        c.polyline(wave, 3, Color(0.4f, 0.9f, 0.8f));
        for (uint i = 0; i < 32; i++)
        {
            float h = Audio::spectrum(i) * 160;
            c.rect(60 + float(i) * 24, 620 - h, 18, h, hsv(0.5f + float(i) / 64, 0.6f, 0.9f));
        }

        // The effects, on and off.
        for (uint i = 0; i < effects.length(); i++)
        {
            float y = 150 + float(i) * 54;
            bool here = i == chosen;
            c.roundRect(900, y, 320, 44, 10, here ? Color(0.25f, 0.3f, 0.5f) : Color(0.14f, 0.15f, 0.24f));
            c.text(font, effects[i].name, 920, y + 10, here ? White : Color(0.75f, 0.78f, 0.88f));
            c.roundRect(1150, y + 10, 50, 24, 12, effects[i].on ? Color(0.3f, 0.8f, 0.5f) : Color(0.3f, 0.32f, 0.4f));
            c.circle(effects[i].on ? 1188 : 1162, y + 22, 9, White);
        }
        c.text(font, "Up, down: choose    Accept: on or off    Alternate: shape    Fire: laser", 640, 676, Yellow, AlignCenter);
    }
}
