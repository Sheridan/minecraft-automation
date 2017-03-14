package Minecraft::Window;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);

sub get_size_and_position
{
  my $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Position | awk \'{print $2}\'', $main::config->{'user'}{'minecraft'}{'title'});
  my @pos = split(/,/, `$cmd`);
  $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Geometry | awk \'{print $2}\'', $main::config->{'user'}{'minecraft'}{'title'});
  my @geo = split(/x/, `$cmd`);
  return { 'x' => $pos[0]+0, 'y' => $pos[1]+0, 'w' => $geo[0]+0, 'h' => $geo[1]+0 };
}

sub restore_size_and_position
{
  # system(sprintf('xdotool search --name "%s" windowactivate --sync windowsize --sync %d %d',
  #   $main::config->{'user'}{'minecraft'}{'title'},
  #   $main::config->{'system'}{'window'}{'geometry'}{'w'},
  #   $main::config->{'system'}{'window'}{'geometry'}{'h'}));
  system(sprintf('xdotool search --name "%s" windowactivate --sync windowsize --sync %d %d windowmove --sync %d %d',
    $main::config->{'user'}{'minecraft'}{'title'},
    $main::config->{'system'}{'window'}{'geometry'}{'w'},
    $main::config->{'system'}{'window'}{'geometry'}{'h'},
    $main::config->{'system'}{'window'}{'geometry'}{'x'},
    $main::config->{'system'}{'window'}{'geometry'}{'y'}));
}

1;
