package Minecraft::Automation;

use strict;
use warnings;
use JSON;
use Data::Dumper;
use Exporter qw(import);
use Time::HiRes qw (sleep);

my $last_mouse_coordinates = { 'c'=> {'x' => 0, 'y' => 0} };


sub mouse_move_to_cell
{
    my $to = $_[0];
    if($last_mouse_coordinates->{'c'}{'x'} != $to->{'c'}{'x'} ||
	   $last_mouse_coordinates->{'c'}{'y'} != $to->{'c'}{'y'})
	{
		system(sprintf('xdotool search --name "%s" windowactivate --sync mousemove --window %%1 %d %d', 
						$main::config->{'user'}{'minecraft'}{'title'}, 
						$to->{'c'}{'x'}, 
						$to->{'c'}{'y'}));
		return 1;
		$last_mouse_coordinates->{'c'}{'x'} = $to->{'c'}{'x'};
		$last_mouse_coordinates->{'c'}{'y'} = $to->{'c'}{'y'};
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
    system(sprintf('xdotool click --delay %d 1', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_rigt_click
{
    system(sprintf('xdotool click --delay %d 3', $main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
}

sub mouse_shift_left_click
{
    system(sprintf('xdotool keydown shift sleep 0.1 click --delay %d 1 sleep 0.2 keyup shift sleep 0.1', 
					$main::config->{'user'}{'timeouts'}{'mouse_click_ms'}));
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