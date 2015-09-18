package Minecraft::UserInteraction;

use strict;
use warnings;
use Exporter qw(import);
use Time::HiRes qw (sleep);

sub say
{
    my $format = shift;
    my @variables = @_;
    printf($format."\n", @variables);
}

sub wait_press_enter
{
    my $format = shift;
    my @variables = @_;
    say($format.". Нажмите тут enter...", @variables);
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

1;