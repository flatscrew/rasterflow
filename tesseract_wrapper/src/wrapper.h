#include <gdk-pixbuf/gdk-pixbuf.h>

extern const char* tesseract_wrapper_version();
extern char* tesseract_wrapper_recognize_text(GdkPixbuf* pixbuf, char* lang);
extern char* tesseract_wrapper_get_available_languages(int *array_length);
