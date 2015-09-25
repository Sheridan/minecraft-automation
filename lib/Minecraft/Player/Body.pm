package Minecraft::Player::Body;
use base Minecraft::Player::Soul;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = Minecraft::Player::Soul::new($class);
  $self->{'turn_steps'} = 7;
  # print Dumper $self, $class;
  return $self;
}

sub turn
{
  my ($self, $hor, $ver) = @_[0..2];
  if(($hor != 0 && abs($hor) <= $self->{'turn_steps'}) || ($ver != 0 && abs($ver) <= $self->{'turn_steps'}))
  {
    $self->call_xdotool(sprintf('mousemove_relative --sync %s %d %d', $hor < 0 || $ver < 0 ? "--" : "", $hor, $ver));
  }
  for (0..$self->{'turn_steps'})
  {
    $self->call_xdotool(sprintf('mousemove_relative --sync %s %d %d', $hor < 0 || $ver < 0 ? "--" : "", $hor/$self->{'turn_steps'}, $ver/$self->{'turn_steps'}));
  }
  sleep($main::config->{'user'}{'timeouts'}{'after_turn'});
}

sub turn_horizontal_points
{
  my ($self, $hor) = @_[0..1];
  $self->turn($hor, 0);
}

sub turn_vertical_points
{
  my ($self, $ver) = @_[0..1];
  $self->turn(0, $ver);
}

sub turn_horizontal_deg
{
  my ($self, $hor) = @_[0..1];
  $self->turn_horizontal_points(int($main::config->{'system'}{'turn'}{'horizontal'} * $hor));
}

sub turn_vertical_deg
{
  my ($self, $ver) = @_[0..1];
  $self->turn_vertical_points(int($main::config->{'system'}{'turn'}{'vertical'} * $ver));
}

sub turn_up_deg
{
  my ($self, $value) = @_[0..1];
  $self->turn_vertical_deg(0-$value);
}

sub turn_down_deg
{
  my ($self, $value) = @_[0..1];
  $self->turn_vertical_deg($value);
}

sub turn_left_deg
{
  my ($self, $value) = @_[0..1];
  $self->turn_horizontal_deg(0-$value);
}

sub turn_right_deg
{
  my ($self, $value) = @_[0..1];
  $self->turn_horizontal_deg($value);
}


1;
