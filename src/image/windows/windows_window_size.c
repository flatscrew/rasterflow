/**
 * Copyright (C) 2025 activey
 * 
 * This file is part of RasterFlow.
 * 
 * RasterFlow is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * RasterFlow is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.
 */

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

    SetWindowPos(hwnd, HWND_TOP, x, y, w, h, SWP_NOZORDER);
}
