// Serves the drives of an original Xbox to FTP programs on the same network, for as long as this is open.

class TransferScreen : Screen
{
    Widget@ go;
    Widget@ write;
    Widget@ state;
    Widget@ last;
    Widget@ much;
    string password;

    void onEnter()
    {
        // A new one each time, as FTP sends it for anyone to see.
        for (int i = 0; i < 6; i++)
            password += formatInt(randomInt(0, 9));
        Widget@ page = Ui::root;
        page.padding = 44;
        page.gap = 16;
        page.label("Transfer", "title");
        Widget@ panel = page.panel();
        panel.grow = 1;
        say(panel, "Address").text = Net::address == "" ? "No network" : "ftp://" + Net::address;
        say(panel, "User").text = "xbox";
        say(panel, "Password").text = password;
        @state = say(panel, "State");
        @last = say(panel, "Latest");
        @much = say(panel, "Moved");
        panel.line();
        panel.paragraph("Only machines on this network are answered. Anyone on it could read what is sent, so stop it when you are done: it stops by itself when you leave.", "small");
        Widget@ row = page.row();
        @go = row.button("Start", WidgetEvent(this.onGo));
        go.grow = 1;
        @write = row.toggle("Let it change files", false);
        write.grow = 1;
        go.enabled = Xbox::available;
        write.enabled = Xbox::available;
    }

    void onExit() { Xbox::stopFtp(); }

    Widget@ say(Widget@ into, const string &in name)
    {
        Widget@ row = into.row();
        row.label(name, "small").width = 160;
        return row.label("");
    }

    void onGo(Widget@ w)
    {
        if (Xbox::ftpRunning)
            Xbox::stopFtp();
        else if (!Xbox::startFtp("xbox", password, write.checked))
            Ui::toast("It couldn't be started");
        go.text = Xbox::ftpRunning ? "Stop" : "Start";
        write.enabled = Xbox::available && !Xbox::ftpRunning;
    }

    void update(float dt)
    {
        state.text = !Xbox::available ? "There are drives to serve only on an original Xbox" : !Xbox::ftpRunning ? "Stopped" : formatInt(int(Xbox::ftpClients)) + " connected";
        last.text = Xbox::ftpLast;
        much.text = formatInt(int(Xbox::ftpKilobytes)) + " KB";
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        c.gradient(0, 0, c.width, 720, Color(0.05f, 0.09f, 0.16f), Color(0.02f, 0.03f, 0.06f));
        Ui::draw(c);
    }
}
