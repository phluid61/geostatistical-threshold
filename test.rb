require_relative 'variogram.rb'
require_relative 'imageio.rb'

TGA = 'images/chopper'

CSV = 'out.csv'
csv = File.new(CSV, 'w')

tga = ImageIO.load_tga_file "#{TGA}.tga"
pixels = tga[:pixels]
width = tga[:header][:image_spec][:width]
height = tga[:header][:image_spec][:height]

min, max = pixels.reduce(:+).minmax
#puts "min = #{min}, max = #{max}"

### CSV Header
csv.print 'Lag (h),',255.times.to_a.join(','),",Best Level,Best Variance,Time\n"

### Calculate individual variances for each lag distance (1-3)
(1..3).each do |lag|
  #puts "Lag: #{lag}"
  t0 = Time.now.to_f
  bv = nil
  bl = nil
  v = Array.new(255)
  (min+1..max).each do |level|
    vv = Variogram.variance pixels, width, height, level, lag
    v[level] = vv
    #puts "  Level: #{level} = #{vv}"
    if bv.nil? or bv > vv
      bv = vv
      bl = level
    end
  end
  td = Time.now.to_f - t0
  #puts "Best level: #{bl} (#{bv})"
  csv.print "#{lag},", v.map{|x|x ? x : 0}.join(','),",#{bl},#{bv},#{td}\n"
end

### Calculate the mean variance over the lag distances (1-3)
#puts "Mean (3)"
t0 = Time.now.to_f
bv = nil
bl = nil
v = Array.new(255)
(min+1..max).each do |level|
  vv = Variogram.mean_variance pixels, width, height, level, 3
  #puts "  Level: #{level} = #{vv}"
  v[level] = vv
  if bv.nil? or bv > vv
    bv = vv
    bl = level
  end
end
td = Time.now.to_f - t0
#puts "Best level: #{bl} (#{bv})"
csv.print '"mean(1,2,3)",', v.map{|x|x ? x : 0}.join(','),",#{bl},#{bv},#{td}\n"

### Create a partitioned image using the mean variance
above,below = Variogram.threshold pixels, width, height, bl
tga[:pixels] = above.map{|row| row.map{|p| p.nil? ? 0 : 255 } }
ImageIO.save_tga_file "#{TGA}-parted.tga", tga

csv.close
$stdout.flush

