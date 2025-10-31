public class AppShortcutsWindow : Object {
  private class ShortcutGroup {
      public string title;
      public Gee.ArrayList<ShortcutItem> items = new Gee.ArrayList<ShortcutItem>();
  }

  private class ShortcutItem {
      public string title;
      public string accel;
  }

  private Gtk.Window parent;
  private Gee.ArrayList<ShortcutGroup> groups = new Gee.ArrayList<ShortcutGroup>();
  private ShortcutGroup? current_group = null;
  public Gtk.ShortcutsWindow window { get; private set; }

  public AppShortcutsWindow(Gtk.Window parent) {
      this.parent = parent;
  }

  public AppShortcutsWindow new_group(string title) {
      var g = new ShortcutGroup();
      g.title = title;
      groups.add(g);
      current_group = g;
      return this;
  }

  public AppShortcutsWindow add(string title, string accel) {
      if (current_group == null)
          error("No active group — call new_group() first.");
      var i = new ShortcutItem();
      i.title = title;
      i.accel = accel
          .replace("&", "&amp;")
          .replace("<", "&lt;")
          .replace(">", "&gt;");
      current_group.items.add(i);
      return this;
  }
  
  public AppShortcutsWindow end_group() {
      current_group = null;
      return this;
  }

  public Gtk.ShortcutsWindow build() throws Error {
      var xml = build_xml();
      var builder = new Gtk.Builder();
      builder.add_from_string(xml, -1);

      window = builder.get_object("shortcuts_window") as Gtk.ShortcutsWindow;
      window.set_transient_for(parent);
      return window;
  }

  private string build_xml() {
      var sb = new StringBuilder();
      sb.append("<interface>\n");
      sb.append("  <object class=\"GtkShortcutsWindow\" id=\"shortcuts_window\">\n");
      sb.append("    <property name=\"modal\">true</property>\n");

      foreach (var g in groups) {
          sb.append("    <child>\n");
          sb.append("      <object class=\"GtkShortcutsSection\">\n");
          sb.append("        <property name=\"title\">" + g.title + "</property>\n");
          sb.append("        <child>\n");
          sb.append("          <object class=\"GtkShortcutsGroup\">\n");
          sb.append("            <property name=\"title\">" + g.title + "</property>\n");

          foreach (var i in g.items) {
              sb.append("            <child>\n");
              sb.append("              <object class=\"GtkShortcutsShortcut\">\n");
              sb.append("                <property name=\"title\">" + i.title + "</property>\n");
              sb.append("                <property name=\"accelerator\">" + i.accel + "</property>\n");
              sb.append("              </object>\n");
              sb.append("            </child>\n");
          }

          sb.append("          </object>\n");
          sb.append("        </child>\n");
          sb.append("      </object>\n");
          sb.append("    </child>\n");
      }

      sb.append("  </object>\n");
      sb.append("</interface>\n");
      return sb.str;
  }
  
  public void present() {
      if (window != null)
          window.present();
  }
}
