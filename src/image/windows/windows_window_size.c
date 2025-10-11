#include <windows.h>
#include <gdk/win32/gdkwin32.h>

void rf_get_window_rect(GdkSurface *surface, int *x, int *y, int *w, int *h) {
    if (!surface) {
        *x = *y = *w = *h = 0;
        return;
    }

    HWND hwnd = gdk_win32_surface_get_handle(surface);
    if (!hwnd) {
        *x = *y = *w = *h = 0;
        return;
    }

    RECT rect;
    if (GetWindowRect(hwnd, &rect)) {
        *x = rect.left;
        *y = rect.top;
        *w = rect.right - rect.left;
        *h = rect.bottom - rect.top;
    } else {
        *x = *y = *w = *h = 0;
    }
}

void rf_set_window_rect(GdkSurface *surface, int x, int y, int w, int h) {
    HWND hwnd = gdk_win32_surface_get_handle(surface);
    if (!hwnd) return;
    MoveWindow(hwnd, x, y, w, h, TRUE);
}