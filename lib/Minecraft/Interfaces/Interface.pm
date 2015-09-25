package Minecraft::Interfaces::Interface;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);
use Minecraft::ItemsReader;

sub new
{
  my ($class, $interface) = @_[0..1];
  my $self =
  {
    'item_in_hand' => '',
    'interface' => $interface,
    'interface-invertory' => Minecraft::ItemsReader->new($interface, 'cells'),
    'self-invertory'      => Minecraft::ItemsReader->new($interface, 'self-invertory')
  };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub interface_invertory
{
  my $self = $_[0];
  return $self->{'interface-invertory'};
}

sub self_invertory
{
  my $self = $_[0];
  return $self->{'self-invertory'};
}

sub hand_is_empty
{
  my $self = $_[0];
  return $main::player->hand()->is_empty($self->{'interface'});
}


1;
