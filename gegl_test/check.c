#include <gegl.h>
#include <stdio.h>

int main() {
    gegl_init(NULL, NULL);

    GeglNode *graph = gegl_node_new();

    GeglColor *red = gegl_color_new("red");
    GeglNode *color = gegl_node_new_child(graph,
                                          "operation", "gegl:color",
                                          "value", red,
                                          NULL);

    GeglNode *save = gegl_node_new_child(graph,
                                         "operation", "gegl:png-save",
                                         "path", "out.png",
                                         NULL);

    gegl_node_connect_to(color, "output", save, "input");

    GeglRectangle bbox_in = gegl_node_get_bounding_box(save);

    if (gegl_rectangle_is_infinite_plane(&bbox_in)) {
        printf("⚠️ bounding box is infinite plane\n");
    } else {
        printf("✅ finite bbox: x=%d y=%d w=%d h=%d\n",
               bbox_in.x, bbox_in.y,
               bbox_in.width, bbox_in.height);
    }

    g_object_unref(red);
    g_object_unref(graph);
    gegl_exit();
    return 0;
}
