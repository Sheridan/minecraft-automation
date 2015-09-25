package Minecraft::Player::Soul;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my ($class) = $_[0];
  my $self = { };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub call_xdotool
{
  my ($self, $command) = @_[0..1];
  my $attempts = 10;
  $command = sprintf('xdotool search --name "%s" windowactivate --sync %s > %s/xdotool-minecraft-automation.log 2>&1',
                                    $main::config->{'user'}{'minecraft'}{'title'},
                                    $command,
                                    $main::config->{'user'}{'paths'}{'temp'});
  # print $command."\n";
  while(system($command) != 0 ||
        -s sprintf('%s/xdotool-minecraft-automation.log', $main::config->{'user'}{'paths'}{'temp'}))
  {
    $attempts--;
    if ($attempts == 0)
    {
      die("xdotool calling failed: $?");
    }
  }
}

1;
