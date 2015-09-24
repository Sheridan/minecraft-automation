package Minecraft::Interfaces::Villager;

use strict;
use warnings;
use Data::Dumper;
use Minecraft::Screenshoter;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = { };
  bless($self, $class);
  $self->clear_state();
  return $self;
}

sub clear_state
{
  my $self = $_[0];
  $self->{'pages'} = { 'current' => 1, 'cache'   => {} };
}

sub hand_is_empty
{
  return Minecraft::Screenshoter::hand_is_empty('villager');
}

sub can_trade # trader_can_sell
{
    return Minecraft::Screenshoter::compare_screenshots
                        (
                            'dont-delete-villager-trade-avialable',
                            Minecraft::Screenshoter::take_temp_screenshot($main::config->{'system'}{'villager'}{'trade-avialable'}, 0)
                        );
}

sub result_is_empty # trader_result_is_empty
{
  return Minecraft::Screenshoter::compare_screenshots
                        (
                            'dont-delete-villager-result-empty',
                            Minecraft::Screenshoter::take_temp_screenshot($main::config->{'system'}{'villager'}{'result'}, 1)
                        );
}

sub invertory_is_empty # trader_invertory_is_empty
{
  my ($self, $villager_invertory) = @_[0..1];
  return Minecraft::Screenshoter::compare_screenshots
                        (
                            sprintf('dont-delete-villager-invertory-%d', $villager_invertory),
                            Minecraft::Screenshoter::take_temp_screenshot($main::config->{'system'}{'villager'}{'invertory'}{$villager_invertory}, 1)
                        );
}

sub trade_interface_is_open # trade_interface_is_open
{
  return Minecraft::Screenshoter::compare_screenshots
                        (
                            'dont-delete-villager-clean',
                            Minecraft::Screenshoter::take_temp_screenshot($main::config->{'system'}{'villager'}{'clean'}, 0)
                        );
}

sub can_trade_on_page # trader_can_trade_on_page
{
  my ($self, $page) = @_[0..1];
  if($self->switch_to_page($page))
  {
    return $self->can_trade();
  }
  return 0;
}

sub can_trade_something # trader_can_trade_something
{
  my ($self, $items_to_trade) = @_[0..1];
  for my $item_to_trade (keys(%{$items_to_trade}))
  {
    if($self->can_trade_on_page($items_to_trade->{$item_to_trade}))
    {
      return 1;
    }
  }
  return 0;
}

sub can_trade_all # trader_can_trade_all
{
  my ($self, $items_to_trade) = @_[0..1];
  my $flag = 0;
  for my $item_to_trade (keys(%{$items_to_trade}))
  {
    $flag += $self->can_trade_on_page($items_to_trade->{$item_to_trade});
  }
  return $flag == scalar(keys(%{$items_to_trade}));
}

sub switch_to_page # switch_to_trader_page
{
  my ($self, $page) = @_[0..1];
  my $button_name = $page > $self->{'pages'}{'current'} ? 'next_page' : 'prev_page';
  while($page != $self->{'pages'}{'current'})
  {
    if(!$self->page_avialable($button_name, $self->{'pages'}{'current'}))
    {
      return 0;
    }
    Minecraft::Automation::mouse_move_to_button($main::config->{'system'}{'villager'}{$button_name});
    Minecraft::Automation::mouse_left_click();
    sleep($main::config->{'user'}{'timeouts'}{'villager_page_switch'});
    $self->{'pages'}{'current'} += $page > $self->{'pages'}{'current'} ? 1 : -1;
  }
  return 1;
}

sub page_avialable # trader_page_avialable
{
  my ($self, $button_name, $page) = @_[0..2];
  if(!exists($self->{'pages'}{'cache'}{$button_name}{$page}))
  {
    $self->{'pages'}{'cache'}{$button_name}{$page} =
                !Minecraft::Screenshoter::compare_screenshots
                          (
                            sprintf("dont-delete-villager-%s-not-avialable", $button_name),
                            Minecraft::Screenshoter::take_temp_screenshot($main::config->{'system'}{'villager'}{$button_name}, 1)
                          );
  }
  return $self->{'pages'}{'cache'}{$button_name}{$page};
}

sub wait_for_upgrade # wait_for_trader_upgrade
{
  my ($self, $items_to_trade) = @_[0..1];
  Minecraft::UserInteraction::say("Отдыхаем, пока торговец апгредится...");
  Minecraft::Automation::close_interface('villager');
  sleep($main::config->{'user'}{'timeouts'}{'villager_upgrade'});
  Minecraft::Automation::open_interface('villager');
  $self->clear_state();
  if(defined($items_to_trade))
  {
    Minecraft::UserInteraction::say("Проверяем, проапгредился ли торговец...");
    return $self->can_trade_something($items_to_trade);
  }
  return 1;
}

sub put_stack_to_invertory
{
  my ($self, $cell_number) = @_[0..1];
  Minecraft::Automation::mouse_move_to_cell($main::config->{'system'}{'villager'}{'invertory'}{$cell_number});
  Minecraft::Automation::mouse_left_click();
}

1;