public class CanvasHeaderbarWidgets {

    private Gtk.Widget[] widgets = {};

    public void add_widget(Gtk.Widget widget) {
        this.widgets += widget;
    }

    public Gtk.Widget[] get_widgets() {
        return widgets;
    }
}