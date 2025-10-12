#pragma once
#include <gdk/gdk.h>

void rf_get_window_rect(GdkSurface *surface, int *x, int *y, int *w, int *h);
void rf_set_window_rect(GdkSurface *surface, int x, int y, int w, int h);
