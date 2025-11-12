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

namespace Data {

    public class FileOriginNodeBuilder : Object {

        public string node_builder_id {
            get;
            private set;
        }

        public FileOriginNodeBuilder(string node_builder_id) {
            this.node_builder_id = node_builder_id;
        }

        public virtual void apply_file_data(CanvasDisplayNode node, File file, FileInfo file_info) {

        }

        public CanvasNodeBuilder? find_builder(CanvasNodeFactory node_factory) {
            return node_factory.find_builder(node_builder_id);
        }
    }

    public class FileOriginNodeFactory : Object {
        private Gee.MultiMap<string, FileOriginNodeBuilder> data_type_builders = new Gee.HashMultiMap<string, FileOriginNodeBuilder> ();

        public void register(FileOriginNodeBuilder node_builder, string[] mime_types) {
            foreach (var mime_type in mime_types) {
                data_type_builders.set(mime_type, node_builder);
            }
        }

        public FileOriginNodeBuilder[] available_builders(string content_type) {
            FileOriginNodeBuilder[] builders = {};

            foreach (var key in data_type_builders.get_keys()) {
                if (key == content_type) {
                    foreach (var builder in data_type_builders.get(key)) {
                        builders += builder;
                    }
                }
            }
            return builders;
        }
    }
}