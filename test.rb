$filename = 'images/chopper-640x426x8.raw'
$width  = 640
$height = 426

def loadfile
	raw_bytes = File.open($filename,'r'){|f|f.read}
	raw_bytes = raw_bytes.unpack('C*')
print "... "
	pixels = Array.new($height){|i| Array.new($width, 0) }
	i = 0
	$height.times do |y|
		$width.times do |x|
			pixels[y][x] = raw_bytes[i]
			i += 1
		end
	end

	pixels
end

def threshold pixels, level
	above = Array.new($height){|i| Array.new($width, nil) }
	below = Array.new($height){|i| Array.new($width, nil) }
	$height.times do |y|
		$width.times do |x|
			if pixels[y][x] >= level
				above[y][x] = pixels[y][x]
			else
				below[y][x] = pixels[y][x]
			end
		end
	end
	[above, below]
end

def gamma(pixels, lag=1)
	factor = $width * $height

	sum1 = 0.0
	($width-lag).times do |x|
		$height.times do |y|
			if pixels[y][x+lag] and pixels[y][x]
				d = pixels[y][x+lag] - pixels[y][x]
				sum1 += (d ** 2)
			end
		end
	end
	sum1 /= factor

	sum2 = 0.0
	$width.times do |x|
		($height-lag).times do |y|
			if pixels[y+lag][x] and pixels[y][x]
				d = pixels[y+lag][x] - pixels[y][x]
				sum1 += (d ** 2)
			end
		end
	end
	sum2 /= factor

	(sum1 + sum2) / 2
end

print "LOADING #{$filename} "
pixels = loadfile
puts "LOADED"
#p pixels

got_some = false
bv = nil
bl = nil
v = Array.new(254)
254.times do |l|
	puts "CALCULATING VARIANCES FOR THRESHOLD #{l}"

	t = Time.now.to_f
	a, b = threshold pixels, l
	puts ".. segmented image in #{Time.now.to_f - t}"

	t = Time.now.to_f
	n1 = a.flatten.compact.length
	n2 = b.flatten.compact.length

	if n1 * n2 > 0
		g1 = gamma a
		puts "   .. got g1"
		g2 = gamma b
		puts "   .. got g2"

		vv = n1 * g1 + n2 * g2
		puts ".. calculated variance #{n1}*#{g1} + #{n2}*#{g2} = #{vv} in #{Time.now.to_f - t}"

		v[l] = vv
		if bv.nil? or bv > vv
			bv = vv
			bl = l
		end

		got_some = true
	else
		puts ".. skipped; empty segments"
		break if got_some
	end
end

p v

puts "Best: #{bl} [#{bv}]"

