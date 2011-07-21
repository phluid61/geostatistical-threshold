
#
# Given a two-dimensional array of numeric values (e.g. an image),
# this function returns two arrays:
#
#  1. where only values >= the given threshold are included (all others are nil)
#  2. the complementary values
#
def threshold pixels, width, height, level
	above = Array.new(height){|i| Array.new(width, nil) }
	below = Array.new(height){|i| Array.new(width, nil) }
	height.times do |y|
		width.times do |x|
			if pixels[y][x] >= level
				above[y][x] = pixels[y][x]
			else
				below[y][x] = pixels[y][x]
			end
		end
	end
	[above, below]
end

#
# Given a two-dimensional array of numeric values where some indices
# in the array may be nil (e.g. a segmented image), this function
# returns the experimental semivariogram -- a measure of variance of
# all non-nil values in the array separated by a given lag distance.
#
def gamma pixels, width, height, lag=1
	factor = width * height

	sum1 = 0.0
	(width-lag).times do |x|
		height.times do |y|
			if pixels[y][x+lag] and pixels[y][x]
				d = pixels[y][x+lag] - pixels[y][x]
				sum1 += (d ** 2)
			end
		end
	end
	sum1 /= factor

	sum2 = 0.0
	width.times do |x|
		(height-lag).times do |y|
			if pixels[y+lag][x] and pixels[y][x]
				d = pixels[y+lag][x] - pixels[y][x]
				sum1 += (d ** 2)
			end
		end
	end
	sum2 /= factor

	(sum1 + sum2) / 2
end

#
# Given a two-dimensional array of numeric values (e.g. an image),
# this function returns the variance of the array as a product
# of the variances of its two subsets when segmented at a given
# threshold level, using the experimental semivariogram with a
# given lag distance.
#
# Note: this will return +nil+ if either subset after segmentation
# is empty.
#
def variance pixels, width, height, level, lag=1
	a, b = threshold pixels, width, height, level

	n1 = a.flatten.compact.length
	n2 = b.flatten.compact.length
	return nil if n1 * n2 == 0

	g1 = gamma a, width, height, lag
	g2 = gamma b, width, height, lag

	n1 * g1 + n2 * g2
end

