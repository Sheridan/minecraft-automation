package Minecraft::FileIO;

use strict;
use warnings;
use JSON;
use Data::Dumper;
use Exporter qw(import);
use Time::HiRes qw (sleep);

sub read_config
{
  my $c = 
    {
        'user'   => read_config_file('config/user-config.json'),
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
  
  return $c;
}

sub read_json_file
{
  my $file_name = $_[0];
  local $/;
  open( my $fh, '<', $file_name ) or die $!;
  my $result = from_json(<$fh>, {utf8 => 1});
  close($fh);
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

sub trim 
{ 
  my $s = shift; 
  $s =~ s/^\s+|\s+$//g; 
  return $s;
}

1;