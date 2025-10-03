// Convert RGB to HSL
void rgb_to_hsl(float r, float g, float b, out float h, out float s, out float l) {
    float min = float.min(float.min(r, g), b);
    float max = float.max(float.max(r, g), b);
    float delta = max - min;

    h = 0;
    s = 0;
    l = (max + min) / 2;

    if (delta != 0) {
        s = l < 0.5 ? delta / (max + min) : delta / (2 - max - min);

        if (r == max) {
            h = (g - b) / delta + (g < b ? 6 : 0);
        } else if (g == max) {
            h = (b - r) / delta + 2;
        } else if (b == max) {
            h = (r - g) / delta + 4;
        }

        h /= 6;
    }
}

// Convert HSL to RGB
void hsl_to_rgb(float h, float s, float l, out float r, out float g, out float b) {
    float p, q;

    if (s == 0) {
        r = l;
        g = l;
        b = l;
    } else {
        q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        p = 2 * l - q;

        r = hue_to_rgb(p, q, h + 1/3.0f);
        g = hue_to_rgb(p, q, h);
        b = hue_to_rgb(p, q, h - 1/3.0f);
    }
}

float hue_to_rgb(float p, float q, float t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1/6.0) return p + (q - p) * 6 * t;
    if (t < 1/2.0) return q;
    if (t < 2/3.0) return p + (q - p) * (2/3.0f - t) * 6;
    return p;
}

public Gdk.RGBA adjust_saturation(Gdk.RGBA color, float factor) {
    float h, s, l;
    rgb_to_hsl(color.red, color.green, color.blue, out h, out s, out l);

    // Adjust lightness by factor. Ensure it remains within [0, 1] range.
    //  h *= factor;
    s *= factor;
    l *= factor;

    //  if (s > 1.0) s = 1.0f;
    //  if (s < 0.0) s = 0.0f;

    var new_red = 0f;
    var new_green = 0f;
    var new_blue = 0f;
    hsl_to_rgb(h, s, l, out new_red, out new_green, out new_blue);

    Gdk.RGBA new_color = {
        red: new_red,
        green: new_green,
        blue: new_blue
    };
    new_color.alpha = color.alpha; // Preserve the original alpha
    return new_color;
}