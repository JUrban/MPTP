#!/usr/bin/perl -w

=head1 NAME

EvalSnow.pl [scalelimit] ( Print the statitics abot Snow predictions)

=head1 SYNOPSIS

  # Train snow with Naive Bayes targets 0-41079 on $NAME.train,
  # test then on $NAME.test, limiting prediction output to 100 best hits,
  # print the statistics about results into $NAME.eval,
  # and plot it with gnuplot.

 snow -train -I $NAME.train -F $NAME.net -B :0-41079
 snow -test -o allboth -I $NAME.test -F $NAME.net -B :0-41079 | LimitSnow.pl 100 > $NAME.res
 EvalSnow.pl 100  < $NAME.res > $NAME.eval
 gnuplot
 gnuplot> plot "$NAME.eval"

=head1 APPENDIX

Description of functions defined here.

=cut

use strict;

# the limit for the scale
my $glimit = shift(@ARGV);
my ($gstat,$gscale)     ;

$glimit = 100 unless(defined($glimit));


=head2   ParseStats()

  Title        : ParseStats()
  Usage        : $gstat = ParseStats();
  Function     : Parse the Snow result predictions into a statistics table.
                 Each record in the table is a list 
                 ( number_of_wanted_targets, (positions_of_wanted_targets) )
  Returns      : pointer to the table
  Global Vars  : STDIN
  Args         : -

=cut

sub ParseStats
{
    my $predpos;
    my @stat;

    while ($_=<>) 
    {
	if (/Example/)        # Start entry for a new example
	{
	    my $rec  = [];
	    $predpos = 0;

	    /Example.*:(.*)/ or die "Bad Example $_";
	    my @wanted = split /\, /, $1;
	    push @$rec, (1+$#wanted, []);
	    push @stat, $rec;
	}
	else                  # Push positions of wanted targets - they are marked with * in $NAME.res
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
  Usage        : $gscale = CreateScale($glimit, $gstat);
  Function     : Calculate average snow hitrate for each value below a limit.
                 This means: For each scale step, calculate for each example the
                 number of correctly
                 predicted references below the step, and divide by
                 min(total number of needed refs, step value) - 
                 which tells how much are we successful at this point.
                 Do average across all examples.
  Returns      : -
  Global Vars  : -
  Args         : $limit: scale upper limit, $stat: parsed statistics table

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

=head2  PrintScale()

  Title        : PrintScale()
  Usage        : PrintScale($gscale);
  Function     : Print the scale for gnuplot
  Returns      : -
  Global Vars  : -
  Args         : $scale: scale in output format of CreateScale()

=cut

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
