package Minecraft::Interfaces::Crafttable;

use strict;
use warnings;
use Data::Dumper;
use Minecraft::Screenshoter;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self =
  {
    'crafttable'     => Minecraft::ItemsReader->new('crafttable', 'cells'),
    'self-invertory' => Minecraft::ItemsReader->new('crafttable', 'self-invertory')
  };
  bless($self, $class);
  return $self;
}

sub take_all_craft_result
{
  my $self = $_[0];
  Minecraft::Automation::take_stack_to_invertory($main::config->{'system'}{'crafttable'}{'result'});
  $self->{'crafttable'}->map_cells();
  $self->{'self-invertory'}->map_cells();
}

sub put_item
{
  my ($self, $item, $x, $y) = @_[0..3];
  $self->add_item_to_items_to_find($item);
  Minecraft::ItemsReader::put_item($self, $item, $x, $y);
}

sub hand_is_empty
{
  return Minecraft::Screenshoter::hand_is_empty('crafttable');
}

sub crafttable
{
  my $self = $_[0];
  return $self->{'crafttable'};
}

sub self_invertory
{
  my $self = $_[0];
  return $self->{'self-invertory'};
}

sub add_item_to_items_to_find
{
  my ($self, $item) = @_[0..1];
  $self->{'self-invertory'}->add_item_to_items_to_find($item);
  $self->{'crafttable'}->add_item_to_items_to_find($item);
}

1;
