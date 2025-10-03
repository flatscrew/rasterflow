#include <gegl.h>
#include "gegl_wrapper.h"

void rasterflow_node_get_bounding_box (GeglNode *node, GeglRectangle *out) {
    *out = gegl_node_get_bounding_box(node);
}