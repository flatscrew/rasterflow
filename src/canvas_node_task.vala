public class CanvasNodeTask : Object {
    private Gtk.ProgressBar bar;
    private bool finished = false;

    internal CanvasNodeTask(Gtk.ProgressBar bar) {
        this.bar = bar;
    }

    public void set_progress(double fraction) {
        if (finished) return;
    
        message("updating progress: %f", fraction);
        bar.set_fraction(fraction.clamp(0.0, 1.0));
    }

    public void pulse() {
        if (finished) return;
        bar.pulse();
    }

    public void finish() {
        if (finished) return;
        finished = true;
        bar.set_fraction(0);
    }

    public void fail() {
        if (finished) return;
        finished = true;
        bar.add_css_class("error");
    }
}