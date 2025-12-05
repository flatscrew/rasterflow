
using Gtk;
using Gsk;
using Graphene;

namespace Data {
    
    public class SpinButtonEntry : Gtk.Widget {
        public signal void value_changed(double value);
        
        private Gtk.Text entry;
        private Gtk.Button dec_button;
        private Gtk.Button inc_button;
        private Gtk.ProgressBar progress;
        
        private Gtk.ToggleButton scale_toggle_button;
        private Gtk.Scale scale;
        private bool scale_visible;
        
        private bool bounded = true;
        private double min;
        private double max;
        private double step;
        private double _value;
        
        private uint repeat_id = 0;
        
        public string text {
            get { return entry.text; }
            set { entry.text = value; }
        }
        
        public double value {
            get { return _value; }
            set {
                double v = value.clamp(min, max);
                if (_value == v)
                    return;
        
                _value = v;
                entry.text = "%.1f".printf(_value);
                
                if (_value == min || _value == max)
                    stop_repeat();
                
                update_buttons();
                update_progress();
                value_changed(_value);
            }
        }

        static construct {
            set_css_name("spinbutton");
            init_css();
        }
        
        private static Gtk.CssProvider css_provider;
        private static Gtk.Settings settings;

        private static void apply_theme_css() {
            bool dark = settings.gtk_application_prefer_dark_theme;

            if (dark) {
                message("dark");
                
                css_provider.load_from_string("""
                    .property-scale {
                        border-top: 1px solid rgba(255,255,255,0.1);
                    }
                """);
            } else {
                message("light");
                css_provider.load_from_string("""
                    .property-scale {
                        border-top: 1px solid rgba(0,0,0,0.1);
                    }
                """);
            }
        }

        private static void init_css() {
            css_provider = new Gtk.CssProvider();
            settings = Gtk.Settings.get_for_display(Gdk.Display.get_default());

            Gtk.StyleContext.add_provider_for_display(
                Gdk.Display.get_default(),
                css_provider,
                Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
            );

            apply_theme_css();

            settings.notify["gtk-application-prefer-dark-theme"].connect(() => {
                apply_theme_css();
            });
        }

        
        public SpinButtonEntry() {
            this.with_range(-double.MAX, double.MAX, 0.1);
        }

        public SpinButtonEntry.with_range(double min, double max, double step) {
            if (double.MAX == max || -double.MAX == min) {
                this.bounded = false;
            } else {
                this.bounded = true;
            }
            
            this.min = min;
            this.max = max;
            this.step = step;
            this._value = bounded ? min : 0.0;
    
            create_entry();
            create_decrement_button();
            create_increment_button();
            
            if (this.bounded) {
                scale_visible = false;
                create_scale_toggle_button();
                create_scale();
                create_progress_bar();
                scale.set_visible(scale_visible);
                progress.set_visible(!scale_visible);
            }
            
            update_buttons();
            update_progress();
            
            set_hexpand(true);
            
            var scroll = new EventControllerScroll(Gtk.EventControllerScrollFlags.VERTICAL);
            scroll.scroll.connect((dx, dy) => {
                if (dy < 0) {
                    increase_value();
                    return true;
                }
    
                if (dy > 0) {
                    decrease_value();
                    return true;
                }
    
                return false;
            });
            add_controller(scroll);
        }
        
        private void create_entry() {
            entry = new Gtk.Text();
            entry.text = "%.1f".printf(_value);
            entry.set_alignment(1.0f);
            entry.hexpand = true;
            entry.set_parent(this);
        
            entry.activate.connect(validate_entry);
        
            var focus_controller = new EventControllerFocus();
            focus_controller.leave.connect(validate_entry);
            entry.add_controller(focus_controller);
        
            var key = new EventControllerKey();
            key.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
            entry.add_controller(key);
        
            key.key_pressed.connect((keyval, keycode, state) => {
                if (keyval == Gdk.Key.Up) {
                    if (repeat_id > 0) return true;
                    repeat_id = Timeout.add(50, () => { increase_value(); return true; });
                    return true;
                }
        
                if (keyval == Gdk.Key.Down) {
                    if (repeat_id > 0) return true;
                    repeat_id = Timeout.add(50, () => { decrease_value(); return true; });
                    return true;
                }
        
                if (keyval == Gdk.Key.Page_Up) {
                    if (repeat_id > 0) return true;
                    repeat_id = Timeout.add(50, () => { increase_value(step * 10); return true; });
                    return true;
                }
        
                if (keyval == Gdk.Key.Page_Down) {
                    if (repeat_id > 0) return true;
                    repeat_id = Timeout.add(50, () => { decrease_value(step * 10); return true; });
                    return true;
                }
        
                return false;
            });
            key.key_released.connect(stop_repeat);
        }
        
        private void create_increment_button() {
            inc_button = new Button.from_icon_name("value-increase-symbolic");
            inc_button.set_focusable(false);
            inc_button.add_css_class("image-button");
            inc_button.add_css_class("down");
            inc_button.set_parent(this);
            
            var gesture = new GestureClick();
            gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
            inc_button.add_controller(gesture);
        
            gesture.pressed.connect(() => {
                if (repeat_id > 0) {
                    return;
                }
                repeat_id = Timeout.add(50, () => {
                    if (repeat_id == 0) {
                        return false;
                    }
                    increase_value();
                    return true;
                });
            });
            gesture.released.connect(stop_repeat);
        }
        
        private void create_decrement_button() {
            dec_button = new Button.from_icon_name("value-decrease-symbolic");
            dec_button.set_focusable(false);
            dec_button.add_css_class("image-button");
            dec_button.add_css_class("down");
            dec_button.set_parent(this);
            
            var gesture = new GestureClick();
            gesture.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
            dec_button.add_controller(gesture);
        
            gesture.pressed.connect(() => {
                if (repeat_id > 0) {
                    return;
                }
                repeat_id = Timeout.add(50, () => {
                    if (repeat_id == 0) {
                        return false;
                    }
                    decrease_value();
                    return true;
                });
            });
            gesture.released.connect(stop_repeat);
        }
        
        private void create_scale_toggle_button() {
            scale_toggle_button = new ToggleButton();
            scale_toggle_button.set_icon_name("content-loading-symbolic");
            scale_toggle_button.add_css_class("image-button");
            scale_toggle_button.add_css_class("down");
            scale_toggle_button.set_focusable(false);
            scale_toggle_button.set_parent(this);
            
            scale_toggle_button.toggled.connect(() => {
                scale_visible = scale_toggle_button.get_active();
                if (bounded) {
                    scale.set_visible(scale_visible);
                    progress.set_visible(!scale_visible);
                }
                queue_allocate();
            });
        }
        
        private void create_scale() {
            scale = new Gtk.Scale.with_range(Gtk.Orientation.HORIZONTAL, min, max, step);
            scale.add_css_class("property-scale");
            scale.set_parent(this);
            scale.value_changed.connect(() => {
                double raw = scale.get_value();
                double snapped = ((int) ((raw / step) + 0.5)) * step;
                scale.set_value(snapped);
                value = snapped;
            });
        }
        
        private void validate_entry() {
            double parsed;
        
            if (double.try_parse(entry.text, out parsed)) {
                parsed = parsed.clamp(min, max);
                if (parsed == _value) {
                    return;
                }
                
                value = parsed;
                
                Idle.add(() => {
                    entry.text = "%.1f".printf(value);
                    return false;
                });
            } else {
                entry.text = "%.1f".printf(_value);
            }
        }
        
        private void create_progress_bar() {
            progress = new Gtk.ProgressBar();
            progress.set_parent(this);
            progress.set_fraction(0.5); 
            progress.set_valign(Gtk.Align.END);
            progress.add_css_class("osd");
            progress.set_can_target(false);
            
            if (!bounded) {
                progress.hide();
            }
        }
        
        private void stop_repeat() {
            if (repeat_id > 0) {
                Source.remove(repeat_id);
                repeat_id = 0;
            }
        }
        
        private void increase_value(double increase_step = step) {
            value = _value + increase_step;
        }
        
        private void decrease_value(double decrease_step = step) {
            value = _value - decrease_step;
        }
        
        private void update_buttons() {
            dec_button.set_sensitive(_value > min);
            inc_button.set_sensitive(_value < max);
        }
        
        private void update_progress() {
            if (!bounded) return;
            
            progress.set_fraction((_value - min) / (max - min));
            scale.set_value(_value);
        }
    
        public override void measure(Gtk.Orientation orientation,
            int for_size,
            out int minimum,
            out int natural,
            out int min_baseline,
            out int nat_baseline)
        {
            int min_entry, nat_entry, base_min_entry, base_nat_entry;
            int min_toggle, nat_toggle, base_min_toggle, base_nat_toggle;
            int min_decrease, nat_decrease, base_min_decrease, base_nat_decrease;
            int min_increase, nat_increase, base_min_increase, base_nat_increase;
            int min_scale, nat_scale, base_min_scale, base_nat_scale;

            bool show_scale = bounded && scale_visible;

            entry.measure(
                orientation, for_size,
                out min_entry, out nat_entry,
                out base_min_entry, out base_nat_entry
            );

            dec_button.measure(orientation, for_size,
                out min_decrease, out nat_decrease,
                out base_min_decrease, out base_nat_decrease);

            inc_button.measure(orientation, for_size,
                out min_increase, out nat_increase,
                out base_min_increase, out base_nat_increase);

            if (bounded) {
                scale_toggle_button.measure(
                    orientation, for_size,
                    out min_toggle, out nat_toggle,
                    out base_min_toggle, out base_nat_toggle
                );

                if (show_scale) {
                    scale.measure(Gtk.Orientation.VERTICAL, for_size,
                        out min_scale, out nat_scale,
                        out base_min_scale, out base_nat_scale);
                } else {
                    min_scale = 0;
                    nat_scale = 0;
                }
            } else {
                min_toggle = 0;
                nat_toggle = 0;
                min_scale = 0;
                nat_scale = 0;
            }
                
            if (orientation == Orientation.HORIZONTAL) {
                minimum = min_entry + min_toggle + min_decrease + min_increase;
                natural = nat_entry + nat_toggle + nat_decrease + nat_increase;
            } else {
                minimum = int.max(min_entry,
                    int.max(min_toggle,
                    int.max(min_decrease, min_increase)))
                    + min_scale;
         
                natural = int.max(nat_entry,
                    int.max(nat_toggle,
                    int.max(nat_decrease, nat_increase)))
                    + nat_scale;
                    
                if (show_scale) {
                    minimum += 4;
                    natural += 4;
                }
            }

            min_baseline = -1;
            nat_baseline = -1;
        }
    
        public override void size_allocate(int width,
            int height,
            int baseline)
        {
            int min_t, nat_t, bt1, bt2;
            int min_d, nat_d, b1, b2;
            int min_i, nat_i, b3, b4;
            int min_s, nat_s, bs1, bs2;
            
            bool show_scale = bounded && scale_visible;
            bool show_progress = bounded && !scale_visible;
            
            dec_button.measure(Gtk.Orientation.HORIZONTAL, -1,
                out min_d, out nat_d, out b1, out b2);
                
            inc_button.measure(Gtk.Orientation.HORIZONTAL, -1,
                out min_i, out nat_i, out b3, out b4);
            
            if (bounded) {
                scale_toggle_button.measure(Gtk.Orientation.HORIZONTAL, -1,
                    out min_t, out nat_t, out bt1, out bt2);

                if (show_scale) {
                    scale.measure(Gtk.Orientation.VERTICAL, -1,
                        out min_s, out nat_s, out bs1, out bs2);
                } else {
                    nat_s = 0;
                }
            } else {
                nat_t = 0;
                nat_s = 0;
            }
            
            int toggle_w = nat_t;
            int dec_w = nat_d;
            int inc_w = nat_i;
            
            int progress_h = show_progress ? 3 : 0;
            int h_margin = 5;
            int v_margin = 3;

            int entry_w = width - toggle_w - dec_w - inc_w;
            if (entry_w < 0) entry_w = 0;

            int scale_h = show_scale ? nat_s : 0;
            int entry_h = height - scale_h;
            
            entry.allocate(entry_w, entry_h, baseline, null);

            var t_dec = new Transform();
            t_dec = t_dec.translate(Point() { x = entry_w + toggle_w, y = 0 });
            dec_button.allocate(dec_w, entry_h, baseline, t_dec);

            var t_inc = new Transform();
            t_inc = t_inc.translate(Point() { x = entry_w + toggle_w + dec_w, y = 0 });
            inc_button.allocate(inc_w, entry_h, baseline, t_inc);

            if (!bounded) return;

            if (show_progress) {
                var t_prog = new Transform();
                t_prog = t_prog.translate(Point() { x = h_margin, y = entry_h - v_margin - progress_h });
                progress.allocate(entry_w - h_margin * 2, progress_h, baseline, t_prog);
            }

            var t_toggle = new Transform();
            t_toggle = t_toggle.translate(Point() { x = entry_w, y = 0 });
            scale_toggle_button.allocate(toggle_w, entry_h, baseline, t_toggle);
            
            if (show_scale) {
                var t_scale = new Transform();
                t_scale = t_scale.translate(Point() { x = 0, y = entry_h });
                scale.allocate(width, scale_h, baseline, t_scale);
            }
        }

        ~SpinButtonEntry() {
            entry.unparent();
            dec_button.unparent();
            inc_button.unparent();
            
            if (!bounded) return;
            
            scale_toggle_button.unparent();
            scale.unparent();
            progress.unparent();
        }
    }
}
