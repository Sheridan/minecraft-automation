package Minecraft::ItemsReader;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);
use Digest::MD5 qw(md5_hex);

sub new
{
  my ($class, $interface, $interface_target) = @_[0..2];
  my $self =
  {
    'data' => {},
    'states' => {},
    'items-count' => {},
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
    $self->add_item_to_items_to_find($item_to_find);
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
    $self->delete_item_from_items_to_find($item_to_find);
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
  my ($self, $x, $y) = @_[0..2];
  #printf("%s => empty\n", $self->{'data'}{$x}{$y});
  $self->{'items-count'}{$self->{'data'}{$x}{$y}}--;
  $self->add_item_to_data('empty', $x, $y);
}

sub empty_count
{
  my ($self) = $_[0];
  return $self->items_count('empty');
}

sub items_count
{
  my ($self, $item) = @_[0..1];
  if($item eq 'any-plank')
  {
    return $self->items_count('dark-oak-plank') +
           $self->items_count('spruce-plank') +
           $self->items_count('jungle-plank') +
           $self->items_count('oak-plank') +
           $self->items_count('acacia-plank') +
           $self->items_count('birch-plank');
  }
  return exists($self->{'items-count'}{$item}) ? $self->{'items-count'}{$item} : 0;
}

sub empty
{
  my $self = $_[0];
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      $self->add_item_to_data('empty', $x, $y);
    }
  }
}


sub map_cells
{
  my $self = $_[0];
  delete($self->{'items-count'});
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      $self->add_item_to_data($self->what_item_at_coordinates($x, $y), $x, $y);
    }
  }
#   $self->dump();
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
        my $item = $self->what_item_at_coordinates($x, $y);
        if($item eq 'empty') { return; }
        $self->add_item_to_data($item, $x, $y);
      }
    }
  }
}

sub remap
{
  my $self = $_[0];
  #Minecraft::UserInteraction::say("Проверяем пустоту в инвертаре...");
  $self->remap_empty_cells(0);
  $self->remap_empty_cells(1);
  #print ("\n");
#   $self->dump();
}

sub what_item_at_coordinates
{
  my ($self, $x, $y) = @_[0..2];
  my $dir_h = undef;
  my $temp_item_screenshot = $main::player->head()->take_temp_item_screenshot($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$x}{$y});
  my $items_dir = sprintf("%s/%s/items/", $main::config->{'user'}{'paths'}{'screenshosts'}, $main::config->{'user'}{'minecraft'}{'texture_pack'});
  opendir($dir_h, $items_dir) or die $!;
  while (my $item = readdir($dir_h))
  {
    next if ($item =~ m/^\./);
    if(
        -d $items_dir.$item &&
        (
          (exists($self->{'items_to_find'}{$item}) || scalar(keys(%{$self->{'items_to_find'}})) == 1) ||
          (exists($self->{'items_to_find'}{'any-plank'}) && $item=~/-plank/) ||
          (exists($self->{'items_to_find'}{'any-wood-slab'}) && $item=~/-slab/)
        )
      )
    {
      if($main::player->head()->compare_screenshots(
                  $main::player->head()->screenshot_full_filename($main::player->head()->screenshot_item_name($item, $self->{'interface'}, $self->{'interface_target'}, $x, $y)),
                  $temp_item_screenshot))
      {
        closedir($dir_h);
        # print $self->{'interface_target'}."->".$item."\n";
        return $item;
      }
      else
      {
        # print $self->{'interface_target'}." ".$item."\n";
      }
    }
  }
  closedir($dir_h);
  # print $self->{'interface_target'}." ---------------------------\n";
  return 'unknown';
}

sub get_first_item_coordinates
{
  my ($self, $item) = @_[0..1];
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      if(
          ($self->{'data'}{$x}{$y} eq $item) ||
          ($item eq 'any-plank' && $self->{'data'}{$x}{$y} =~ /plank/)
        )
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
  return $self->get_first_item_coordinates($item)->{'x'} != -1;
}

sub take_stack_of_items
{
  my ($self, $item) = @_[0..1];
  my $coordinates = $self->get_first_item_coordinates($item);
  $self->remove_item_from_data($coordinates->{'x'}, $coordinates->{'y'});
  $main::player->hand()->take_stack_from_cell($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$coordinates->{'x'}}{$coordinates->{'y'}});
  return $coordinates;
}

sub put_stack_of_items
{
  my ($self, $item, $x, $y) = @_[0..3];
  add_item_to_data($self, $item, $x, $y);
  $main::player->hand()->put_stack_to_cell($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$x}{$y});
}

sub put_one_item
{
  my ($self, $item, $x, $y) = @_[0..3];
  add_item_to_data($self, $item, $x, $y);
  $main::player->hand()->put_one_item_to_cell($main::config->{'system'}{$self->{'interface'}}{$self->{'interface_target'}}{$x}{$y});
}

sub save_state
{
  my ($self, $state_name) = @_[0..1];
  $self->{'states'}{$state_name} = md5_hex(Dumper($self->{'data'}));
}

sub state_is_unchanged
{
  my ($self, $state_name) = @_[0..1];
  return $self->{'states'}{$state_name} eq md5_hex(Dumper($self->{'data'}));
}

sub dump
{
  my $self = $_[0];
  print "Inventory:\n";
  for my $y (0..$self->{'dimension'}{'y'})
  {
    for my $x (0..$self->{'dimension'}{'x'})
    {
      printf("[%d:%d:%s]", $x, $y, $self->{'data'}{$x}{$y});
    }
    print "\nItenms to find:\n";
  }
  for my $itf (keys(%{$self->{'items_to_find'}}))
  {
    printf("[%s]", $itf);
  }
  print "\n";
  #Minecraft::UserInteraction::wait_press_enter("Жду пока сверите инвертарь");
}

1;
