[CCode (cheader_filename = "windows_window_size.h", cname = "rf_get_window_rect")]
public extern void rf_get_window_rect(Gdk.Surface surface,
                                       out int x,
                                       out int y,
                                       out int w,
                                       out int h);

[CCode (cheader_filename = "windows_window_size.h", cname = "rf_set_window_rect")]
public extern void rf_set_window_rect(Gdk.Surface surface,
                                      int x, int y, int w, int h);