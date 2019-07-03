#! /bin/perl -w
#
# Imager testing

use strict;
use Imager;

my $img = Imager->new;
my $filename = 'C:/Program Files/Steam/steamapps\common/Stardew Valley/Content (unpacked)/Tilesheets/Craftables.png';

$img->read(file=>$filename) or die $img->errstr;
my $img2 = $img->crop(left=>0, top=>96, width=>16, height=>32);
$img2->write(file=>"../img/TEST_x1.png");
$img2 = $img2->scale(scalefactor=>2.0, qtype=>'preview');
$img2->write(file=>"../img/TEST_x2.png");

__END__
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