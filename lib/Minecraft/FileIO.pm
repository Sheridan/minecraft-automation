package Minecraft::FileIO;

use strict;
use warnings;
use JSON;
use Data::Dumper;
use File::Basename;
use Exporter qw(import);
use Time::HiRes qw (sleep);

sub read_item
{
  my $item = $_[0];
  return read_item_file( sprintf("config/items/%s.item", $item));
}

sub read_item_file
{
  my $file_name = $_[0];
  open(my $fh, '<', $file_name) or die $!;
  my $result = {'name' => basename($file_name, '.item')};
  my $is_reciept = 0;
  my $reciept_number = 0;
  my $crafttable_row = 0;
  while (my $line = <$fh>)
  {
    chomp $line;
    if(substr($line, 0, 1) eq '#') { next; }
    if(!$is_reciept)
    {
      my @option = split(/:/, $line);
      if($option[0] eq 'craft-reciepts')
      {
        $is_reciept = 1;
      }
      if($option[0] eq 'result')
      {
        $is_reciept = 1;
        if($option[1] eq 'one')
        {
          $result->{'reciepts'}{$reciept_number}{'result'}{'units'} = 'one';
        }
        else
        {
          my @reciept_result = split(/,/, $option[1]);
          $result->{'reciepts'}{$reciept_number}{'result'}{'units'} = 'stack';
          $result->{'reciepts'}{$reciept_number}{'result'}{'quantity'} = $reciept_result[1];
        }
        $reciept_number++;
        next;
      }
      $result->{$option[0]} = $option[1];
    }
    else
    {
      my @crafttable_items = split(/,/, $line);
      for my $x (0..2)
      {
        my $crafttable_item = trim($crafttable_items[$x]);
        $result->{'reciepts'}{$reciept_number}{'crafttable'}{$x}{$crafttable_row} = $crafttable_item;
        if($crafttable_item ne 'empty')
        {
          if(exists($result->{'reciepts'}{$reciept_number}{'ingridients'}{$crafttable_item}))
          {
            $result->{'reciepts'}{$reciept_number}{'ingridients'}{$crafttable_item}++;
          }
          else
          {
            $result->{'reciepts'}{$reciept_number}{'ingridients'}{$crafttable_item} = 1;
          }
        }
      }
      $crafttable_row++;
      if($crafttable_row > 2)
      {
        $is_reciept = 0;
        $crafttable_row = 0;
      }
    }
  }
  close($fh);
  return $result;
}

sub read_trader_file
{
  my $file_name = $_[0];
  open(my $fh, '<', $file_name) or die $!;
  my $row = 0;
  my $result = {'name' => basename($file_name, '.trader')};
  while (my $line = <$fh>)
  {
    chomp $line;
    if(substr($line, 0, 1) eq '#') { next; }
    for my $data (split(/,/, $line))
    {
      my @page = split(/:/, trim($data));
      $result->{$row>0?'buy':'sell'}{trim($page[0])} = trim($page[1]);
    }
    $row++;
  }
  close($fh);
  #print Dumper($result);
  return $result;
}

sub read_csv_file
{
  my $file_name = $_[0];
  open(my $fh, '<', $file_name) or die $!;
  my $row = 0;
  my $result = {};
  while (my $line = <$fh>)
  {
    chomp $line;
    if(substr($line, 0, 1) eq '#') { next; }
    my $column = 0;
    for my $data (split(/,/, $line))
    {
      $result->{$column}{$row} = trim($data);
      #print $data."\n";
      $column++;
    }
    $row++;
  }
  close($fh);
  #print Dumper($result);
  return $result;
}

# --------------------------------- проверки на существование -----------------------

sub item_description_exists
{
  my $item_name = $_[0];
  return -e sprintf("config/items/%s.item", $item_name);
}

# ---------------------------------  списки файлов ---------------------------------

sub get_files_list
{
  my ($path, $extention) = @_[0..1];
  opendir(my $dir_h, $path) or die $!;
  my @files = map { $path.$_} grep(/\.$extention$/, readdir($dir_h));
  closedir($dir_h);
  return @files;
}

sub get_train_chests
{
  return get_files_list('config/big-chests-for-train/', 'csv');
}

sub get_traders
{
  return get_files_list('config/traders/', 'trader');
}

sub get_items
{
  return get_files_list('config/items/', 'item');
}

# ---------------------------------  конфиг ---------------------------------

sub read_json_file
{
  my $file_name = $_[0];
  local $/;
  open( my $fh, '<', $file_name ) or die $!;
  my $result = from_json(<$fh>, {utf8 => 1});
  close($fh);
  return $result;
}

sub read_config_file
{
  my $file_name = $_[0];
  return read_json_file($file_name);
}

sub save_system_config
{
  my $config = $_[0];
  open( my $fh, '>', 'config/system-config.json' );
  print {$fh} to_json($config->{'system'}, {utf8 => 1, pretty => 1});
  close($fh);
  return read_config();
}

sub save_user_config
{
  my $config = $_[0];
  open( my $fh, '>', 'config/user-config.json' );
  print {$fh} to_json($config->{'user'}, {utf8 => 1, pretty => 1});
  close($fh);
  return read_config();
}

sub read_config
{
  my $c =
    {
        'user'   => -e 'config/user-config.json'   ? read_config_file('config/user-config.json'  ) : {},
        'system' => -e 'config/system-config.json' ? read_config_file('config/system-config.json') : {}
    };
  if(!exists($c->{'user'}{'paths'}{'temp'}))                                 { $c->{'user'}{'paths'}{'temp'} = '/tmp'; }
  if(!exists($c->{'user'}{'paths'}{'screenshosts'}))                         { $c->{'user'}{'paths'}{'screenshosts'} = './screenshots'; }
  if(!exists($c->{'user'}{'minecraft'}{'texture_pack'}))                     { $c->{'user'}{'minecraft'}{'texture_pack'} = "default"; }
  if(!exists($c->{'user'}{'minecraft'}{'title'}))                            { $c->{'user'}{'minecraft'}{'title'} = 'Minecraft 1.8.8'; }
  if(!exists($c->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'})) { $c->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'} = 0.1; }
  if(!exists($c->{'user'}{'timeouts'}{'villager_upgrade'}))                  { $c->{'user'}{'timeouts'}{'villager_upgrade'} = 5; }
  if(!exists($c->{'user'}{'timeouts'}{'interface_open'}))                    { $c->{'user'}{'timeouts'}{'interface_open'} = 1; }
  if(!exists($c->{'user'}{'timeouts'}{'max_interface_open'}))                { $c->{'user'}{'timeouts'}{'max_interface_open'} = 15; }
  if(!exists($c->{'user'}{'timeouts'}{'mouse_click_ms'}))                    { $c->{'user'}{'timeouts'}{'mouse_click_ms'} = 100; }
  if(!exists($c->{'user'}{'timeouts'}{'after_turn'}))                        { $c->{'user'}{'timeouts'}{'after_turn'} = 0.5; }
  if(!exists($c->{'user'}{'timeouts'}{'villager_page_switch'}))              { $c->{'user'}{'timeouts'}{'villager_page_switch'} = 0.1; }

  return $c;
}

# ---------------------------------  всякие мелочи ---------------------------------
sub trim
{
  my $s = shift;
  $s =~ s/^\s+|\s+$//g;
  return $s;
}

1;
