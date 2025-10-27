namespace Data {

    public class TitleBar : Gtk.Widget {

        private Gtk.CenterBox action_bar;
        private Gtk.Widget title_widget;
        private Gtk.Box left_box;
        private Gtk.Box right_box;

        ~TitleBar() {
            this.action_bar.unparent();
        }

        construct {
            set_layout_manager(new Gtk.BinLayout());

            this.action_bar = new Gtk.CenterBox();
            action_bar.set_parent(this);   
            action_bar.hexpand = true;
        }

        public TitleBar(Gtk.Widget title_widget) {
            this.left_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            left_box.margin_bottom = left_box.margin_top = left_box.margin_start = left_box.margin_end = 5;

            this.right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            right_box.margin_bottom = right_box.margin_top = right_box.margin_start = right_box.margin_end = 5;

            this.title_widget = title_widget;

            action_bar.set_start_widget(this.left_box);
            action_bar.set_center_widget (this.title_widget);
            action_bar.set_end_widget(this.right_box);
        }

        public void append_left(Gtk.Widget widget) {
            left_box.append(widget);
        }

        public void append_right(Gtk.Widget widget) {
            right_box.prepend(widget);
        }
    }
}