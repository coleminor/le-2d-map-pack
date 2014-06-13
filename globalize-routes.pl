#!/usr/bin/perl
use warnings;
use strict;

sub read_bounds {
  my ($p) = @_;
  open my $f, '<', $p or die "$p: $!";
  my %m;
  while (<$f>) {
    chomp;
    next unless /^(\S+) (\d+) (\d+) (\d+) (\d+)$/;
    my ($n, $x0, $y0, $x1, $y1) = ($1, $2, $3, $4, $5);
    $m{$n} = [$x0, $y0, $x1 - $x0, $y1 - $y0];
  }
  return \%m;
}

sub read_routes {
  my ($p) = @_;
  open my $f, '<', $p or die "$p: $!";
  my @l;
  while (<$f>) {
    chomp;
    next unless /^(\S+) (0\.\d+),(0\.\d+) - (\S+) (0\.\d+),(0\.\d+)$/;
    my ($s, $sx, $sy, $e, $ex, $ey) = ($1, $2, $3, $4, $5, $6);
    push @l, [[$s, $sx, $sy], [$e, $ex, $ey]];
  }
  return \@l;
}

sub globalize {
  my ($l, $m) = @_;
  my ($n, $lx, $ly) = @$l;
  my ($ox, $oy, $w, $h) = @{$m->{$n}};
  my $x = int($ox + $lx * $w);
  my $y = int($oy + $ly * $h);
  return [$x, $y];
}

my $pb = shift or die "bound list expected";
my $pr = shift or die "route list expected";

my $m = read_bounds $pb;
my $l = read_routes $pr;

for my $r (@$l) {
  my ($s, $e) = @$r;
  my $sg = globalize $s, $m;
  my $eg = globalize $e, $m;
  print "$sg->[0],$sg->[1] $eg->[0],$eg->[1]\n";
}

