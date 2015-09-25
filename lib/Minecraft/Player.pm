package Minecraft::Player;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);
use Minecraft::Player::Head;
use Minecraft::Player::Hand;
use Minecraft::Player::Body;

sub new
{
  my ($class) = $_[0];
  my $self =
  {
    'head' => Minecraft::Player::Head->new(),
    'hand' => Minecraft::Player::Hand->new(),
    'body' => Minecraft::Player::Body->new()
  };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub head
{
  my $self = $_[0];
  return $self->{'head'};
}

sub hand
{
  my $self = $_[0];
  return $self->{'hand'};
}

sub body
{
  my $self = $_[0];
  return $self->{'body'};
}

1;
