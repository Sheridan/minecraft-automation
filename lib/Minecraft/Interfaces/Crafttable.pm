package Minecraft::Interfaces::Crafttable;
use base Minecraft::Interfaces::Interface;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = Minecraft::Interfaces::Interface::new($class, 'crafttable');
  return $self;
}

sub take_all_craft_result
{
  my $self = $_[0];
  $main::player->hand()->take_stack_to_invertory($main::config->{'system'}{'crafttable'}{'result'});
  $self->interface_invertory()->map_cells(); 
  $self->self_invertory()->remap();
}

sub put_item
{
  my ($self, $item, $x, $y) = @_[0..3];
  $self->add_item_to_items_to_find($item);
  Minecraft::ItemsReader::put_item($self, $item, $x, $y);
}

sub crafttable
{
  my $self = $_[0];
  return $self->interface_invertory();
}

sub add_item_to_items_to_find
{
  my ($self, $item) = @_[0..1];
  $self->self_invertory()->add_item_to_items_to_find($item);
  $self->interface_invertory()->add_item_to_items_to_find($item);
}

1;
