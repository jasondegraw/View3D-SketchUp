#
# view3d.rb - A SketchUp plugin to load and display View3D surfaces
#
# Copyright (c) 2011 Jason W. DeGraw
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require 'sketchup.rb'
# Add menu items
submenu = UI.menu("PlugIns").add_submenu("View3D")
submenu.add_item("Load View3D file") {View3D.open}
submenu.add_item("Online Manual"){UI.openURL "http://www.personal.psu.edu/jwd131/software/v3dsu1/manual/View3DSketchUpPluginV1.html"}
#
# View3DError - custom exception class that pops up a message box
#
class View3DError < StandardError
  def initialize(msg)
    UI.messagebox("View3DError: "+msg)
    super(msg)
  end
end
#
# convert2Nr - convert a string into an integer (id number)
#
def convert2Nr(s,errmsg,allowZero=false)
  if s.to_s.match(/[^0-9]/) == nil
    v = Integer(s)
    if v == 0 and !allowZero
      raise V3D_Error, errmsg+" - 0 not permitted"
    end
  else
    if allowZero
      raise V3D_Error, errmsg+" - number must be a nonnegative integer"
    else
      raise V3D_Error, errmsg+" - number must be a positive integer"
    end
  end
  return v
end
#
# convert2Float -  convert a string into a floating point number
#
# The Ruby float conversion is less than satisfactory, so this 
# ended up being more complicated than one would like.
#
def convert2Float(s,errmsg)
  return Float(s)
rescue
  # Try to recover and fix things
  st = s.to_s.strip.downcase
  begin
    if st[-1..-1] == '.'
      st[-1..-1] = ''
      return Float(st)
    else
      return Float(st.sub('.e','.0e'))
    end
  rescue
    raise V3D_Error, errmsg
  end
  raise V3D_Error, errmsg
end
#
# View3D Module - contains the loader, etc.
#
module View3D
  #
  # Module variables
  #
  @file,@data,@units,@scale = nil,nil,"m",1
  def self.data
    return @data
  end
  #
  # Vertex - View3D vertex data class
  #
  class Vertex
    attr_reader :nr, :x, :y, :z
    def initialize(nr,x,y,z)
      @nr,@x,@y,@z = nr,x,y,z
    end
  end
  #
  # Surface - View3D surface data class
  #
  class Surface
    attr_reader :nr, :v, :name
    def initialize(nr,name,v0,v1,v2,v3=nil)
      @nr,@name = nr,name
      if v3 != nil
        @v = [v0,v1,v2,v3]
      else
        @v = [v0,v1,v2]
      end
    end
    def normal()
      v0 = Geom::Vector3d.new(@v[1].x-@v[0].x,@v[1].y-@v[0].y,@v[1].z-@v[0].z)
      v1 = Geom::Vector3d.new(@v[-1].x-@v[0].x,@v[-1].y-@v[0].y,
                              @v[-1].z-@v[0].z)
      return v0.cross(v1)
    end
    def to_s()
      str = '%d %d,%d,%d' % [@nr,@v[0].nr,@v[1].nr,@v[2].nr]
      if @v.length == 4
        str += ',%d' % @v[3].nr
      end
      str += ' '+@name
      return str
    end
  end
  #
  # Data - View3D case data class
  #
  class Data
    attr_reader :verts, :surfs
    def initialize
      @surfs = []
      @verts = []
    end
    #
    # read - Read View3D input data
    #
    def read(filename)
      fp = File.open(filename,'r')
      # Scan for the F element
      format = nil
      while !fp.eof? do
        line = fp.readline().strip()
        if line[0,1] == "F"
          format = line[1..-1].split()[-1]
          break
        end
      end
      # Start over and get all the vertices and surfaces
      fp.rewind
      if format == '3'
        lastVertex = 0
        lastSurface = 0
        while !fp.eof? do
          line = fp.readline().strip()
          case line[0,1].downcase
          when 'v'
            data = line[1..-1].split()
            if data.length < 4
              raise View3DError, "Insufficient data in vertex entry %d"%(lastVertex+1) 
            end
            nr = convert2Nr(data[0],"Bad vertex number in vertex entry %d"%(lastVertex+1))
            if nr != lastVertex+1
              raise View3DError, "Nonsequential vertex number detected in vertex %d" % nr
            end
            x = convert2Float(data[1],"Bad x value in vertex %d" % nr)
            y = convert2Float(data[2],"Bad y value in vertex %d" % nr)
            z = convert2Float(data[3],"Bad y value in vertex %d" % nr)
            @verts << Vertex.new(nr,x,y,z)
            lastVertex += 1
          when 's'
            data = line[1..-1].split()
            if data.length < 9
              raise View3DError,"Insufficient data in surface entry %d"%(lastSurface+1)
            end
            nr = convert2Nr(data[0],"Bad surface number in surface entry %d" % (lastSurface+1))
            if nr != lastSurface+1
              raise View3DError, "Nonsequential vertex number detected in vertex %d" % nr
            end
            v0 = convert2Nr(data[1],"Bad first vertex nubmer in surface %d"%nr)
            if v0 > @verts.length
              raise View3DError, "First vertex in surface %d is undefined" % nr
            end
            v1 = convert2Nr(data[2],"Bad second vertex number in surface %d"%nr)
            if v1 > @verts.length
              raise View3DError, "Second vertex in surface %d is undefined" % nr
            end
            v2 = convert2Nr(data[3],"Bad third vertex number in surface %d"%nr)
            if v2 > @verts.length
              raise View3DError, "Third vertex in surface %d is undefined" % nr
            end
            v3 = convert2Nr(data[4],"Bad fourth vertex number in surface %d" % nr,true)
            if v3 > @verts.length
              raise View3DError, "Fourth vertex in surface %d is undefined" % nr
            end
            if v3 == 0:
                v3 = nil
            else
              v3 = @verts[v3-1]
            end
            @surfs << Surface.new(nr,data[8],@verts[v0-1],@verts[v1-1],
                                  @verts[v2-1], v3)
            lastSurface += 1
          when 'e'
            break
          end
        end
      elsif format == '3a'
        raise View3DError, 'Format 3a not yet supported'
      else
        raise View3DError, 'Unrecognized format "%s"' % format
      end
    end
  end
  # Function to actually load the data
  def self.open()
    file = @file = UI.openpanel("Open View3D File", ".", "*.vs3")
    if file != nil
      # Load data
      data = @data = Data.new
      data.read(file)
      input = UI.inputbox(["Scale factor","Original Units"],
                          ["1.0","m"],
                          ["","m|cm|ft|in"],
                          "Input Scale and Units")
      scale = @scale=Float(input[0])
      units = @units = input[1]
      # Figure out the scaling/conversion
      case units
      when "ft"
        scale *= 12
      when "m"
        scale *= 12.0/0.3048
      when "cm"
        scale *= 12.0/304.8
      end
      ents = Sketchup.active_model.entities
      data.surfs.each do |srf|
        pt = []
        srf.v.each do |vert|
          pt << [vert.x*scale, vert.y*scale, vert.z*scale]
        end
        # Make sure the surface is facing the right direction
        new_face = ents.add_face(*pt)
        if srf.normal().dot(new_face.normal()) < 0.0
          new_face.reverse!
        end
      end
    end
  end
  # Get a summary
  def self.summary()
    return "Filename:%s\nUnits: %s\nScale: %f\n" % [@file,@units,@scale]
  end
end
