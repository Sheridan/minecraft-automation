package Minecraft::L10n;

use strict;
use warnings;
use Data::Dumper;
use Minecraft::FileIO;

sub new
{
  my ($class) = $_[0];
  my $self =
  {
    'l10n' => {}
  };
  bless($self, $class);
  # print Dumper $self, $class;
  return $self;
}

sub join_translation
{
    my ($self, $translation) = @_[0..1];
    return ref($translation) eq "ARRAY" ? join("\n", @{$translation})."\n" : $translation;
}

sub translate
{
    my ($self, $phrase, $lang) = @_[0..2];
    my $filename = sprintf("config/l10n/%s.json", $phrase);
    if(-e $filename)
    {
	my $phrase_variants = Minecraft::FileIO::read_json_file($filename);
	if(exists($phrase_variants->{$lang}))
	{
	    return $self->join_translation($phrase_variants->{$lang});
	}
	if($main::config->{'user'}{'l10n'}{'language'} ne 'en')
	{
	    return $self->translate($phrase, 'en');
	}
    }
    return $phrase;
}

sub tr
{
  my ($self, $phrase) = @_[0..1];
  if(!exists($self->{'l10n'}{$phrase}))
  {
    $self->{'l10n'}{$phrase} = $self->translate($phrase, $main::config->{'user'}{'l10n'}{'language'});
  }
  return $self->{'l10n'}{$phrase};
}

1;
