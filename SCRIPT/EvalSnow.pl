#!/usr/bin/perl -w

=head1 NAME

EvalSnow.pl ( Print the statitics abot Snow predictions )

=cut

use strict;

# the limit for the scale
my $glimit = shift(@ARGV);
my ($gstat,$gscale)     ;

$glimit = 100 unless(defined($glimit));

sub ParseStats
{
    my $predpos;
    my @stat;

    while ($_=<>) 
    {
	if (/Example/)
	{
	    my $rec  = [];
	    $predpos = 0;

	    /Example.*:(.*)/ or die "Bad Example $_";
	    my @wanted = split /\, /, $1;
	    push @$rec, (1+$#wanted, []);
	    push @stat, $rec;
	}
	else
	{
	    $predpos++;
	    push(@{ $stat[$#stat]->[1]}, $predpos) if(/.*[*].*/);
	}
    }
    return \@stat;
}

sub PrintStats
{
    my ($stat) = @_;
    my $rec;
    foreach $rec (@$stat)
    {
	print "$rec->[0]:";
	print join(',', @{$rec->[1]}), "\n";
    }
}

sub min { my ($x,$y) = @_; ($x <= $y)? $x : $y }

=head2 CreateScale()
  Title        : CreateScale()
  Usage        : CreateScale($limit,$stat)
  Function     : For each scale step, calculate for each example the 
                 number of correctly
                 predicted references below the step, and divide by
                 min(total number of needed refs, step value) - 
                 which tells how much are we successful at this point.
                 Do average acroos all examples.
  Returns      : -
  Global Vars  : -
  Args         : $stat

=cut
sub CreateScale
{
    my ($limit,$stat) = @_;
    my @scale = ();
    my ($i,$j,$rec,$oneratio);

    for($i=1; $i <= $limit; $i++)
    {
	$scale[$i] = 0;
	foreach $rec (@$stat)
	{
	    $j = 0;
	    while(($j <= $#{$rec->[1]}) && ($rec->[1][$j] <= $i))
	    {
		$j++;
	    }
	    $oneratio = $j/min($rec->[0], $i);
	    $scale[$i] += $oneratio;
	}
	$scale[$i] = $scale[$i]/$#{@$stat};
    }
    return \@scale;
}

sub PrintScale
{
    my ($scale) = @_;
    my $i;

    for($i=1; $i <= $#{@$scale}; $i++)
    {
	print "$i $scale->[$i]\n";
    }
}


$gstat = ParseStats();

# PrintStats($gstat);
$gscale = CreateScale($glimit, $gstat);
PrintScale($gscale);
