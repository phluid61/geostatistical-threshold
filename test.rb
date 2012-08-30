require './variogram.rb'

FILENAME = 'images/chopper-640x426x8.raw'
WIDTH  = 640
HEIGHT = 426

if TRUE #=verbose
	def blab *args
		Thread.new {
			puts *args
		}
	end
else
	def blab *args
	end
end

CSV = 'out.csv'
csv = File.new(CSV, 'w')

def load_raw_file filename, width, height
	raw_bytes = File.open(filename,'r'){|f|f.read}
	raw_bytes = raw_bytes.unpack('C*')
	pixels = Array.new(height){|i| Array.new(width, 0) }
	i = 0
	height.times do |y|
		width.times do |x|
			pixels[y][x] = raw_bytes[i]
			i += 1
		end
	end

	pixels
end

#print "LOADING #{FILENAME} "
pixels = load_raw_file FILENAME, WIDTH, HEIGHT
#blab "LOADED"
#p pixels

csv.print 'Lag (h),',255.times.to_a.join(','),",Best Level,Best Variance,Time\n"

(1..3).each do |lag|
	t0 = Time.now.to_f
	blab "LAG #{lag}: starting"
	got_some = false
	bv = nil
	bl = nil
	v = Array.new(255)
	254.times do |level|
		t = Time.now.to_f
		vv = variance pixels, WIDTH, HEIGHT, level, lag
		if vv.nil?
			blab "  THRESHOLD #{level}: empty segments"
			break if got_some
		else
			blab "  THRESHOLD #{level}: #{vv} in #{'%0.3f' % ((Time.now.to_f - t)*1000)}ms"
			v[level] = vv
			if bv.nil? or bv > vv
				bv = vv
				bl = level
			end
			got_some = true
		end
	end
	td = Time.now.to_f - t0
	blab "LAG #{lag}: done in #{'%0.3f' % td}s"
	csv.print "#{lag},", v.map{|x|x ? x : 0}.join(','),",#{bl},#{bv},#{td}\n"
end
# mean variance...
t0 = Time.now.to_f
blab "LAG (1,2,3): starting"
got_some = false
bv = nil
bl = nil
v = Array.new(255)
254.times do |level|
	#t = Time.now.to_f
	vv = mean_variance pixels, WIDTH, HEIGHT, level, 3
	if vv.nil?
		break if got_some
	else
		v[level] = vv
		if bv.nil? or bv > vv
			bv = vv
			bl = level
		end
		got_some = true
	end
end
td = Time.now.to_f - t0
blab "LAG (1,2,3): done in #{'%0.3f' % td}s"
csv.print '"mean(1,2,3)",', v.map{|x|x ? x : 0}.join(','),",#{bl},#{bv},#{td}\n"

csv.close
$stdout.flush

