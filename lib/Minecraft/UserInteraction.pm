package Minecraft::UserInteraction;

use strict;
use warnings;
use Exporter qw(import);
use Time::HiRes qw (sleep);

sub wait_press_enter
{
    my $text = $_[0];
    say($text.". Нажмите тут enter...");
    <STDIN>;
}

sub prompt 
{
  my $query = $_[0];
  local $| = 1;
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}

sub prompt_yn 
{
  my $query = $_[0];
  my $answer = prompt("$query (Y/N): ");
  return lc($answer) eq 'y';
}
