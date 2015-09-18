package Minecraft::Screenshoter;

use strict;
use warnings;
use Data::Dumper;
use Digest::MD5::File qw(file_md5_base64); 
use Time::HiRes qw (sleep);
use Exporter qw(import);

my $md5_cache = {};

sub get_window_size_position
{
  my $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Position | awk \'{print $2}\'', $main::config->{'user'}{'minecraft'}{'title'});
  my @pos = split(/,/, `$cmd`);
  $cmd = sprintf('xdotool search --name "%s" getwindowgeometry | grep Geometry | awk \'{print $2}\'', $main::config->{'user'}{'minecraft'}{'title'});
  my @geo = split(/x/, `$cmd`);
  $main::config->{'system'}{'window'}{'geometry'} = { 'x' => $pos[0]+0, 'y' => $pos[1]+0, 'w' => $geo[0]+0, 'h' => $geo[1]+0 };
}

sub screenshot_full_filename
{
  my $name = $_[0];
  return sprintf("%s/%s/%s.bmp", $main::config->{'user'}{'paths'}{'screenshosts'}, $main::config->{'user'}{'minecraft'}{'texture_pack'}, $name);
}

sub screenshot_item_name
{
  my ($item, $where, $x, $y) = @_[0..3];
  return sprintf("items/%s/%s-%d-%d", $item, $where, $x, $y);
}

sub take_screenshot
{ 
  my ($filename, $coordinates, $clean) = @_[0..2];
  if($clean && Minecraft::Automation::mouse_hide_from_interface())
  {
    sleep($main::config->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'});
  }
  system(sprintf('import -silent -window "%s" -crop %dx%d+%d+%d %s', 
    $main::config->{'user'}{'minecraft'}{'title'}, 
    $coordinates->{'br'}{'x'} - $coordinates->{'tl'}{'x'}, 
    $coordinates->{'br'}{'y'} - $coordinates->{'tl'}{'y'}, 
    $coordinates->{'tl'}{'x'},
    $coordinates->{'tl'}{'y'},
    screenshot_full_filename($filename)));
  return $filename;
}

sub take_temp_screenshot
{
  my ($coordinates, $clean) = @_[0..1];
  return take_screenshot('temporally', $coordinates, $clean);
}

sub convert_cell_to_item_coordinates
{
  my $coordinates = $_[0];
  my $dx = int(($coordinates->{'br'}{'x'} - $coordinates->{'tl'}{'x'})/4);
  my $dy = int(($coordinates->{'br'}{'y'} - $coordinates->{'tl'}{'y'})/3);
  return {
      'tl' => 
      {
        'x' => $coordinates->{'tl'}{'x'}+$dx,
        'y' => $coordinates->{'tl'}{'y'}+$dy
      },
      'br' => 
      {
        'x' => $coordinates->{'br'}{'x'}-$dx,
        'y' => $coordinates->{'br'}{'y'}-$dy
      }
    };
}

sub take_item_screenshot
{
  my ($item, $where, $x, $y, $coordinates) = @_[0..4];
  my $filename = sprintf("items/%s/%s-%d-%d", $item, $where, $x, $y);
  return take_screenshot($filename, convert_cell_to_item_coordinates($coordinates), 1);
}

sub take_temp_item_screenshot
{
  my $coordinates = $_[0];
  return take_screenshot('temporally', convert_cell_to_item_coordinates($coordinates), 1);
}

sub hand_is_empty
{
  my $interface = $_[0];
  Minecraft::Automation::mouse_move_to_cell($main::config->{'system'}{$interface}{'clean'});
  sleep($main::config->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'});
  my $ssname = take_screenshot('temporally', $main::config->{'system'}{$interface}{'clean'}, 0);
  return compare_screenshots($ssname, sprintf("dont-delete-%s-clean", $interface));
}

sub compare_screenshots
{
    my ($f0, $f1) = @_[0..1];
    #print sprintf("%s == %s : %s\n",file_md5_base64($f0), file_md5_base64($f1) ,file_md5_base64($f0) eq file_md5_base64($f1));
    return get_md5($f0) eq get_md5($f1);
}

sub compare_screenshots_no_cache
{
  my ($f0, $f1) = @_[0..1];
  return file_md5_base64(screenshot_full_filename($f0)) eq file_md5_base64(screenshot_full_filename($f1));
}

sub get_md5
{
  my $name = $_[0];
  if($name eq 'temporally') 
  { 
    #Minecraft::UserInteraction::say("Считаю md5 от временного файла...");
    return file_md5_base64(screenshot_full_filename($name)); 
  }
  if(!exists($md5_cache->{$name}))
  {
    $md5_cache->{$name} = file_md5_base64(screenshot_full_filename($name));
    #Minecraft::UserInteraction::say("Новый хэш md5 в кэше: [%s:%s]", $name, $md5_cache->{$name});
  }
  return $md5_cache->{$name};
}

sub interface_is_open
{
  my ($name, $coordinates) = @_[0..1];
  return compare_screenshots(sprintf("dont-delete-%s-is-open", $name), take_temp_screenshot($coordinates));
}

1;