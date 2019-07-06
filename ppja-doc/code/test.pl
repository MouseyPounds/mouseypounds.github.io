#! /bin/perl -w
#
# Imager testing

use strict;
use Imager;
use Math::Trig;
use Imager::Color;

my $img = Imager->new();
$img->read(file=>"test_crop.png") or die $img->errstr;

my $overlay = $img->crop(left=>112, top=>0, width=>16, height=>32);

$overlay->write(file=>"test_overlay.png");


$img->read(file=>"test_crop.png") or die $img->errstr;
my $target = Imager::Color->new(rgb=>[255, 70, 175]);
my $new_h;
my $new_s;
($new_h, $new_s, $_, $_) = $target->hsv();

# Let's brute force this shit
for (my $x = 0; $x < $img->getwidth(); $x++) {
	for (my $y = 0; $y < $img->getheight(); $y++) {
		my $c = $img->getpixel(x=>$x, y=>$y);
		my ($h, $s, $v, $a) = $c->hsv();
		my $c2 = Imager::Color->new(hsv=>[$new_h, $new_s, $v], alpha=>$a);
		$img->setpixel(x=>$x, y=>$y, color=>$c2);
	}
}
$img->write(file=>"ColorsNew.png");

__END__
    "Colors": [
		"255, 70, 175, 255",
		"255, 0, 0, 255",
		"255, 0, 100, 255"],

		
-------------
# Trying stuff from http://beesbuzz.biz/code/16-hsv-color-transforms
# $H is Hue angle (0 would be no change)
# $S is Saturation scaling (1 would be no change)
# $V is Value scaling (1 would be no change)
my $H = 90;
my $S = 1;
my $V = 1;
# Mechanics
my $theta = pi*$H/180;
my $U = cos($theta);
my $W = sin($theta);
$img = $img->convert(matrix=>[
[ .299*$V + .701*$V*$S*$U + .168*$V*$S*$W, .587*$V - .587*$V*$S*$U + .330*$V*$S*$W, .114*$V - .114*$V*$S*$U - .497*$V*$S*$W ],
[ .299*$V - .299*$V*$S*$U - .328*$V*$S*$W, .587*$V + .413*$V*$S*$U + .035*$V*$S*$W, .114*$V - .114*$V*$S*$U + .292*$V*$S*$W ],
[ .299*$V - .300*$V*$S*$U + 1.25*$V*$S*$W, .587*$V - .588*$V*$S*$U + 1.05*$V*$S*$W, .114*$V + .886*$V*$S*$U - .203*$V*$S*$W ],
]);
	   
$img->write(file=>"ColorsNew.png");
--------------
		
$img->read(file=>"Colors.png") or die $img->errstr;
my @map = map { int( $_*2 ) } 0..255;
$img->map( red=>\@map );
$img->write(file=>"ColorsNew.png");
------------
#This did nothing but throw errors
my %opts = (
	rpnexpr => 'x y getp1 !pix 128 128 255 rgb @pix',
	);
	# 'rpnexpr' => 'x y getp1 !pix @pix value 0.96 gt @pix sat 0.1 lt and 128 128 255 rgb @pix ifp',
	# This transform gets pixel at x,y and stores it
	# Then retrieves it and checks if value is greater than 0.96?
	# Then retrieves again and checks if sat is less than 0.1
	# then sets its rgb to 128, 128, 255?
my $img2 = Imager->new();
$img2->Imager::transform2(\%opts, $img);
	   

------------		
my $img2 = $img->crop(left=>0, top=>96, width=>16, height=>32);
$img2->write(file=>"../img/TEST_x1.png");
$img2 = $img2->scale(scalefactor=>2.0, qtype=>'preview');
$img2->write(file=>"../img/TEST_x2.png");
my $img = Imager->new;
my $filename = "mystical.png";

print "reading\n";
$img->read(file=>$filename) or die $img->errstr;

print "cropping\n";
my $img2 = $img->crop(left=>0, top=>0, width=>16, height=>32);
print "writing static\n";
$img2->write(file=>"img_test.png");

print "scaling\n";
$img2 = $img->crop(left=>0, top=>0, width=>16, height=>32)->scale(scalefactor=>2.0, qtype=>'normal');
$img2->write(file=>"scale_test_1.png");
$img2 = $img->crop(left=>0, top=>0, width=>16, height=>32)->scale(scalefactor=>2.0, qtype=>'preview');
$img2->write(file=>"scale_test_2.png");


print "creating animation\n";
# This logic is great if we have just the one machine in a file, but if there are multiple machines
# we'd need to adjust for that by only counting (and cropping) from the correct starting position
# Here we are excluding the first sprite (idle) and last sprite (ready) to only animate the rest.
print "image size is " . $img->getwidth() . " x " . $img->getheight . " px\n";
my $num_frames = $img->getwidth()/16 - 2;
my @imgs = ();

for (my $i = 1; $i <= $num_frames; $i++) {
	$imgs[$i-1] = $img->crop(left=>16*$i, top=>0, width=>16, height=>32);
}

# GIF animation details
# gif_delay is in hundredths of a second but SV runs at 60fps so to actually mimic the proper timing we would do
#   gif_delay = 100/fps. CFR appears to default to 6fps. An array ref may be possible for individual timings.
# gif_disposal isn't described in current POD but from an earlier version: 
#   0 means unspecified, 1 means the image should be left in place, 
#   2 means restore to background colour and 3 means restore to the previous value.

print "writing anim\n";
Imager->write_multi({ file=>"anim_test.gif", type=>'gif' , gif_loop=>0, gif_delay=>100/6, gif_disposal=>2}, @imgs)
  or die Imager->errstr;

print "creating scaled animation\n";
@imgs = ();

for (my $i = 1; $i <= $num_frames; $i++) {
	$imgs[$i-1] = $img->crop(left=>16*$i, top=>0, width=>16, height=>32)->scale(scalefactor=>2.0, qtype=>'preview');
}
 Imager->write_multi({ file=>"anim_test_2.gif", type=>'gif' , gif_loop=>0, gif_delay=>100/6, gif_disposal=>2}, @imgs)
  or die Imager->errstr;
 
  
print "creating spritesheet\n";
# For this example, we will grab the first sprite of mystical.png, lemonade.png, and newmachines2.png
# as well as sprites 0, 5, 7, and 14 of MoreMachines.png
# These will all be put together in a single spritesheet of 7 images
my $sheet = Imager->new(xsize=>16*7, ysize=>32, channels=>4);
my $count = 0;
my @fnames = qw(mystical.png lemonade.png newmachines2.png);
for my $f (@fnames) {
	$img->read(file=>$f) or die $img->errstr;
	$sheet->paste(src=>$img,
            left => 16*$count, top => 0,
            src_minx => 0, src_miny => 0,
			width=>16, height=>32);
	$count++;
}
my @frames = qw(0 5 7 14);
$img->read(file=>"MoreMachines.png") or die $img->errstr;
for my $f (@frames) {
	$sheet->paste(src=>$img,
            left => 16*$count, top => 0,
            src_minx => 16*$f, src_miny => 0,
			width=>16, height=>32);
	$count++;
}
$sheet->write(file=>"sheet_test.png");

print "done";