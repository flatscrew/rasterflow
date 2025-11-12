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

public class TimeSorter : Gtk.Sorter {

    public override Gtk.Ordering compare(GLib.Object? item1, GLib.Object? item2) {
        var entry1 = item1 as LogEntry;
        var entry2 = item2 as LogEntry;
        return Gtk.Ordering.from_cmpfunc(entry2.time.compare(entry1.time));
    }
}

public class CanvasLogsWindow : Adw.ApplicationWindow {
    private CanvasLog log;
    private Gtk.ColumnView list_view;
    private Gtk.SortListModel sorted_model;
    private Gtk.SingleSelection selection;

    public CanvasLogsWindow() {
        Object(title: "Logs");
        set_default_size(700, 400);

        log = CanvasLog.get_log();

        var headerbar = new Adw.HeaderBar();
        headerbar.set_title_widget(new Gtk.Label("Logs"));

        var clear_button = new Gtk.Button.from_icon_name("user-trash-symbolic");
        clear_button.set_tooltip_text("Clear all logs");
        clear_button.clicked.connect(log.clear);
        headerbar.pack_start(clear_button);
        
        var sorter = new TimeSorter();
        this.sorted_model = new Gtk.SortListModel(log.get_model(), sorter);
        this.selection = new Gtk.SingleSelection(sorted_model);

        list_view = new Gtk.ColumnView(selection);
        list_view.hexpand = list_view.vexpand = true;
        list_view.append_column(time_column());
        list_view.append_column(severity_column());
        list_view.append_column(message_column());
        list_view.set_model(selection);

        var scrolled = new Gtk.ScrolledWindow();
        scrolled.set_child(list_view);

        var toolbar_view = new Adw.ToolbarView();
        toolbar_view.add_top_bar(headerbar);
        toolbar_view.set_content(scrolled);
        set_content(toolbar_view);
    }

    private Gtk.ColumnViewColumn time_column() {
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((o) => (o as Gtk.ListItem).set_child(new Gtk.Label("")));
        factory.bind.connect((o) => {
            var li = o as Gtk.ListItem;
            var e = li.get_item() as LogEntry;
            (li.get_child() as Gtk.Label).set_label(e.time.format_iso8601());
        });
        return new Gtk.ColumnViewColumn("Time", factory);
    }

    private Gtk.ColumnViewColumn severity_column() {
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((o) => {
            var li = o as Gtk.ListItem;
            var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            box.append(new Gtk.Image());
            box.append(new Gtk.Label(""));
            li.set_child(box);
        });
        factory.bind.connect((o) => {
            var li = o as Gtk.ListItem;
            var e = li.get_item() as LogEntry;
            var box = li.get_child() as Gtk.Box;
            var icon = box.get_first_child() as Gtk.Image;
            var label = icon.get_next_sibling() as Gtk.Label;
            switch (e.severity) {
            case LogSeverity.ERROR:
                icon.set_from_icon_name("dialog-error-symbolic");
                label.set_label("Error");
                break;
            case LogSeverity.WARNING:
                icon.set_from_icon_name("dialog-warning-symbolic");
                label.set_label("Warning");
                break;
            case LogSeverity.INFO:
                icon.set_from_icon_name("dialog-information-symbolic");
                label.set_label("Info");
                break;
            }
        });
        return new Gtk.ColumnViewColumn("Severity", factory);
    }

    private Gtk.ColumnViewColumn message_column() {
        var factory = new Gtk.SignalListItemFactory();
        factory.setup.connect((o) => {
            var li = o as Gtk.ListItem;
            var label = new Gtk.Label("");
            label.halign = Gtk.Align.START;
            label.wrap = true;
            label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            li.set_child(label);
        });
        factory.bind.connect((o) => {
            var li = o as Gtk.ListItem;
            var e = li.get_item() as LogEntry;
            (li.get_child() as Gtk.Label).set_label(e.message);
        });
        var col = new Gtk.ColumnViewColumn("Message", factory);
        col.expand = true;
        return col;
    }
}

