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

public Gdk.RGBA get_contrasting_text_color(Gdk.RGBA bg) {
    double luminance = 0.2126 * bg.red + 0.7152 * bg.green + 0.0722 * bg.blue;
    return (luminance > 0.5)
        ? Gdk.RGBA() { red = 0, green = 0, blue = 0, alpha = 1 }
        : Gdk.RGBA() { red = 1, green = 1, blue = 1, alpha = 1 };  
}


public Gdk.RGBA adjust_for_contrast(Gdk.RGBA color) {
    float h, s, l;
    rgb_to_hsl(color.red, color.green, color.blue, out h, out s, out l);

    bool light_bg = l > 0.5f;

    if (light_bg) {
        // dla jasnego tła – ciemniejszy, bardziej nasycony
        l = (l * 0.35f < 0.0f) ? 0.0f : (l * 0.35f);
        s = (s * 1.4f > 1.0f) ? 1.0f : (s * 1.4f);
    } else {
        // dla ciemnego tła – jaśniejszy, mniej nasycony
        l = (l + 0.45f > 1.0f) ? 1.0f : (l + 0.45f);
        s = (s * 0.8f < 0.0f) ? 0.0f : (s * 0.8f);
    }

    float r, g, b;
    hsl_to_rgb(h, s, l, out r, out g, out b);
    return Gdk.RGBA() { red = r, green = g, blue = b, alpha = 1.0f };
}

