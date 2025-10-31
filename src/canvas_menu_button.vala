using Gtk;
using GLib;

public class AppMenu : Object {
    public signal void about_selected();
    public signal void shortcuts_selected();

    public MenuButton button { get; private set; }
    private SimpleActionGroup actions;

    public AppMenu() {
        button = new MenuButton() { icon_name = "open-menu-symbolic" };

        var model = new Menu();
        model.append("About", "menu.about");
        model.append("Keyboard Shortcuts", "menu.shortcuts");
        button.set_menu_model(model);

        actions = new SimpleActionGroup();

        var about = new SimpleAction("about", null);
        about.activate.connect(() => {
            about_selected();
        });
        actions.add_action(about);

        var shortcuts = new SimpleAction("shortcuts", null);
        shortcuts.activate.connect(() => {
            shortcuts_selected();
        });
        actions.add_action(shortcuts);

        button.insert_action_group("menu", actions);
    }
}
