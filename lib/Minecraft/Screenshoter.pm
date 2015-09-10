package Minecraft::Screenshoter;

use strict;
use warnings;
use Data::Dumper;
use Digest::MD5::File qw(file_md5_base64); 
use Minecraft::Automation;
use Exporter qw(import);

my $config = Minecraft::Automation::read_config();

sub get_window_size_position
{
	my $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Position | awk \'{print $2}\'', $config->{'user'}{'minecraft'}{'title'});
	my @pos = split(/,/, `$cmd`);
	$cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Geometry | awk \'{print $2}\'', $config->{'user'}{'minecraft'}{'title'});
	my @geo = split(/x/, `$cmd`);
	$config->{'system'}{'window'}{'geometry'} = { 'x' => $pos[0]+0, 'y' => $pos[1]+0, 'w' => $geo[0]+0, 'h' => $geo[1]+0 };
	$config = Minecraft::Automation::save_system_config($config);
	return $config;
}

sub screenshot_full_filename
{
	my $name = $_[0];
	return sprintf("%s/%s.bmp", $config->{'user'}{'paths'}{'temp'}, $name);
}

sub take_screenshot
{ 
	my ($filename, $coordinates) = @_[0..1];
	system(sprintf('import -silent -window "%s" -crop %dx%d+%d+%d %s', 
		$config->{'user'}{'minecraft'}{'title'}, 
		$coordinates->{'br'}{'x'} - $coordinates->{'tl'}{'x'}, 
		$coordinates->{'br'}{'y'} - $coordinates->{'tl'}{'y'}, 
		$coordinates->{'tl'}{'x'},
		$coordinates->{'tl'}{'y'},
		screenshot_full_filename($filename)));
	return $filename;
}

sub take_temp_screenshot
{
	my $coordinates = $_[0];
	return take_screenshot('temporally', $coordinates);
}

sub compare_screenshots
{
    my ($f0, $f1) = @_[0..1];
    #print sprintf("%s == %s : %s\n",file_md5_base64($f0), file_md5_base64($f1) ,file_md5_base64($f0) eq file_md5_base64($f1));
    return file_md5_base64(screenshot_full_filename($f0)) eq file_md5_base64(screenshot_full_filename($f1));
}

1;