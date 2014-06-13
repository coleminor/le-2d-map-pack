#!/usr/bin/perl
use warnings;
use strict;
use Text::Fuzzy;
use File::Basename;

my $note_dir = './notes';
my $map_dir = './maps';
my $note_suffix = '-notes.txt';
my $map_suffix = '.elm.gz';
my $note_files;
my $abbreviations;

sub get_name {
  my $f = shift;
  my $n = basename $f;
  $n =~ s/$note_suffix$//;
  $n =~ s/$map_suffix$//;
  return $n;
}

sub find_note_files {
  my $p = $note_dir;
  opendir my $d, $p
    or die "could not open '$p': $!";
  my @a = grep { /$note_suffix$/ } readdir $d;
  die "no note files found in '$p'"
    unless @a;
  $note_files = \@a;
}

sub create_abbreviation_table {
  my @w;
  my @l;
  for my $f (@$note_files) {
    my $n = get_name $f;
    my $t = $n;
    $t =~ s/^[12]_//;
    push @w, $t;
    push @l, $n;
  }
  my $c = 'elm-render-notes -l';
  open my $i, '-|', $c
    or die "failed to run '$c': $!";
  my %h;
  while (<$i>) {
    next unless /^(...) - (.*)$/;
    my ($s, $l) = ($1, $2);
    my $t = lc $l;
    $t =~ s/[ '-]/_g/;
    my $m = Text::Fuzzy->new($t, max=>10);
    my $b = $m->nearest(\@w);
    die "no match for '$t' ($s - $l)"
      unless defined $b;
    $h{$s} = $l[$b];
  }
  $abbreviations = \%h;
}

sub read_links {
  my $f = shift;
  open my $i, '<', $f
    or die "could not open '$f': $!";
  my @l;
  while (<$i>) {
    chomp;
    next unless /^(\d+),(\d+) @(...)/;
    my ($x, $y, $w) = ($1, $2, $3);
    push @l, [$x, $y, $w];
  }
  close $i;
  return \@l;
}

sub get_tile_extent {
  my $p = shift;
  open my $i, '-|', "elmhdr $p"
    or die "could not run elmhdr on '$p': $!";
  my ($x, $y);
  while (<$i>) {
    $x = 6*$1 if /^terrain_x = (\d+)/;
    $y = 6*$1 if /^terrain_y = (\d+)/;
    last if defined $x and defined $y;
  }
  die "map sizes not found for '$p'"
    unless defined $x and defined $y;
  return [$x, $y];
}

sub unabbreviate {
  my $a = shift;
  my $t = $abbreviations;
  die "unrecognized abbreviation '$a'"
    unless exists $t->{$a};
  return $t->{$a};
}

sub get_routes {
  my $f = shift;
  my $n = get_name $f;
  my $m = "$map_dir/$n$map_suffix";
  return unless -f $m;
  my $p = "$note_dir/$f";
  my $l = read_links $p;
  return unless @$l;
  my $s = get_tile_extent $m;
  my %h;
  for my $r (@$l) {
    my ($x, $y, $w) = @$r;
    my $u = $x / $s->[0];
    my $v = 1.0 - $y / $s->[1];
    my $d = unabbreviate $w;
    $h{$d} = [$u, $v];
  }
  return \%h;
}

$map_dir = shift if @ARGV;
$note_dir = shift if @ARGV;
find_note_files;
create_abbreviation_table;

my %h;
for my $f (@$note_files) {
  my $r = get_routes $f or next;
  my $n = get_name $f;
  $h{$n} = $r;
}
for my $n (sort keys %h) {
  my $r = $h{$n};
  for my $d (sort keys %$r) {
    my $w = $r->{$d};
    next if $n gt $d;
    my ($x, $y) = @$w;
    die "no routes for '$d'"
      unless exists $h{$d};
    my $o = $h{$d};
    die "no destination found for '$n' in '$d'"
      unless exists $o->{$n};
    my $c = $o->{$n};
    my ($u, $v) = @$c;
    print "$n $x,$y - $d $u,$v\n";
  }
}
