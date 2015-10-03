package Minecraft::Interfaces::Villager;
use base Minecraft::Interfaces::Interface;

use strict;
use warnings;
use Data::Dumper;
use Time::HiRes qw (sleep);


sub new
{
  my $class = $_[0];
  my $self = Minecraft::Interfaces::Interface::new($class, 'villager');
  $self->self_invertory()->add_item_to_items_to_find('emerald');
  $self->clear_state();
  return $self;
}

sub clear_state
{
  my $self = $_[0];
  $self->{'pages'} = { 'current' => 1, 'cache'   => {} };
}


sub can_trade
{
    return $main::player->head()->compare_screenshots
                        (
                            $main::player->head()->screenshot_full_filename('dont-delete-villager-trade-avialable'),
                            $main::player->head()->take_temp_screenshot($main::config->{'system'}{'villager'}{'trade-avialable'}, 0)
                        );
}

sub invertory_is_empty
{
  my ($self, $villager_invertory) = @_[0..1];
  return $main::player->head()->compare_screenshots
                        (
                            $main::player->head()->screenshot_full_filename(sprintf('dont-delete-villager-invertory-%d', $villager_invertory)),
                            $main::player->head()->take_temp_screenshot($main::config->{'system'}{'villager'}{'invertory'}{$villager_invertory}, 1)
                        );
}

sub can_trade_on_page
{
  my ($self, $page) = @_[0..1];
  if($self->switch_to_page($page))
  {
    return $self->can_trade();
  }
  return 0;
}

sub can_trade_something
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

sub can_trade_all
{
  my ($self, $items_to_trade) = @_[0..1];
  my $flag = 0;
  for my $item_to_trade (keys(%{$items_to_trade}))
  {
    $flag += $self->can_trade_on_page($items_to_trade->{$item_to_trade});
  }
  return $flag == scalar(keys(%{$items_to_trade}));
}

sub switch_to_page
{
  my ($self, $page) = @_[0..1];
  my $button_name = $page > $self->{'pages'}{'current'} ? 'next_page' : 'prev_page';
  while($page != $self->{'pages'}{'current'})
  {
    if(!$self->page_avialable($button_name, $self->{'pages'}{'current'}))
    {
      return 0;
    }
    $main::player->hand()->press_button($main::config->{'system'}{'villager'}{$button_name});
    sleep($main::config->{'user'}{'timeouts'}{'villager_page_switch'});
    $self->{'pages'}{'current'} += $page > $self->{'pages'}{'current'} ? 1 : -1;
  }
  return 1;
}

sub page_avialable
{
  my ($self, $button_name, $page) = @_[0..2];
  if(!exists($self->{'pages'}{'cache'}{$button_name}{$page}))
  {
    $self->{'pages'}{'cache'}{$button_name}{$page} =
                !$main::player->head()->compare_screenshots
                          (
                            $main::player->head()->screenshot_full_filename(sprintf("dont-delete-villager-%s-not-avialable", $button_name)),
                            $main::player->head()->take_temp_screenshot($main::config->{'system'}{'villager'}{$button_name}, 1)
                          );
  }
  return $self->{'pages'}{'cache'}{$button_name}{$page};
}

sub wait_for_upgrade
{
  my ($self, $items_to_trade) = @_[0..1];
  Minecraft::UserInteraction::say($main::l10n->tr('wait_trader_upgarde'));
  $main::player->hand()->close_interface('villager');
  sleep($main::config->{'user'}{'timeouts'}{'villager_upgrade'});
  $main::player->hand()->open_interface('villager');
  $self->clear_state();
  if(defined($items_to_trade))
  {
    Minecraft::UserInteraction::say($main::l10n->tr('check_trader_upgarde'));
    return $self->can_trade_something($items_to_trade);
  }
  $self->self_invertory()->remap();
  return 1;
}

sub put_stack_to_invertory
{
  my ($self, $villager_invertory) = @_[0..1];
  $main::player->hand()->put_stack_to_cell($main::config->{'system'}{'villager'}{'invertory'}{$villager_invertory});
}

1;
