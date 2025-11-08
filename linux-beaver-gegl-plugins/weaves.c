/* weaves.c
 *
 * Copyright (C) 2025 LinuxBeaver and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * Pippin for writing GEGL
 * Grok for Writing this plugin
 * Beaver for directing Grok
 */

#include "config.h"
#include <glib/gi18n-lib.h>
#include <math.h>

#ifdef GEGL_PROPERTIES

enum_start (weave_pattern)
  enum_value (WEAVE_PATTERN_PLAIN,      "plain",      N_("Plain Weave"))
  enum_value (WEAVE_PATTERN_TWILL,      "twill",      N_("Twill Weave"))
  enum_value (WEAVE_PATTERN_SATIN,      "satin",      N_("Satin Weave"))
  enum_value (WEAVE_PATTERN_DIAMOND,    "diamond",    N_("Diamond Weave"))
  enum_value (WEAVE_PATTERN_HERRINGBONE, "herringbone", N_("Herringbone Weave"))
  enum_value (WEAVE_PATTERN_WAVE,       "wave",       N_("Wave Weave"))
enum_end (WeavePattern)

property_enum (pattern, _("Weave Pattern"),
               WeavePattern, weave_pattern, WEAVE_PATTERN_PLAIN)
  description (_("Type of weave pattern to apply"))

property_double (thread_width, _("Thread Width"), 75.0)
  description (_("Width of the weave threads in pixels"))
  value_range (2.0, 200.0)
  ui_range (2.0, 200.0)

property_double (thread_spacing, _("Thread Spacing"), 60.0)
  description (_("Spacing between threads in pixels"))
  value_range (2.0, 150.0)
  ui_range (2.0, 150.0)

property_double (angle, _("Angle"), 45.0)
  description (_("Rotation angle of the weave pattern in degrees"))
  value_range (0.0, 360.0)
  ui_range (0.0, 360.0)

property_double (shadow_intensity, _("Shadow Intensity"), 0.0)
  description (_("Intensity of the shadow effect for 3D appearance"))
  value_range (0.0, 1.0)
  ui_range (0.0, 0.5)
  ui_meta     ("role", "output-extent")

property_color (thread_color1, _("Thread Color 1"), "#a2a2a2")
  description (_("Color of the first set of threads"))

property_color (thread_color2, _("Thread Color 2"), "#cccccc")
  description (_("Color of the second set of threads"))

property_boolean (use_background_color, _("Use Background Color"), FALSE)
  description (_("Enable or disable a solid background color"))

property_color (background_color, _("Background Color"), "#000000")
  description (_("Color of the background when enabled"))
  ui_meta     ("sensitive", "use_background_color")

#else

#define GEGL_OP_FILTER
#define GEGL_OP_NAME     weaves
#define GEGL_OP_C_SOURCE weaves.c

#include "gegl-op.h"

static void
prepare (GeglOperation *operation)
{
  const Babl *format = babl_format ("RGBA float");
  gegl_operation_set_format (operation, "input", format);
  gegl_operation_set_format (operation, "output", format);
}

static GeglRectangle
get_bounding_box (GeglOperation *operation)
{
  GeglRectangle *in_rect = gegl_operation_source_get_bounding_box (operation, "input");
  return in_rect ? *in_rect : (GeglRectangle){0, 0, 0, 0};
}

static GeglRectangle
get_required_for_output (GeglOperation       *operation,
                        const gchar         *input_pad,
                        const GeglRectangle *roi)
{
  return get_bounding_box (operation);
}

static gboolean
process (GeglOperation       *operation,
         GeglBuffer          *input,
         GeglBuffer          *output,
         const GeglRectangle *result,
         gint                 level)
{
  GeglProperties *o = GEGL_PROPERTIES (operation);
  const Babl *format = babl_format ("RGBA float");
  GeglBufferIterator *iter;

  if (result->width < 1 || result->height < 1)
    {
      if (input != output)
        gegl_buffer_copy (input, result, GEGL_ABYSS_CLAMP, output, result);
      return TRUE;
    }

  iter = gegl_buffer_iterator_new (input, result, 0, format,
                                  GEGL_ACCESS_READ, GEGL_ABYSS_CLAMP, 2);
  gegl_buffer_iterator_add (iter, output, result, 0, format,
                           GEGL_ACCESS_WRITE, GEGL_ABYSS_CLAMP);

  /* Get thread and background colors */
  gfloat color1[4], color2[4], bg_color[4];
  gegl_color_get_pixel (o->thread_color1, format, color1);
  gegl_color_get_pixel (o->thread_color2, format, color2);
  gegl_color_get_pixel (o->background_color, format, bg_color);

  /* Convert angle to radians */
  gfloat angle_rad = o->angle * G_PI / 180.0f;
  gfloat cos_a = cosf (angle_rad);
  gfloat sin_a = sinf (angle_rad);

  while (gegl_buffer_iterator_next (iter))
    {
      gfloat *in_data = iter->items[0].data;
      gfloat *out_data = iter->items[1].data;
      GeglRectangle roi = iter->items[0].roi;
      gint x, y;

      for (y = 0; y < roi.height; y++)
        for (x = 0; x < roi.width; x++)
          {
            gint offset = (y * roi.width + x) * 4;
            gfloat px = x + roi.x;
            gfloat py = y + roi.y;

            /* Rotate coordinates */
            gfloat rx = px * cos_a + py * sin_a;
            gfloat ry = -px * sin_a + py * cos_a;

            /* Compute weave pattern */
            gfloat period = o->thread_width + o->thread_spacing;
            gfloat wx = fmodf (rx, period);
            gfloat wy = fmodf (ry, period);
            gboolean is_thread_x = wx < o->thread_width;
            gboolean is_thread_y = wy < o->thread_width;

            gfloat *color = color1;
            gfloat shadow = 1.0f;

            /* Determine thread crossing based on pattern */
            if (is_thread_x && is_thread_y)
              {
                gfloat cx = floorf (rx / period);
                gfloat cy = floorf (ry / period);
                gboolean x_over_y = FALSE;

                switch (o->pattern)
                  {
                  case WEAVE_PATTERN_PLAIN:
                    /* Plain weave: Alternating over-under */
                    x_over_y = fmodf (cx + cy, 2.0f) < 1.0f;
                    break;

                  case WEAVE_PATTERN_TWILL:
                    /* Twill weave: Diagonal pattern, 2x2 offset */
                    x_over_y = fmodf (cx + cy * 2.0f, 4.0f) < 2.0f;
                    break;

                  case WEAVE_PATTERN_SATIN:
                    /* Satin weave: Sparse crossing, 4x1 offset */
                    x_over_y = fmodf (cx + cy * 4.0f, 5.0f) < 1.0f;
                    break;

                  case WEAVE_PATTERN_DIAMOND:
                    /* Diamond weave: Diagonal shifts forming diamond shapes */
                    x_over_y = fmodf (fabs(cx - cy), 4.0f) < 2.0f;
                    break;

                  case WEAVE_PATTERN_HERRINGBONE:
                    /* Herringbone: Zigzag twill */
                    x_over_y = fmodf (cx + cy * 2.0f + floorf (cy / 4.0f) * 4.0f, 8.0f) < 4.0f;
                    break;

                  case WEAVE_PATTERN_WAVE:
                    /* Wave weave: Sinusoidal pattern */
                    x_over_y = sinf (G_PI * (cx + cy) / 4.0f) > 0.0f;
                    break;
                  }

                color = x_over_y ? color1 : color2;
                shadow = x_over_y ? 1.0f : 1.0f - o->shadow_intensity;
              }
            else if (is_thread_x)
              {
                color = color1;
                shadow = 1.0f - o->shadow_intensity * 0.5f;
              }
            else if (is_thread_y)
              {
                color = color2;
                shadow = 1.0f - o->shadow_intensity * 0.5f;
              }
            else
              {
                /* Background: use background color if enabled, else input image */
                color = o->use_background_color ? bg_color : in_data + offset;
                shadow = 1.0f;
              }

            /* Apply output color with shadow effect */
            for (gint j = 0; j < 4; j++)
              {
                out_data[offset + j] = color[j] * shadow;
                if (j == 3 && !is_thread_x && !is_thread_y)
                  out_data[offset + j] = color[j]; /* Preserve input alpha */
              }
          }
    }

  return TRUE;
}

static void
gegl_op_class_init (GeglOpClass *klass)
{
  GeglOperationClass     *operation_class = GEGL_OPERATION_CLASS (klass);
  GeglOperationFilterClass *filter_class  = GEGL_OPERATION_FILTER_CLASS (klass);

  operation_class->prepare         = prepare;
  operation_class->get_bounding_box = get_bounding_box;
  operation_class->get_required_for_output = get_required_for_output;
  filter_class->process            = process;

  gegl_operation_class_set_keys (operation_class,
    "name",        "ai/lb:weave",
    "title",       _("Weave"),
    "description", _("Applies a weave pattern"),
    "gimp:menu-path", "<Image>/Filters/AI GEGL",
    "gimp:menu-label", _("Weave"),
    NULL);
}

#endif
