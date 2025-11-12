// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

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
