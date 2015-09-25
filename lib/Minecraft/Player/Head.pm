package Minecraft::Player::Head;
use base Minecraft::Player::Soul;

use strict;
use warnings;
use Data::Dumper;
use Digest::MD5::File qw(file_md5_base64);
use Time::HiRes qw (sleep);
use Minecraft::FileIO;

sub new
{
  my $class = $_[0];
  my $self = Minecraft::Player::Soul::new($class);
  $self->{'compare_method'} = 0; # 0:md5, 1:cmp
  if(!$self->{'compare_method'})
  {
    $self->{'md5_cache'} = Minecraft::FileIO::read_json_file($self->screenshots_path()."/md5.cache");
  }
  # print Dumper $self, $class;
  return $self;
}

sub DESTROY
{
  my $self = $_[0];
  if(!$self->{'compare_method'})
  {
    Minecraft::FileIO::save_json_file($self->screenshots_path()."/md5.cache", $self->{'md5_cache'});
  }
}

sub screenshots_path
{
  my $self = $_[0];
  return sprintf("%s/%s", $main::config->{'user'}{'paths'}{'screenshosts'}, $main::config->{'user'}{'minecraft'}{'texture_pack'});
}

sub screenshot_full_filename
{
  my ($self, $name) = @_[0..1];
  return sprintf("%s/%s.bmp", $self->screenshots_path(), $name);
}

sub screenshot_item_path
{
  my ($self, $item, $interface, $cells) = @_[0..4];
  return sprintf("items/%s/%s/%s", $item, $interface, $cells);
}

sub screenshot_item_name
{
  my ($self, $item, $interface, $cells, $x, $y) = @_[0..5];
  return sprintf("%s/%d-%d", $self->screenshot_item_path($item, $interface, $cells), $x, $y);
}

sub take_screenshot
{
  my ($self, $filename, $coordinates, $clean) = @_[0..3];
  if($clean && $main::player->hand()->mouse_hide_from_interface())
  {
    sleep($main::config->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'});
  }
  system(sprintf('import -silent -compress None -window "%s" -crop %dx%d+%d+%d %s',
    $main::config->{'user'}{'minecraft'}{'title'},
    $coordinates->{'br'}{'x'} - $coordinates->{'tl'}{'x'},
    $coordinates->{'br'}{'y'} - $coordinates->{'tl'}{'y'},
    $coordinates->{'tl'}{'x'},
    $coordinates->{'tl'}{'y'},
    $self->screenshot_full_filename($filename)));
  return $filename;
}

sub take_temp_screenshot
{
  my ($self, $coordinates, $clean) = @_[0..2];
  return $self->take_screenshot('temporally', $coordinates, $clean);
}

sub convert_cell_to_item_coordinates
{
  my ($self, $coordinates) = @_[0..1];
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
  my ($self, $item, $interface, $cells, $x, $y) = @_[0..5];
  return $self->take_screenshot(
                                $self->screenshot_item_name($item, $interface, $cells, $x, $y),
                                $self->convert_cell_to_item_coordinates($main::config->{'system'}{$interface}{$cells}{$x}{$y}),
                                1);
}

sub take_temp_item_screenshot
{
  my ($self, $coordinates) = @_[0..1];
  return $self->take_screenshot(
                                'temporally',
                                $self->convert_cell_to_item_coordinates($coordinates),
                                1);
}

sub hand_is_empty
{
  my ($self, $interface) = @_[0..1];
  $main::player->hand()->mouse_move_to_cell($main::config->{'system'}{$interface}{'clean'});
  sleep($main::config->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'});
  my $ssname = $self->take_screenshot('temporally', $main::config->{'system'}{$interface}{'clean'}, 0);
  return $self->compare_screenshots($ssname, sprintf("dont-delete-%s-clean", $interface));
}

sub result_is_empty
{
  my ($self, $interface) = @_[0..1];
  return $self->compare_screenshots
                        (
                            sprintf('dont-delete-%s-result-empty', $interface),
                            $self->take_temp_screenshot($main::config->{'system'}{$interface}{'result'}, 1)
                        );
}

sub interface_is_open
{
  my ($self, $interface) = @_[0..1];
  return $self->compare_screenshots
              (
                sprintf('dont-delete-%s-is-open', $interface),
                $self->take_temp_screenshot($main::config->{'system'}{$interface}{'is_open'})
              );
}

sub compare_with_cmp
{
  my ($self, $f0, $f1) = @_[0..2];
  system("cmp", "--silent", $self->screenshot_full_filename($f0), $self->screenshot_full_filename($f1));
  if ($? == -1) { die "Не могу запустить cmp: $!\n"; }
  elsif ($? & 127) { die sprintf("cmp издох с сигналом %d, %s\n", ($? & 127),  ($? & 128) ? 'с корой' : 'без коры') ; }
  my $ret = $? >> 8;
  if($ret == 2) { die "Проблема с cmp: $!\n"; }
  # print $ret;
  return $ret == 0;
}

sub compare_with_md5
{
  my ($self, $f0, $f1) = @_[0..2];
  #print sprintf("%s == %s : %s\n",file_md5_base64($f0), file_md5_base64($f1) ,file_md5_base64($f0) eq file_md5_base64($f1));
  return $self->get_md5($f0) eq $self->get_md5($f1);
}

sub compare_screenshots
{
    my ($self, $f0, $f1) = @_[0..2];
    if($self->{'compare_method'} == 0) { return $self->compare_with_md5($f0, $f1); }
    if($self->{'compare_method'} == 1) { return $self->compare_with_cmp($f0, $f1); }
}

sub compare_screenshots_no_cache
{
  my ($self, $f0, $f1) = @_[0..2];
  if($self->{'compare_method'} == 0) { return file_md5_base64($self->screenshot_full_filename($f0)) eq file_md5_base64($self->screenshot_full_filename($f1)); }
  if($self->{'compare_method'} == 1) { return $self->compare_with_cmp($f0, $f1); }
}

sub get_md5
{
  my ($self, $name) = @_[0..1];
  if($name eq 'temporally')
  {
    #Minecraft::UserInteraction::say("Считаю md5 от временного файла...");
    return file_md5_base64($self->screenshot_full_filename($name));
  }
  if(!exists($self->{'md5_cache'}{$name}))
  {
    $self->{'md5_cache'}{$name} = file_md5_base64($self->screenshot_full_filename($name));
    #Minecraft::UserInteraction::say("Новый хэш md5 в кэше: [%s:%s]", $name, $md5_cache->{$name});
  }
  return $self->{'md5_cache'}{$name};
}



1;
