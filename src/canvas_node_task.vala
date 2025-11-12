// Copyright (C) 2025 activey
// 
// This file is part of RasterFlow.
// 
// RasterFlow is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// RasterFlow is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with RasterFlow.  If not, see <https://www.gnu.org/licenses/>.

public class CanvasNodeTask : Object {
    public signal void on_finished();
    
    private Gtk.ProgressBar bar;
    private bool finished = false;

    internal CanvasNodeTask(Gtk.ProgressBar bar) {
        this.bar = bar;
    }

    public void set_progress(double fraction) {
        if (finished) return;
        bar.set_fraction(fraction.clamp(0.0, 1.0));
    }

    public void pulse() {
        if (finished) return;
        bar.pulse();
    }

    public void finish() {
        if (finished) return;
        finished = true;
        bar.set_fraction(0);
        
        on_finished();
    }
}