View3D SketchUp Plugin
======================

Version 1.0, 5/15/2011
----------------------

### Overview 

View3D is a program that calculates view factors for planar polygons
using an adaptive integration technique.  This plugin allows the input
files for View3D to be displayed in SketchUp.

### Obtaining/Installation

The plugin is available under the terms of the GNU General Public
License (GPL) version 3 as a single Ruby language file.  See the file
"COPYING" for details.  This program is distributed in the hope that
it will be useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Place it in the "plugins" directory to use it (this location varies by
platform - check the SketchUp documentation for your platform). The
next time that SketchUp is started, a new menu item "View3D" will be
added in the "Plugins" menu.

### Using the Plugin

To load a View3D file, select the "Load View3D file" menu item
(Plugins -> View3D -> Load View3D file).  Select the input file that
you want to load, and if it can be successfully loaded, a scaling
dialog box will pop up.  Since View3D files have no specific unit
system, it is necessary to specify the units of the original file.
The scale factor can be used to accommodate units other than those
listed (meters, centimeters, feet, and inches).  If, for example, the
original file has yards as the distance unit, select "ft" and set the
scale factor to 3.  If the units are something else entirely, then
select "in" and set the scale factor as the conversion factor from the
file units to inches.  Make the appropriate input and click OK to
continue.  If all goes well, the geometry will be displayed.

### Limitations and Future Plans

The plugin is not an editor, and it only displays the input file
geometry.  It is really only intended as a way to check that the
geometry is correct.  In the future, more editor-like features may be
added, but that depends upon the time that is available to work on
this (and there isn't likely to be a lot available).  It isn't clear
how well suited SketchUp is to that use.

Presently, only the F=3 format is supported.  I haven't used the F=3a
format, and unless there is a) a real demand for it or b) a reason for
me to start using the F=3a format it is unlikely to be added any time
soon.  It would not be a difficult addition to make, but I'd rather
spend that time on other things.

The most likely improvements in the near term are to assign different
surfaces different appearance so as to help distinguish the various
surface types.  Also, it would be nice to optionally label the
surfaces with names.
