// The page is in form.json and what it says in a file for each language. Only what it does is here.

class FormScreen : Screen
{
    array<string> languages = { "asset:english.json", "asset:francais.json", "asset:deutsch.json" };

    void onEnter()
    {
        Ui::words(languages[0]);
        Ui::load("asset:form.json");
        Ui::find("name").focus();
    }

    void onLanguage(Widget@ w) { Ui::words(languages[uint(w.chosen)]); }

    void onCheck(Widget@ w)
    {
        // The button can be pressed once there is a name.
        Ui::find("send").enabled = Ui::find("name").text.length() > 1;
        Ui::find("missing").visible = !Ui::find("send").enabled;
    }

    void onPets(Widget@ w) { Ui::find("pets").text = formatInt(int(w.value)); }

    void onSend(Widget@ w)
    {
        Ui::dialog("@thanks", Ui::find("name").text + ", " + Ui::find("drink").chosenText, array<string> = { "@fine" });
    }

    void onClear(Widget@ w)
    {
        Ui::find("name").text = "";
        onCheck(w);
        Ui::toast("@cleared");
    }

    void draw(Canvas@ c)
    {
        c.designHeight(720);
        c.gradient(0, 0, c.width, 720, Color(0.06f, 0.12f, 0.13f), Color(0.03f, 0.05f, 0.07f));
        Ui::draw(c);
    }
}
