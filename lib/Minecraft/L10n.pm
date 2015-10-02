package Minecraft::L10n;

use strict;
use warnings;
use Data::Dumper;
use Minecraft::FileIO;

sub new
{
  my ($class) = $_[0];
  my $self =
  {
    'l10n' => Minecraft::FileIO::read_json_file("config/l10n.json")
  };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub tr
{
  my ($self, $phrase) = @_[0..1];
  return exists($self->{'l10n'}{$phrase}{$main::config->{'user'}{'l10n'}{'language'}})
    ?
    (
      ref($self->{'l10n'}{$phrase}{$main::config->{'user'}{'l10n'}{'language'}}) eq "ARRAY" ?
      join("\n", @{$self->{'l10n'}{$phrase}{$main::config->{'user'}{'l10n'}{'language'}}})."\n" :
      $self->{'l10n'}{$phrase}{$main::config->{'user'}{'l10n'}{'language'}})
    : $phrase;
}

1;
