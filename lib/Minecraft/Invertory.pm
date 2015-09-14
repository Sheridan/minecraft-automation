package Minecraft::Invertory;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);
use Exporter qw(import);

my $config = Minecraft::Automation::read_config();

sub map_invertory
{
    Minecraft::Automation::say("Картографирую инвертарь...");
    my $invertory = {};
    for my $y (0..3)
    {
        Minecraft::Automation::say("Строка %d", $y);
        for my $x (0..8)
        {
			$invertory->{$x}{$y} = what_item_at_coordinates('invertory', $x, $y);
        }
    }
    Minecraft::Automation::say("Инвертарь откартографирован.");
    return $invertory;
}

sub remap_empty_cells
{
	my ($invertory, $reverse) = @_[0..1];
	for my $y ($reverse?reverse(0..3):(0..3))
    {
		for my $x ($reverse?reverse(0..8):(0..8))
        {
			if($invertory->{$x}{$y} eq 'empty')
			{
				my $item = what_item_at_coordinates('invertory', $x, $y);
				if($item eq 'empty') { return; }
				$invertory->{$x}{$y} = $item;
			}
        }
    }
}

sub remap_empty_cell_in_invertory
{
	my $invertory = $_[0];
	Minecraft::Automation::say("Проверяем пустоту в инвертаре...");
	remap_empty_cells($invertory, 0);
	remap_empty_cells($invertory, 1);
}

sub what_item_at_coordinates
{
    my ($where, $x, $y) = @_[0..2];
    my $dir_h = undef;
    my $temp_item_screenshot = Minecraft::Screenshoter::take_temp_item_screenshot($config->{'system'}{$where}{$x}{$y});
    my $items_dir = sprintf("%s/items/", $config->{'user'}{'paths'}{'screenshosts'});
    opendir($dir_h, $items_dir) or die $!;
    while (my $item = readdir($dir_h)) 
    {
        next if ($item =~ m/^\./);
        if(-d $items_dir.$item)
        {
            if(Minecraft::Screenshoter::compare_screenshots(Minecraft::Screenshoter::screenshot_item_name($item, $where, $x, $y), 
                                                                                                          $temp_item_screenshot))
            {
                closedir($dir_h);
                return $item;
            }
        }
    }
    closedir($dir_h);
    return 'unknown';
}

sub take_first_item
{
	my ($item, $invertory) = @_[0..1];
	for my $y (0..3)
	{
		for my $x (0..8)
		{
			if($invertory->{$x}{$y} eq $item)
			{
				return {'x' => $x, 'y' => $y, 'exists' => 1};
			}
		}
	}
	return {'x' => 0, 'y' => 0, 'exists' => 0};
}

sub item_exists_in_invertory
{
	my ($item, $invertory) = @_[0..1];
	return take_first_item($item, $invertory)->{'exists'};
}

sub put_stack_to_trader_invertory
{
	my ($item, $trader_invertory, $invertory) = @_[0..2];
	my $item_xy = take_first_item($item, $invertory);
	$invertory->{$item_xy->{'x'}}{$item_xy->{'y'}} = 'empty';
	Minecraft::Automation::move_stack_between_cells($config->{'system'}{'invertory'}{$item_xy->{'x'}}{$item_xy->{'y'}}, 
													$config->{'system'}{'villager'}{'invertory'}{$trader_invertory});
}

sub dump_invertory
{
	my $invertory = $_[0];
	for my $y (0..3)
	{
		for my $x (0..8)
		{
			printf("[%d:%d:%s]", $x, $y, $invertory->{$x}{$y});
		}
		print "\n";
	}
	Minecraft::Automation::wait_any_key("Жду пока сверите инвертарь");
}

1;