[CCode (cheader_filename = "gegl_wrapper.h")]
namespace Rasterflow {
    [CCode (cname = "rasterflow_node_get_bounding_box")]
    public static Gegl.Rectangle node_get_bounding_box(Gegl.Node node);
}