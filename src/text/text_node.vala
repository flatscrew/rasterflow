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

namespace Text {

    public class TextDataDisplayNodeBuilder : CanvasNodeBuilder, Object {

        public CanvasDisplayNode create(int x, int y) throws Error{
            return new TextDataDisplayNode(id(), new TextDataNode());
        }

        public string name() {
            return "Display text";
        }
        
        public string id() {
            return "text:display";
        } 
    }

    class TextDataDisplayNode : CanvasDisplayNode {

        private Data.DataDisplayView data_display_view;
        private Gtk.Label text_label;

        public TextDataDisplayNode(string builder_id, TextDataNode data_node) {
            base (builder_id, data_node, 0, 0, new GtkFlow.NodeDockLabelWidgetFactory(data_node));
            this.data_display_view = new Data.DataDisplayView();
            add_child(data_display_view);

            var scrolling_window = new Gtk.ScrolledWindow();
            this.text_label = new Gtk.Label("");
            this.text_label.hexpand = this.text_label.vexpand = true;
            this.text_label.wrap = true;
            scrolling_window.set_child(text_label);
            data_display_view.add_child(scrolling_window);

            data_node.input_sink.changed.connect(value => {
                var text = value.get_string();
                text_label.set_markup(text);
            });
        }
    }

    class TextDataNode : CanvasNode {

        internal GFlow.Sink input_sink;

        public TextDataNode() {
            base("Text data");

            input_sink = new_sink_with_type("Input text", typeof(string));
        }
    }
}