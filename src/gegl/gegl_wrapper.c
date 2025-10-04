#include <gegl.h>
#include "gegl_wrapper.h"

GeglRectangle* rasterflow_node_get_bounding_box(GeglNode *node) {
    GeglRectangle rect = gegl_node_get_bounding_box(node);
    GeglRectangle *out = g_new(GeglRectangle, 1);
    *out = rect;
    return out;
}
