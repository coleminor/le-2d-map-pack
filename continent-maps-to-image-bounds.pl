#!/usr/bin/perl
use warnings;
use strict;

my $continent_size = 512;
my $image_size = 1024;
my $continent_list = './mapinfo.lst';

sub continent_to_image_coordinates {
  my ($x, $y) = @_;
  my $i = $image_size;
  my $c = $continent_size;
  my $u = $x * $i / $c;
  my $v = $i - $y * $i / $c;
  return $u, $v;
}

sub normalize_continent_name {
  my $c = shift;
  my $n = lc $c;
  if ($n =~ /^ser/) {
    $n = "1_$n";
  } elsif ($n =~ /^iri/) {
    $n = "2_$n";
  }
  return $n;
}

my $p = shift || $continent_list;
my $m = shift;

unless (-f $p) {
  print<<EOS;
Usage: $0 [map list] [continent name]

The default map list file is '$continent_list'.
If no continent name pattern is given, all map
bounds are printed.
EOS
  exit 1;
}

open my $f, '<', $p or die "failed to open '$p': $!";
while (<$f>) {
  chomp;
  next unless /^(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+\.\/maps\/([^.]+)\.elm/;
  my ($c, $x0, $y0, $x1, $y1, $n) = ($1, $2, $3, $4, $5, $6);
  next if $m and $c !~ /$m/;
  next unless $x0 and $y0 and $x1 and $y1;
  my ($u0, $v0) = continent_to_image_coordinates $x0, $y0;
  my ($u1, $v1) = continent_to_image_coordinates $x1, $y1;
  ($u0, $u1) = ($u1, $u0) if $u1 < $u0;
  ($v0, $v1) = ($v1, $v0) if $v1 < $v0;
  my $r = normalize_continent_name $c;
  print "$r $u0 $v0 $u1 $v1 $n\n";
}
