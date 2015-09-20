package Minecraft::Automation;

use strict;
use warnings;
use JSON;
use Data::Dumper;
use Exporter qw(import);
use Time::HiRes qw (sleep);

my $last_mouse_coordinates = { 'c'=> {'x' => 0, 'y' => 0} };
# my $is_first_xdotool_call = 1;

sub call_xdotool
{
  my $command = $_[0];
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

sub open_interface
{
  my ($name, $coordinates) = @_[0..1];
  mouse_rigt_click();
  my $attempt_check_open_interface = int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                         $main::config->{'user'}{'timeouts'}{'interface_open'}    );
  while(!Minecraft::Screenshoter::interface_is_open($name, $coordinates))
  {
    sleep($main::config->{'user'}{'timeouts'}{'interface_open'});
    $attempt_check_open_interface--;
    if(!$attempt_check_open_interface)
    {
      Minecraft::UserInteraction::say("Интерфейс так и не открылся за %d секунд", int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                                                                      $main::config->{'user'}{'timeouts'}{'interface_open'}   ));
      exit(0);
    }
  }
}

sub close_interface
{
  my ($name, $coordinates) = @_[0..1];
  use_e();
  my $attempt_check_close_interface = int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                          $main::config->{'user'}{'timeouts'}{'interface_open'}    );
  while(Minecraft::Screenshoter::interface_is_open($name, $coordinates))
  {
    sleep($main::config->{'user'}{'timeouts'}{'interface_open'});
    $attempt_check_close_interface--;
    if(!$attempt_check_close_interface)
    {
      Minecraft::UserInteraction::say("Интерфейс так и не закрылся за %d секунд", int($main::config->{'user'}{'timeouts'}{'max_interface_open'}/
                                                                                      $main::config->{'user'}{'timeouts'}{'interface_open'}   ));
      exit(0);
    }
  }
}

sub use_e
{
  call_xdotool('key e');
}

sub mouse_move_to_cell
{
    my $to = $_[0];
    #print Dumper($to);
    if($last_mouse_coordinates->{'c'}{'x'} != $to->{'c'}{'x'} ||
       $last_mouse_coordinates->{'c'}{'y'} != $to->{'c'}{'y'})
  {
    $last_mouse_coordinates->{'c'}{'x'} = $to->{'c'}{'x'};
    $last_mouse_coordinates->{'c'}{'y'} = $to->{'c'}{'y'};
    call_xdotool(sprintf('mousemove --window %%1 %d %d',
            $to->{'c'}{'x'},
            $to->{'c'}{'y'}));
    return 1;
  }
  return 0;
}

sub mouse_move_to_button
{
    mouse_move_to_cell($_[0]);
}

sub mouse_hide_from_interface
{
  return mouse_move_to_cell($main::config->{'system'}{'no-interface'});
}

sub mouse_left_click
{
    call_xdotool(sprintf('click --delay %d 1', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_rigt_click
{
    call_xdotool(sprintf('click --delay %d 3', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_shift_left_click
{
    call_xdotool(sprintf('keydown shift sleep 0.1 click --delay %d 1 sleep 0.2 keyup shift sleep 0.1',
                                                 $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub turn_user
{
  my ($hor, $ver) = @_[0..1];
  call_xdotool(sprintf('mousemove_relative --sync %s %d %d', $hor < 0 || $ver < 0 ? "--" : "", $hor, $ver));
  sleep($main::config->{'user'}{'timeouts'}{'after_turn'});
}

sub turn_user_horizontal_points
{
  my $hor = $_[0];
  turn_user($hor, 0);
}

sub turn_user_vertical_points
{
  my $ver = $_[0];
  turn_user(0, $ver);
}

sub turn_user_horizontal_deg
{
  my $hor = $_[0];
  turn_user_horizontal_points(int($main::config->{'system'}{'turn'}{'horizontal'} * $hor));
}

sub turn_user_vertical_deg
{
  my $ver = $_[0];
  turn_user_vertical_points(int($main::config->{'system'}{'turn'}{'vertical'} * $ver));
}

sub turn_user_up_deg
{
  my $value = $_[0];
  turn_user_vertical_deg(0-$value);
}

sub turn_user_down_deg
{
  my $value = $_[0];
  turn_user_vertical_deg($value);
}

sub turn_user_left_deg
{
  my $value = $_[0];
  turn_user_horizontal_deg(0-$value);
}

sub turn_user_right_deg
{
  my $value = $_[0];
  turn_user_horizontal_deg($value);
}

sub take_stack_from_cell
{
    my ($from_cell) = $_[0];
    mouse_move_to_cell($from_cell);
    mouse_left_click();
}

sub take_half_stack_from_cell
{
    my ($from_cell) = $_[0];
    mouse_move_to_cell($from_cell);
    mouse_rigt_click();
}

sub put_stack_to_cell
{
    my ($to_cell) = $_[0];
    take_stack_from_cell($to_cell);
}

sub move_stack_between_cells
{
    my ($from_cell, $to_cell) = @_[0..1];
    take_stack_from_cell($from_cell);
    put_stack_to_cell($to_cell);
}

sub move_half_stack_between_cells
{
    my ($from_cell, $to_cell) = @_[0..1];
    take_half_stack_from_cell($from_cell);
    put_stack_to_cell($to_cell);
}

sub swap_stack_between_cells
{
    my ($from_cell, $to_cell) = @_[0..1];
    move_stack_between_cells($from_cell, $to_cell);
    put_stack_to_cell($from_cell);
}

sub drop_item_from_cell
{
    my ($from_cell) = $_[0];
    take_stack_from_cell($from_cell);
    mouse_hide_from_interface();
    mouse_left_click();
}

sub take_stack_to_invertory
{
    my ($from_cell) = $_[0];
    mouse_move_to_cell($from_cell);
    mouse_shift_left_click();
}



1;
