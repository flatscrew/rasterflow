namespace Data {

    public class TitleBar : Gtk.Widget {

        private Gtk.CenterBox action_bar;
        private Gtk.Label title_label;
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

            action_bar.get_style_context().add_class("rounded_top");
        }

        public TitleBar(string title) {
            this.left_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            left_box.margin_bottom = left_box.margin_top = left_box.margin_start = left_box.margin_end = 5;

            this.right_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
            right_box.margin_bottom = right_box.margin_top = right_box.margin_start = right_box.margin_end = 5;

            this.title_label = new Gtk.Label (title);

            action_bar.set_start_widget(this.left_box);
            action_bar.set_center_widget (this.title_label);
            action_bar.set_end_widget(this.right_box);
        }

        public void set_title(string title) {
            this.title_label.set_markup(title);
        }

        public void append_left(Gtk.Widget widget) {
            left_box.append(widget);
        }

        public void append_right(Gtk.Widget widget) {
            right_box.prepend(widget);
        }
    }
}