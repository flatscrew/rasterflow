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

public class AppShortcutsWindowInstance : Object {
    
    private string xml;
    
    public AppShortcutsWindowInstance(string xml) {
        this.xml = xml;
    }
    
    public Gtk.ShortcutsWindow use_with(Gtk.Window parent) {
        var builder = new Gtk.Builder();
        builder.add_from_string(xml, -1);
        var window = builder.get_object("shortcuts_window") as Gtk.ShortcutsWindow;
        window.set_transient_for(parent);
        return window;
    }
}

public class AppShortcutsWindowBuilder : Object {
    private Gtk.Window parent;
    private Gee.ArrayList<Section> sections = new Gee.ArrayList<Section>();

    public AppShortcutsWindowBuilder(Gtk.Window parent) {
        this.parent = parent;
    }

    public Section new_section(string title) {
        var section = new Section(this, title);
        sections.add(section);
        return section;
    }

    public AppShortcutsWindowInstance build() throws Error {
        return new AppShortcutsWindowInstance(to_xml());
    }
    
    private string to_xml() {
        var sb = new StringBuilder();
        sb.append("<interface>\n");
        sb.append("  <object class=\"GtkShortcutsWindow\" id=\"shortcuts_window\">\n");
        sb.append("    <property name=\"modal\">true</property>\n");
        foreach (var section in sections)
            sb.append(section.to_xml(4));
        sb.append("  </object>\n");
        sb.append("</interface>\n");
        return sb.str;
    }

    private static string pad(int n) {
        var sb = new StringBuilder();
        for (int i = 0; i < n; i++)
            sb.append(" ");
        return sb.str;
    }

    public class Section {
        private AppShortcutsWindowBuilder owner;
        public string title;
        private Gee.ArrayList<Group> groups = new Gee.ArrayList<Group>();

        public Section(AppShortcutsWindowBuilder owner, string title) {
            this.owner = owner;
            this.title = title;
        }

        public Group new_group(string title) {
            var group = new Group(this, title);
            groups.add(group);
            return group;
        }

        public AppShortcutsWindowBuilder end_section() {
            return owner;
        }

        public string to_xml(int indent = 0) {
            var p = pad(indent);
            var sb = new StringBuilder();
            sb.append(p + "<child>\n");
            sb.append(p + "  <object class=\"GtkShortcutsSection\">\n");
            sb.append(p + "    <property name=\"title\">" + title + "</property>\n");
            foreach (var g in groups)
                sb.append(g.to_xml(indent + 4));
            sb.append(p + "  </object>\n");
            sb.append(p + "</child>\n");
            return sb.str;
        }
    }

    public class Group {
        private Section owner;
        public string title;
        private Gee.ArrayList<Shortcut> shortcuts = new Gee.ArrayList<Shortcut>();

        public Group(Section owner, string title) {
            this.owner = owner;
            this.title = title;
        }

        public Group add(string title, string accel) {
            shortcuts.add(new Shortcut(title, accel));
            return this;
        }

        public Section end_group() {
            return owner;
        }

        public string to_xml(int indent = 0) {
            var p = pad(indent);
            var sb = new StringBuilder();
            sb.append(p + "<child>\n");
            sb.append(p + "  <object class=\"GtkShortcutsGroup\">\n");
            sb.append(p + "    <property name=\"title\">" + title + "</property>\n");
            foreach (var s in shortcuts)
                sb.append(s.to_xml(indent + 4));
            sb.append(p + "  </object>\n");
            sb.append(p + "</child>\n");
            return sb.str;
        }
    }

    public class Shortcut {
        public string title;
        public string accel;

        public Shortcut(string title, string accel) {
            this.title = title;
            this.accel = accel
                .replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;");
        }

        public string to_xml(int indent = 0) {
            var p = pad(indent);
            var sb = new StringBuilder();
            sb.append(p + "<child>\n");
            sb.append(p + "  <object class=\"GtkShortcutsShortcut\">\n");
            sb.append(p + "    <property name=\"title\">" + title + "</property>\n");
            sb.append(p + "    <property name=\"accelerator\">" + accel + "</property>\n");
            sb.append(p + "  </object>\n");
            sb.append(p + "</child>\n");
            return sb.str;
        }
    }
}
