#!/usr/bin/perl
use warnings;
use strict;
use File::Copy;
use POSIX qw(strftime);

my $re_line = qr/^(\w+\s+(?:\d+\s+){4}(\S+)\s*)$/;

sub usage {
  print<<"EOS";
Usage: $0 ORIGINAL NEW [NEW2 ...]

Lines in the mapinfo.lst file ORIGINAL are
replaced by corresponding lines in NEW.
EOS
  exit 1;
}

sub read_lines {
  my ($p) = @_;
  open my $i, '<', $p
    or die "failed to open '$p': $!";
  my $h = {};
  while (<$i>) {
    next unless /$re_line/;
    my ($l, $m) = ($1, $2);
    $h->{$m} = $l;
  }
  return $h;
}

sub main {
  my @a = @ARGV;
  usage if @a < 2;
  my $p = shift @a;

  my $h = {};
  for my $f (@a) {
    my $n = read_lines $f;
    my %m = (%$h, %$n);
    $h = \%m;
  }

  my $c_replaced = 0;

  open my $i, '<', $p
    or die "failed to open '$p': $!";
  my $t = "$p-updated_mapinfo.txt";
  open my $o, '>', $t
    or die "failed to open '$t' for writing: $!";
  while (<$i>) {
    if (/$re_line/) {
      my ($l, $m) = ($1, $2);
      if (exists $h->{$m} and $h->{$m} ne $l) {
        $c_replaced++;
        print $o $h->{$m};
        next;
      } 
    }
    print $o $_;
  }
  close $i;
  close $o;
  
  if (!$c_replaced) {
    print "$p: no change\n";
    unlink $t;
    return;
  }

  my $d = strftime '%Y%m%d_%H%M%S', localtime;
  my $b = "$p-$d.bak";
  move $p, $b;
  print "$p: backup saved to '$b'\n";
  move $t, $p;
  print "$p: $c_replaced lines replaced\n";
}

main;
