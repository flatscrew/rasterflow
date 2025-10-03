//  namespace Image {

//      public class LangMap {
//          public static Gee.Map<string,string> languages {
//              get;
//              private set;
//          }
//          private static bool initialized;

//          public static void initialize() {
//              if (LangMap.initialized) {
//                  return;
//              }
//              LangMap.languages = new Gee.HashMap<string, string>();
//              LangMap.read_from_resource("/data/iso_639-2.csv");
//          }

//          private static string read_from_resource(string resource_path) {
//              string content = null;
//              try {
//                  var stream = GLib.resources_open_stream(resource_path, GLib.ResourceLookupFlags.NONE);
//                  var data_stream = new GLib.DataInputStream(stream);

//                  string line;
//                  while ((line = data_stream.read_line(null)) != null) {
//                      var parts = line.split(";", 2);
//                      if (parts.length == 2) {
//                          string code = parts[0].strip();
//                          string name = parts[1].strip();
//                          languages.set(code, name);
//                      }
//                  }
//                  size_t length;
//                  content = data_stream.read_upto("", -1, out length);
//              } catch (Error e) {
//                  stderr.printf("Error reading resource: %s\n", e.message);
//              }
        
//              return content;
//          }
//      }

//      public class ImageOCRNodeBuilder : CanvasDisplayNodeBuilder, Object {

//          public CanvasDisplayNode create() throws Error{
//              return new ImageOCRNodeView(new ImageOCRNode());
//          }

//          public string name() {
//              return "OCR image";
//          }
//      }

//      public class ImageOCRNode : CanvasNode {
        
//          private Gdk.Pixbuf? pixbuf;
//          private GFlow.SimpleSource text;
//          private GFlow.SimpleSink input_data_sink;
//          internal string? lang;

//          construct {
//              LangMap.initialize();
//          }

//          public ImageOCRNode() {
//              base("OCR image");
//              resizable = false;

//              input_data_sink = new_sink_with_type ("Input image data", typeof(Gdk.Pixbuf));
//              input_data_sink.changed.connect(value => {
//                  this.pixbuf = value as Gdk.Pixbuf;
//                  print("recognizing text in language: %s\n", lang);
//                  var recocnized_text = TesseractWrapper.recognize_text(pixbuf, lang);
//                  try {
//                      text.set_value(recocnized_text);
//                  } catch (Error e) {
//                      error(e.message);
//                  }
//              });
//              text = new_source_with_type("Recognized text", typeof(string));
//          }
//      }

//      class ImageOCRNodeView : CanvasDisplayNode {

//          private Gtk.ComboBox combobox;

//          public ImageOCRNodeView(ImageOCRNode node) {
//              base(node);

//              var grid = new Gtk.Grid();
//              grid.row_spacing = grid.column_spacing = 5;
//              grid.valign = grid.halign = Gtk.Align.CENTER;
//              grid.margin_start = grid.margin_end = grid.margin_top = grid.margin_bottom = 10;
//              grid.attach(new Gtk.Label("Language:"), 0, 0, 1, 1);
            
//              var liststore = new Gtk.ListStore(2, typeof(string), typeof(string));
//              Gtk.TreeIter iter;
            
//              var lang_codes = TesseractWrapper.get_available_languages();
//              foreach (var lang in lang_codes) {
//                  var lang_name = LangMap.languages.get(lang);
//                  if (lang_name == null) {
//                      continue;
//                  }
//                  if (node.lang == null) {
//                      node.lang = lang;
//                  }
//                  liststore.append(out iter);
//                  liststore.set(iter, 0, lang, 1, LangMap.languages.get(lang));
//              }

//              this.combobox = new Gtk.ComboBox.with_model(liststore);
//              var renderer = new Gtk.CellRendererText ();
//              combobox.pack_start (renderer, true);
//              combobox.add_attribute (renderer, "text", 1);
//              combobox.active = 0;
//              combobox.changed.connect(() => {
//                  Value value;
//                  Gtk.TreeIter readiter;
//                  combobox.get_active_iter(out readiter);
//                  combobox.get_model().get_value(readiter, 0, out value);
                
//                  string language_code = value.get_string();
//                  var ocr_node = n as ImageOCRNode;
//                  ocr_node.lang = language_code;
//              });
//              grid.attach(combobox, 1, 0, 1, 1);

//              add_child(grid);
//          }

//      }
//  }