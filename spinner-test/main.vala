using Gtk;

public class App : Adw.Application {

    public App () {
        Object (application_id: "example.app");
    }

    protected override void activate () {
        var window = new ApplicationWindow (this);
        window.set_default_size (300, 60);
        
        var spin_bounded = new Data.SpinButtonEntry.with_range(-100, 100, 1);
        spin_bounded.value = 0;
        spin_bounded.value_changed.connect(value_changed);
        
        var spin_unbounded = new Data.SpinButtonEntry();
        spin_unbounded.value_changed.connect(value_changed);
        
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        box.margin_start = box.margin_end = box.margin_top = box.margin_bottom = 10;
        box.append (spin_bounded);
        box.append (spin_unbounded);
        
        window.set_child (box);
        window.present ();
    }
    
    private void value_changed(double value) {
        message("===> %f", value);    
    }
    
    public static int main (string[] args) {
        return new App ().run (args);
    }
}
