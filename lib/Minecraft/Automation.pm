package Minecraft::Automation;

use strict;
use warnings;
use JSON;
use Data::Dumper;
use Exporter qw(import);
use Time::HiRes qw (sleep);

my $config = Minecraft::Automation::read_config();

sub read_config
{
    return {
                'user'   => read_config_file('user-config.json'),
                'system' => -e 'system-config.json' ? read_config_file('system-config.json') : {}
            };
}

sub read_config_file
{
    my $file_name = $_[0];
    local $/;
    open( my $fh, '<', $file_name );
    my $json_text   = <$fh>;
    my $perl_scalar = decode_json( $json_text );
    close($fh);
    return $perl_scalar;
}

sub save_system_config
{
    my $config = $_[0];
    open( my $fh, '>', 'system-config.json' );
    print {$fh} encode_json( $config->{'system'} );
    close($fh);
    return read_config();
}

sub say
{
    my $format = shift;
    my @variables = @_;
    printf($format."\n", @variables);
}

sub wait_any_key
{
    my $text = $_[0];
    say($text.". Нажмите тут enter...");
    <STDIN>;
}

sub mouse_move_to_cell
{
    my $to = $_[0];
    system(sprintf('xdotool search --name "%s" windowactivate --sync mousemove --window %%1 %d %d', $config->{'user'}{'minecraft'}{'title'}, $to->{'c'}{'x'}, $to->{'c'}{'y'}));
}

sub mouse_move_to_button
{
    mouse_move_to_cell($_[0]);
}

sub mouse_hide_from_interface
{
    mouse_move_to_cell({ 'c' => {'x' => 10, 'y' => 10 } });
}

sub mouse_left_click
{
    system('xdotool click --delay 100 1');
}

sub mouse_rigt_click
{
    system('xdotool click --delay 100 3');
}

sub mouse_shift_left_click
{
    system('xdotool keydown shift sleep 0.1 click --delay 100 1 sleep 0.2 keyup shift sleep 0.1');
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

sub move_stack_from_craft_result
{
    take_stack_to_invertory($config->{'system'}{'crafttable'}{'result'});
}

sub move_stack_from_trade_result
{
    take_stack_to_invertory($config->{'system'}{'villager'}{'result'});
}

1;