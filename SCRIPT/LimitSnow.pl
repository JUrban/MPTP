#!/usr/bin/perl -w

=head1 NAME

LimitSnow.pl ( Cut the Snow output to given number of lines for each example)

=cut

use strict;

my $glimit = shift(@ARGV);
my $glines = 0;

$glimit = 20 unless(defined($glimit));

$glimit++;

do { $_=<> } while($_ && !($_=~/Example/));

print $_ if(defined($_));

while($_=<>)
{
    if(/Example/) { $glines = 0} else { $glines++};

    print $_ if($glines < $glimit);
}


