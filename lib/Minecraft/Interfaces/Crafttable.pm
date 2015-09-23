package Minecraft::Interfaces::Crafttable;
use base Minecraft::ItemsReader;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = Minecraft::ItemsReader::new($class, 'crafttable', 'cells');
  return $self;
}

sub take_all_craft_result
{
  my $self = $_[0];
  Minecraft::Automation::take_stack_to_invertory($main::config->{'system'}{'crafttable'}{'result'});
  $self->map_cells();
}

sub put_item
{
  my ($self, $item, $x, $y) = @_[0..3];
  $self->add_item_to_items_to_find($item);
  Minecraft::ItemsReader::put_item($self, $item, $x, $y);
}

1;