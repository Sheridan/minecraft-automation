package Minecraft::Player::Hand;
use base Minecraft::Player::Soul;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = Minecraft::Player::Soul::new($class);
  $self->{'last_mouse_coordinates'} = { 'c'=> {'x' => 0, 'y' => 0} };
  # print Dumper $self, $class;
  return $self;
}

sub mouse_coordinates_is_changed
{
  my ($self, $current) = @_[0..1];
  return $self->{'last_mouse_coordinates'}{'c'}{'x'} != $current->{'c'}{'x'} ||
         $self->{'last_mouse_coordinates'}{'c'}{'y'} != $current->{'c'}{'y'}
}

sub mouse_move_to_cell
{
  my ($self, $to) = @_[0..1];
  #print Dumper($to);
  if($self->mouse_coordinates_is_changed($to))
  {
    $self->{'last_mouse_coordinates'}{'c'}{'x'} = $to->{'c'}{'x'};
    $self->{'last_mouse_coordinates'}{'c'}{'y'} = $to->{'c'}{'y'};
    $self->call_xdotool(sprintf('mousemove --window %%1 %d %d',
                                  $to->{'c'}{'x'},
                                  $to->{'c'}{'y'}));
    return 1;
  }
  return 0;
}

sub mouse_move_to_button
{
  my ($self, $to) = @_[0..1];
  $self->mouse_move_to_cell($to);
}

sub mouse_hide_from_interface
{
  my $self = $_[0];
  return $self->mouse_move_to_cell($main::config->{'system'}{'no-interface'});
}

sub mouse_left_click
{
  my $self = $_[0];
  $self->call_xdotool(sprintf('click --delay %d 1', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_right_click
{
  my $self = $_[0];
  $self->call_xdotool(sprintf('click --delay %d 3', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_shift_left_click
{
  my $self = $_[0];
  $self->call_xdotool(sprintf('keydown shift sleep %s click --delay %d 1 sleep %s keyup shift',
                                                 $main::config->{'user'}{'timeouts'}{'between_keypress_and_click'},
                                                 $main::config->{'user'}{'timeouts'}{'mouse_click_ms'},
                                                 $main::config->{'user'}{'timeouts'}{'between_keypress_and_click'}
                                                 ));
                                                #  print "!"; exit 0;
}

sub take_stack_from_cell
{
  my ($self, $from_cell) = @_[0..1];
  $self->mouse_move_to_cell($from_cell);
  $self->mouse_left_click();
}

sub take_half_stack_from_cell
{
  my ($self, $from_cell) = @_[0..1];
  $self->mouse_move_to_cell($from_cell);
  $self->mouse_right_click();
}

sub put_stack_to_cell
{
  my ($self, $to_cell) = @_[0..1];
  $self->take_stack_from_cell($to_cell);
}

sub put_one_item_to_cell
{
  my ($self, $to_cell) = @_[0..1];
  $self->take_half_stack_from_cell($to_cell);
}

sub move_stack_between_cells
{
  my ($self, $from_cell, $to_cell) = @_[0..2];
  $self->take_stack_from_cell($from_cell);
  $self->put_stack_to_cell($to_cell);
}

sub move_half_stack_between_cells
{
  my ($self, $from_cell, $to_cell) = @_[0..2];
  $self->take_half_stack_from_cell($from_cell);
  $self->put_stack_to_cell($to_cell);
}

sub swap_stack_between_cells
{
  my ($self, $from_cell, $to_cell) = @_[0..2];
  $self->move_stack_between_cells($from_cell, $to_cell);
  $self->put_stack_to_cell($from_cell);
}

sub drop_item_from_cell
{
  my ($self, $from_cell) = @_[0..1];
  $self->take_stack_from_cell($from_cell);
  $self->mouse_hide_from_interface();
  $self->mouse_left_click();
}

sub take_stack_to_invertory
{
  my ($self, $from_cell) = @_[0..1];
  $self->mouse_move_to_cell($from_cell);
  $self->mouse_shift_left_click();
}

sub press_button
{
  my ($self, $button) = @_[0..1];
  $self->mouse_move_to_button($button);
  $self->mouse_left_click();
}

sub use
{
  my $self = $_[0];
  $self->call_xdotool('type e');
}

sub is_empty
{
  my ($self, $interface) = @_[0..1];
  return $main::player->head()->hand_is_empty($interface);
}

sub open_interface
{
  my ($self, $interface) = @_[0..1];
  $self->mouse_right_click();
  my $attempt_check_open_interface = int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                         $main::config->{'user'}{'timeouts'}{'interface_open'}    );
  while(!$main::player->head()->interface_is_open($interface))
  {
    sleep($main::config->{'user'}{'timeouts'}{'interface_open'});
    $attempt_check_open_interface--;
    if(!$attempt_check_open_interface)
    {
      Minecraft::UserInteraction::say($main::l10n->tr('interface_not_opened'), int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                                                                   $main::config->{'user'}{'timeouts'}{'interface_open'}   ));
      exit(0);
    }
  }
}

sub close_interface
{
  my ($self, $interface) = @_[0..1];
  $self->use();
  my $attempt_check_close_interface = int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                          $main::config->{'user'}{'timeouts'}{'interface_open'}    );
  while($main::player->head()->interface_is_open($interface))
  {
    sleep($main::config->{'user'}{'timeouts'}{'interface_open'});
    $attempt_check_close_interface--;
    if(!$attempt_check_close_interface)
    {
      Minecraft::UserInteraction::say($main::l10n->tr('interface_not_closed'), int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                                                                   $main::config->{'user'}{'timeouts'}{'interface_open'}   ));
      exit(0);
    }
  }
}

1;
