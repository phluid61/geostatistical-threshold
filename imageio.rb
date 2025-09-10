
module ImageIO

  def self._do_load raw_bytes, width, height, bytes
    raw_bytes = raw_bytes.unpack("C*")
    pixels = Array.new(height){|i| Array.new(width, 0) }
    i = 0
    if bytes == 1
      height.times do |y|
        width.times do |x|
          pixels[y][x] = raw_bytes[i]
          i += 1
        end
      end
    else
      height.times do |y|
        width.times do |x|
          pixels[y][x] = raw_bytes[i,bytes]
          i += bytes
        end
      end
    end

    pixels
  end

  def self.load_raw_file filename, width, height
    raw_bytes = File.open(filename,'r'){|f|f.read}
    _do_load raw_bytes, width, height, 1
  end

  def self.load_tga_file filename
    raw_bytes = File.open(filename,'r'){|f|f.read}

    header = raw_bytes.unpack('CCC''S<S<C''S<S<S<S<CC')
    image_descriptor = header[11]
    header_struct = {
      :ID_length => header[0],
      :color_map_type => header[1],
      :image_type => header[2],
      :color_map_spec => {
        :first_index => header[3],
        :length => header[4],
        :entry_size => header[5],
      },
      :image_spec => {
        :x_origin => header[6],
        :y_origin => header[7],
        :width => header[8],
        :height => header[9],
        :pixel_depth => header[10],
        :image_descriptor => {
          :_ => image_descriptor,
          :alpha_depth => image_descriptor & 0b1111,
          :direction => {
            :left_to_right => ((image_descriptor & 0b010000) == 0),
            :bottom_to_top => ((image_descriptor & 0b100000) == 0),
          },
          :reserved => image_descriptor & 0b11000000,
        },
      },
    }
    raise "invalid TGA file: image_spec.image_descriptor bits 7-6 must be 0" unless header_struct[:image_spec][:image_descriptor][:reserved] == 0
    cursor = 18

    image_id = nil
    if header_struct[:ID_length] > 0
      image_id = raw_bytes[cursor, header_struct[:ID_length]]
      cursor += header_struct[:ID_length]
    end

    color_map = nil
    case header_struct[:color_map_type]
    when 0
      # no color map
      raise "color_map_spec.length > 0 but color_map_type = 0" if header_struct[:color_map_spec][:length] != 0
    when 1
      # FIXME
      raise "color maps not implemented yet!"
    when 2..127
      raise "invalid TGA file: color_map_type reserved by Truevision"
    else
      # available for developer use
      raise "cannot read TGA file with color_map_type=#{header_struct[:color_map_type]} (expected 0 or 1)"
    end

    w = header_struct[:image_spec][:width]
    h = header_struct[:image_spec][:height]
    d = header_struct[:image_spec][:pixel_depth] >> 3

    _pixels = nil
    pixels = nil
    case header_struct[:image_type]
    when 0
      raise "cannot read TGA file with no image data"
    when 1
      raise "color maps not implemented yet"
    when 2
      raise "true-color images not implemented yet"
    when 3
      _pixels = raw_bytes[cursor, w*h*d]
      pixels = _do_load _pixels, w, h, d
      cursor += w*h*d
    when 9
      raise "RLE and color maps not implemented yet"
    when 10
      raise "RLE and true-color images not implemented yet"
    when 11
      raise "RLE not implemented yet"
    else
      raise "cannot read TGA file with image_type=#{header_struct[:image_type]}"
    end

    _rest = raw_bytes[cursor..-1]
    _rest = '' unless _rest

    if raw_bytes[-18,18] == "TRUEVISION-XFILE.\0"
      footer = raw_bytes[-26,8].unpack('L<L<')
      footer_struct = {
        :extension_offset => footer[0],
        :developer_area_offset => footer[1],
      }
    end

    {
      :header => header_struct,
      :image_id => image_id,
      :color_map => color_map,
      :pixels => pixels,
      :_rest => _rest,
      :footer => footer_struct,
    }
  end

  def self.save_tga_file filename, tga
    bytes = ''.force_encoding('UTF-8')
    bytes << [
      tga[:header][:ID_length],
      tga[:header][:color_map_type],
      tga[:header][:image_type],
      tga[:header][:color_map_spec][:first_index],
      tga[:header][:color_map_spec][:length],
      tga[:header][:color_map_spec][:entry_size],
      tga[:header][:image_spec][:x_origin],
      tga[:header][:image_spec][:y_origin],
      tga[:header][:image_spec][:width],
      tga[:header][:image_spec][:height],
      tga[:header][:image_spec][:pixel_depth],
      tga[:header][:image_spec][:image_descriptor][:_],
    ].pack('CCC''S<S<C''S<S<S<S<CC')
    bytes << tga[:image_id] if tga[:image_id]
    #bytes << tga[:color_map][:_] if tga[:color_map]
    bytes << tga[:pixels].flatten.pack('C*') # FIXME: RLE, higher BPP, etc.
    bytes << tga[:_rest].force_encoding('UTF-8') # FIXME: KLUGE

    File.open(filename,'w'){|f|f.write bytes}
  end

  extend self
end

