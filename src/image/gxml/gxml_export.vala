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

namespace Image.GXml {

    public class Exporter {

        public void export_to (Gegl.Node root_node, string output_file_path) {
            try {
                string xml_data = root_node.to_xml_full(root_node, "/");

                FileUtils.set_contents_full (
                    output_file_path,
                    xml_data,
                    xml_data.length,
                    GLib.FileSetContentsFlags.CONSISTENT
                );

                message ("Graph exported to: %s", output_file_path);
            } catch (Error e) {
                warning ("Failed to export graph: %s", e.message);
            }
        }
    }
}
