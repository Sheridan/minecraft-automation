package Minecraft::Player::Head;
use base Minecraft::Player::Soul;

use strict;
use warnings;
use Data::Dumper;
use File::Path qw(make_path);
use Digest::MD5::File qw(file_md5_base64);
use Time::HiRes qw (sleep gettimeofday);
use Minecraft::FileIO;

sub new
{
  my $class = $_[0];
  my $self = Minecraft::Player::Soul::new($class);
  $self->{'compare_method'} = 0; # 0:md5, 1:cmp
  $self->{'temporally_screenshots'} = [];
  if(!$self->{'compare_method'})
  {
    $self->{'md5_cache'} = Minecraft::FileIO::read_json_file($self->screenshots_path()."/md5.cache");
  }
  # print Dumper $self, $class;
  if(! -d $main::config->{'user'}{'paths'}{'temp'})
  {
    make_path($main::config->{'user'}{'paths'}{'temp'});
  }
  return $self;
}

sub DESTROY
{
  my $self = $_[0];
  if(!$self->{'compare_method'})
  {
    Minecraft::FileIO::save_json_file($self->screenshots_path()."/md5.cache", $self->{'md5_cache'});
  }
  for my $file (@{$self->{'temporally_screenshots'}})
  {
    unlink($file);
  }
}

sub coordinates_shift_by_delta
{
  my ($self, $coordinates) = @_[0..1];
  my $c_shifted = {};
  for my $crdpnt ('tl', 'c', 'br')
  {
	if (not exists($coordinates->{$crdpnt})) { next; }
	$c_shifted->{$crdpnt} = { 'x' => 0, 'y' => 0 };
	for my $crd ('x', 'y')
	{
		$c_shifted->{$crdpnt}{$crd} = $coordinates->{$crdpnt}{$crd} + $main::config->{'system'}{'coordinates_delta'}{$crd};
	}
  }
  return $c_shifted;
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

sub screenshot_temp_filename
{
  my $self = $_[0];
  my $filename = sprintf("%s/%s.bmp", $main::config->{'user'}{'paths'}{'temp'}, int (gettimeofday() * 1000));
  push(@{$self->{'temporally_screenshots'}}, $filename);
  return $filename;
}

sub take_screenshot_and_save_to
{
  my ($self, $filename, $coordinates, $clean) = @_[0..3];
  $coordinates = $self->coordinates_shift_by_delta($coordinates);
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
    $filename));
  return $filename;
}

sub take_screenshot
{
  my ($self, $filename, $coordinates, $clean) = @_[0..3];
  return $self->take_screenshot_and_save_to($self->screenshot_full_filename($filename), $coordinates, $clean);
}

sub take_temp_screenshot
{
  my ($self, $coordinates, $clean) = @_[0..2];
  return $self->take_screenshot_and_save_to($self->screenshot_temp_filename(), $coordinates, $clean);
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
  return $self->take_screenshot($self->screenshot_item_name($item, $interface, $cells, $x, $y),
                                $self->convert_cell_to_item_coordinates($main::config->{'system'}{$interface}{$cells}{$x}{$y}),
                                1);
}

sub take_temp_item_screenshot
{
  my ($self, $coordinates) = @_[0..1];
  return $self->take_screenshot_and_save_to($self->screenshot_temp_filename(),
                                            $self->convert_cell_to_item_coordinates($coordinates),
                                            1);
}

sub hand_is_empty
{
  my ($self, $interface) = @_[0..1];
  if($main::player->hand()->mouse_move_to_cell($main::config->{'system'}{$interface}{'clean'}))
  {
    sleep($main::config->{'user'}{'timeouts'}{'between_mouse_hide_and_screenshot'});
  }
  return $self->compare_screenshots
                        (
                          $self->take_temp_screenshot($main::config->{'system'}{$interface}{'clean'}, 0), 
                          $self->screenshot_full_filename(sprintf("dont-delete-%s-clean", $interface))
                        );
}

sub result_is_empty
{
  my ($self, $interface) = @_[0..1];
  return $self->compare_screenshots
                        (
                            $self->screenshot_full_filename(sprintf('dont-delete-%s-result-empty', $interface)),
                            $self->take_temp_screenshot($main::config->{'system'}{$interface}{'result'}, 1)
                        );
}

sub interface_is_open
{
  my ($self, $interface) = @_[0..1];
  return $self->compare_screenshots
                        (
                          $self->screenshot_full_filename(sprintf('dont-delete-%s-is-open', $interface)),
                          $self->take_temp_screenshot($main::config->{'system'}{$interface}{'is_open'})
                        );
}

sub compare_with_cmp
{
  my ($self, $f0, $f1) = @_[0..2];
  system("cmp", "--silent", $f0, $f1);
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
  if($self->{'compare_method'} == 0) { return file_md5_base64($f0) eq file_md5_base64($f1); }
  if($self->{'compare_method'} == 1) { return $self->compare_with_cmp($f0, $f1); }
}

sub get_md5
{
  my ($self, $name) = @_[0..1];
  if($name =~ '.*/\d+\.bmp')
  {
    #Minecraft::UserInteraction::say("Считаю md5 от временного файла...");
    return file_md5_base64($name);
  }
  if(!exists($self->{'md5_cache'}{$name}))
  {
    $self->{'md5_cache'}{$name} = file_md5_base64($name);
    #Minecraft::UserInteraction::say("Новый хэш md5 в кэше: [%s:%s]", $name, $self->{'md5_cache'}{$name});
  }
  return $self->{'md5_cache'}{$name};
}



1;
