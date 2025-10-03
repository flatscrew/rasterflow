[CCode (cheader_filename = "wrapper.h", has_type_id=false, lower_case_cprefix="tesseract_wrapper_")]
namespace TesseractWrapper {

    public unowned string version();
    public unowned string recognize_text(Gdk.Pixbuf pixbuf, string lang);
    public unowned string[] get_available_languages();
}