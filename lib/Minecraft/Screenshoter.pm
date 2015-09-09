package Minecraft::Screenshoter;

use strict;
use warnings;
use Data::Dumper;
use Minecraft::Automation;
use Exporter qw(import);

my $config = Minecraft::Automation::read_config();

sub take_screenshot
{ 
	my ($filename, $coordinates) = @_[0..1];
	system(sprintf('import -silent -window "%s" -crop %dx%d+%d+%d %s', 
		$config->{'user'}{'minecraft'}{'title'}, 
		$coordinates->{'br'}{'x'} - $coordinates->{'tl'}{'x'}, 
		$coordinates->{'br'}{'y'} - $coordinates->{'tl'}{'y'}, 
		$coordinates->{'tl'}{'x'},
		$coordinates->{'tl'}{'y'},
		sprintf("%s/%s.bmp", $config->{'user'}{'paths'}{'temp'}, $filename)));
	return $filename;
}

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

1;