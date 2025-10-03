#include <tesseract/baseapi.h>
#include <tesseract/genericvector.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <cstdio>
#include <allheaders.h>
#include <string>
#include <iostream>

extern "C" {
    const char* tesseract_wrapper_version() {
        return tesseract::TessBaseAPI::Version();
    }

    char* tesseract_wrapper_recognize_text(GdkPixbuf* pixbuf, char* lang) {
        tesseract::TessBaseAPI *api = new tesseract::TessBaseAPI();
        // Initialize tesseract-ocr with English, without specifying tessdata path
        if (api->Init(NULL, lang)) {
            fprintf(stderr, "Could not initialize tesseract.\n");
            return nullptr;  // Return nullptr on error
        }

        char *outText;

        gint width = gdk_pixbuf_get_width(pixbuf);
        gint height = gdk_pixbuf_get_height(pixbuf);
        guchar* pixels = gdk_pixbuf_get_pixels(pixbuf);
        gint stride = gdk_pixbuf_get_rowstride(pixbuf);
        int bytes_per_pixel = gdk_pixbuf_get_n_channels(pixbuf);
    
        api->SetImage(pixels, width, height, bytes_per_pixel, stride);
        api->SetSourceResolution(300);
        api->SetRectangle(0, 0, width, height);
        outText = api->GetUTF8Text();
        api->End();
        delete api;

        return outText;
    }

     char** tesseract_wrapper_get_available_languages(int* array_length) {
        tesseract::TessBaseAPI api;
        api.Init(NULL, NULL);

        GenericVector<STRING> langs;
        api.GetAvailableLanguagesAsVector(&langs);

        *array_length = langs.size();  // Store the length

        char** langList = new char*[langs.size() + 1];  // +1 for NULL termination

        for (int i = 0; i < langs.size(); ++i) {
            langList[i] = strdup(langs[i].string());
        }

        langList[langs.size()] = NULL;  // NULL terminate the list

        return langList;
    }

}