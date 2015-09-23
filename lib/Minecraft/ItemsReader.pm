package Minecraft::ItemsReader;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);

sub new
{
  my ($class, $interface, $interface_target) = @_[0..2];
  my $self =
  {
    'data' => {},
    'items_to_find' =>
    {
      'empty' => 1
    },
    'interface' => $interface,
    'interface_target' => $interface_target,
    'dimension' =>
    {
      'x' => scalar(keys(%{$main::config->{'system'}{$interface}{$interface_target}}))-1,
      'y' => scalar(keys(%{$main::config->{'system'}{$interface}{$interface_target}{0}}))-1
    }
  };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub add_item_to_items_to_find
{
  my ($self, $item_to_find) = @_[0..1];
  $self->{'items_to_find'}{$item_to_find} = 1;
}

sub add_items_to_items_to_find
{
  my ($self, $items_to_find) = @_[0..1];
  for my $item_to_find (keys(%{$items_to_find}))
  {
    add_item_to_items_to_find($self, $item_to_find);
  }
}

sub delete_item_from_items_to_find
{
  my ($self, $item_to_find) = @_[0..1];
  if($item_to_find eq 'empty') { return; }
  delete($self->{'items_to_find'}{$item_to_find});
}

sub delete_items_from_items_to_find
{
  my ($self, $items_to_find) = @_[0..1];
  for my $item_to_find (keys(%{$items_to_find}))
  {
    delete_item_from_items_to_find($self, $item_to_find);
  }
}

sub add_item_to_data
{
  my ($self, $item, $x, $y) = @_[0..3];
  $self->{'data'}{$x}{$y} = $item;
  if(exists($self->{'items-count'}{$item}))
  {
    $self->{'items-count'}{$item}++;
  }
  else
  {
    $self->{'items-count'}{$item} = 1;
  }
}

sub remove_item_from_data
{
  my ($self, $item, $x, $y) = @_[0..3];
  $self->{'data'}{$x}{$y} = 'empty';
  $self->{'items-count'}{$item}--;
}

sub map_cells
{
  my $self = $_[0];
  Minecraft::UserInteraction::say("Картографирую инвертарь...");
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      my $item = what_item_at_coordinates($self, $x, $y);
      add_item_to_data($self, $item, $x, $y);
      printf("[%s]", $self->{'data'}{$x}{$y});
    }
    print ("\n");
  }
  Minecraft::UserInteraction::say("Инвертарь откартографирован.");
}

sub remap_empty_cells
{
  my ($self, $reverse) = @_[0..1];
  for my $y ($reverse?reverse(0..$self->{'dimension'}{'y'}):(0..$self->{'dimension'}{'y'}))
  {
    for my $x ($reverse?reverse(0..$self->{'dimension'}{'x'}):(0..$self->{'dimension'}{'x'}))
    {
      if($self->{'data'}{$x}{$y} eq 'empty')
      {
        my $item = what_item_at_coordinates($self, $x, $y);
        if($item eq 'empty') { return; }
        add_item_to_data($self, $item, $x, $y);
      }
    }
  }
}

sub remap_empty_cell_in_invertory
{
  my $self = $_[0];
  #Minecraft::UserInteraction::say("Проверяем пустоту в инвертаре...");
  remap_empty_cells($self, 0);
  remap_empty_cells($self, 1);
}

sub what_item_at_coordinates
{
  my ($self, $x, $y) = @_[0..2];
  my $dir_h = undef;
  my $temp_item_screenshot = Minecraft::Screenshoter::take_temp_item_screenshot($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$x}{$y});
  my $items_dir = sprintf("%s/%s/items/", $main::config->{'user'}{'paths'}{'screenshosts'}, $main::config->{'user'}{'minecraft'}{'texture_pack'});
  opendir($dir_h, $items_dir) or die $!;
  while (my $item = readdir($dir_h))
  {
    next if ($item =~ m/^\./);
    if(-d $items_dir.$item && (exists($self->{'items_to_find'}{$item}) || scalar(keys(%{$self->{'items_to_find'}})) == 1))
    {
      if(Minecraft::Screenshoter::compare_screenshots(Minecraft::Screenshoter::screenshot_item_name($item, $self->{'interface'}, $self->{'interface_target'}, $x, $y),
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

sub get_first_item_coordinates
{
  my ($self, $item) = @_[0..1];
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      if($self->{'data'}{$x}{$y} eq $item)
      {
        return {'x' => $x, 'y' => $y};
      }
    }
  }
  return {'x' => -1, 'y' => -1};
}

sub item_exists
{
  my ($self, $item) = @_[0..1];
  return get_first_item_coordinates($self, $item)->{'x'} != -1;
}

sub take_item
{
  my ($self, $item) = @_[0..1];
  my $coordinates = get_first_item_coordinates($self, $item);
  remove_item_from_data($self, $item, $coordinates->{'x'}, $coordinates->{'y'});
  Minecraft::Automation::mouse_move_to_cell($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$coordinates->{'x'}}{$coordinates->{'y'}});
  Minecraft::Automation::mouse_left_click();
}

sub put_item
{
  my ($self, $item, $x, $y) = @_[0..3];
  add_item_to_data($self, $item, $x, $y);
  Minecraft::Automation::mouse_move_to_cell($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$x}{$y});
  Minecraft::Automation::mouse_left_click();
}

sub dump
{
  my $self = $_[0];
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      printf("[%d:%d:%s]", $x, $y, $self->{'data'}{$x}{$y});
    }
    print "\n";
  }
  #Minecraft::UserInteraction::wait_press_enter("Жду пока сверите инвертарь");
}

1;
