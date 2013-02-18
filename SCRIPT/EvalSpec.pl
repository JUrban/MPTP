#!/usr/bin/perl -w

=head1 NAME

EvalSpec.pl [scalelimit] ( Print the statitics abot predicted specification file)

=head1 SYNOPSIS

  # Train snow with Naive Bayes targets 0-41079 on $NAME.train,
  # test then on $NAME.test, limiting prediction output to 100 best hits,
  # print the statistics about results into $NAME.eval,
  # and plot it with gnuplot.

 snow -train -I $NAME.train -F $NAME.net -B :0-41079
 snow -test -o allboth -I $NAME.test -F $NAME.net -B :0-41079 | LimitSnow.pl 100 > $NAME.res
 time /home/urban/gitrepo/MPTP2/finedeps/SnowRes2Specs.pl -l500 -r/home/mptp/big/ec/HolyHammer/Advisor/holdata1/refnr < /home/mptp/big/ec/HolyHammer/Advisor/holdata1/holdata1.res  > /home/mptp/big/ec/HolyHammer/Advisor/holdata1/holdata1.spec4
 EvalSpec.pl -l100  < $NAME.spec > $NAME.eval
 gnuplot
 gnuplot> plot "$NAME.eval"

for KNN:

    perl -e 'while(<>) {$i++; if(int($i/3)== $i/3) print $_}' combdeps.m10u_all_atponly  > c5000
    time ./knn.pl symst_notrivsyms c5000 40 1 3 > rc5000.spec
    EvalSpec.pl -l100  rc5000.spec c5000 > $NAME.eval
    gnuplot
    gnuplot> plot "$NAME.eval"

 Options:
   --limit=<arg>,           -l<arg>
   --examplegraph=<arg>,    -e<arg>
   --windowsize=<arg>,      -w<arg>
   --ignore_self,           -I
   --ignore_defs,           -d
   --output=<arg>,          -o<arg>
   --all,                   -A
   --matrix,                -M
   --help,                  -h
   --man

=head1 OPTIONS

=over 8

=item B<<< --limit=<arg>, -l<arg> >>>

Upper limit for the hit scale, if creating scale.
The default is 100.

=item B<<< --examplegraph=<arg>, -e<arg> >>>

Create graph ranging over all examples instead of
the overall hit scale. <arg> determines the smoothing
method: none if 1, cumulative average if 2, sliding
average if 3 (size of the smoothing window is then 
specified with the -w parameter). The --ignore_self 
parameter also influences these results.

=item B<<< --windowsize=<arg>, -w<arg> >>>

Size of the smoothing window if using the -e3
(sliding average) method. Default is 100.

=item B<<< --ignore_self, -B<I> >>>

Do not include into the algorithms the reference to itself
in examples. This is advisable if the theorem labels are
newly introduced to the learning system in the testing
examples, and so we only can hope for getting their references
as advice.

=item B<<< --ignore_de, -d >>>

Skip examples with only one target label. These are usually
definitions, which we hardly want advice for, especially
if --ignore-self is used.

=item B<<< --output=<arg>, -o<arg> >>>

Direct the output into this file. If the -A option
is used, append this name with the method number
(see the -e option) for each graph.

=item B<<< --all, -B<A> >>>

Print graphs using all vailable methods (see the -e option).
Output file stem has to be supplied for this with 
the -o option.

=item B<<< --matrix, -B<M> >>>

If building graph(s) ranging over all examples 
(-e or -A options), rather than creating just one
dependence for the limit value, create a matrix for
a 3d graph of the dependences for all values ranging
from 1 to the limit.

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=head1 APPENDIX

Description of functions defined here.

=cut

use strict;
use Getopt::Long;
use Pod::Usage;

my $glimit       = 100;   # Limit for the scale
my $gwindow_size = 100;   # Size of the smoothing window
my $GraphMethod  = 0;     # Which graph we want
my $DoAllGraphs  = 0;     # Print all graphs
my $DoMatrix     = 0;     # Print matrices for 3D graphs
my $gstep        = 10;     # The step for creating matrices

# Do not count the reference to itself - testings when it is not available yet
# Some theorems may now be without refs - proved only by local private items
# or schemes - then at least 1 reference always
my $gignore_self = 0;
my $gignore_defs = 0;

my ($help, $man, $outfilename);
my ($gstat,$gscale) ;

=head2   ParseSpecs()

  Title        : ParseSpecs()
  Usage        : $gstat = ParseSpecss();
  Function     : Parse the spec result predictions into a statistics table.
                 Each record in the table is a list 
                 ( number_of_wanted_targets, (positions_of_wanted_targets) )
  Returns      : pointer to the table
  Global Vars  : STDIN
  Args         : -

=cut

my $greffile;
my $gpredfile;

sub ParseSpecs
{
    my @stat=();
    open(R, $greffile) or die;
    open(P, $gpredfile) or die;

    while(<R>)
    {
	chop($_);
	$_ =~ m/^([^:]+):(.*)/ or die "bad line $_";
	my ($name, $rfs) = ($1, $2);
	my @wanted = split(/ /,$rfs);
	my $rec  = [];
	push @$rec, (1+$#wanted, []);
	push @stat, $rec;
	my %refsh = ();
	@refsh{ @wanted } = ();

	$_=<P>;
	chop($_);
	$_ =~ m/^([^:]+):(.*)/ or die "bad line $_";
	my ($name1, $rfs1) = ($1, $2);
	die "$name noteq $name1" unless ($name eq $name1);
	my @pred = split(/ /,$rfs1);

	foreach my $i (0 .. $#pred)
	{
	    my $r = $pred[$i]; 
	    push(@{ $rec->[1]}, $i+1) if(exists($refsh{$r}));
	}
    }
    return \@stat;
}

sub min { my ($x,$y) = @_; ($x <= $y)? $x : $y }
sub max { my ($x,$y) = @_; ($x <= $y)? $y : $x }

sub PrintStats
{
    my ($stat) = @_;
    my $rec;
    foreach $rec (@$stat)
    {
	print OUT "$rec->[0]:";
	print OUT join(',', @{$rec->[1]}), "\n";
    }
}


sub BelowLimit
{
    my($rec,$limit) = @_;
    my @found_orders = @{$rec->[1]};
    my $l;

    if ((0 <= $#found_orders) && ($limit < $found_orders[$#found_orders]))
    {
	$l = 0;
	$l++ while(($l <= $#found_orders) && ($found_orders[$l] <= $limit));
    }
    else {$l   = (1+$#found_orders);}

    return $l;
}


# Ratio for each
sub PrintStats1
{
    my ($stat,$limit,$matrix,$step) = @_;
    my ($i,$j,$rec);

    for($i=0; $i <= $#{@$stat}; $i++)
    {
	$rec = $stat->[$i];
	my $l = ($matrix)? 1 : $limit;

	for( ; $l <= $limit; $l += $step)
	{
	    $j = BelowLimit($rec,$l)/max(1, $rec->[0] - $gignore_self);
	    print OUT "$j\t";
	}
	print OUT "\n";
    }
}

# Running average of ratios
sub PrintStats2
{
    my ($stat,$limit,$matrix,$step) = @_;
    my ($i,$j,$rec,$avg);
    my @sum;
    for($i=0; $i <= $#{@$stat}; $i++)
    {
	$rec = $stat->[$i];
	my $l = ($matrix)? 1 : $limit;

	for( ; $l <= $limit; $l += $step)
	{
	    $j = BelowLimit($rec,$l)/max(1,$rec->[0] - $gignore_self);
	    $sum[$l] += $j;
	    $avg = $sum[$l]/(1+$i);
	    print OUT "$avg\t";
	}
	print OUT "\n";
    }
}


# Sliding average of ratios across last $window_size ratios
sub PrintStats3
{
    my ($stat,$window_size,$limit,$matrix,$step) = @_;
    my ($i,$j,$rec,$rec1,$avg);
    my @sum;

    for($i=0; $i < $window_size; $i++)
    {
	my $l = ($matrix)? 1 : $limit;
	$rec = $stat->[$i];

	for( ; $l <= $limit; $l += $step)
	{
	    $sum[$l] += BelowLimit($rec,$l)/max(1,$rec->[0] - $gignore_self);
	}
    }

    for(; $i <= $#{@$stat}; $i++)
    {
	my $l = ($matrix)? 1 : $limit;
	$rec  = $stat->[$i];
	$rec1 = $stat->[$i - $window_size];

	for( ; $l <= $limit; $l += $step)
	{
	    $sum[$l] += BelowLimit($rec,$l)/max(1,$rec->[0] - $gignore_self);
	    $sum[$l] -= BelowLimit($rec1,$l)/max(1,$rec1->[0] - $gignore_self);
	    $avg = $sum[$l]/$window_size;
	    print OUT "$avg\t";
	}
	print OUT "\n";
    }
}






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
	    $oneratio = BelowLimit($rec,$i)/min(max(1,$rec->[0] - $gignore_self), $i);
	    $scale[$i] += $oneratio;
	}
	$scale[$i] = $scale[$i]/$#{$stat};
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

    for($i=1; $i <= $#{$scale}; $i++)
    {
	print OUT "$i $scale->[$i]\n";
    }
}


Getopt::Long::Configure ("bundling","no_ignore_case");

GetOptions('limit|l=i'         => \$glimit,
	   'examplegraph|e=i'  => \$GraphMethod,
	   'windowsize|w=i'    => \$gwindow_size,
	   'ignore_self|I'     => \$gignore_self,
	   'ignore_defs|d'     => \$gignore_defs,
	   'output|o=s'        => \$outfilename,
	   'all|A'             => \$DoAllGraphs,
	   'matrix|M'          => \$DoMatrix,
	   'help|h'            => \$help,
	   'man'               => \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);
pod2usage(2) if(($GraphMethod > 3) || ($DoAllGraphs && !($outfilename)));

pod2usage(2) if ($#ARGV < 1);

$greffile = shift;
$gpredfile = shift;



$gstat = ParseSpecs();

if($DoAllGraphs)
{
    open(OUT, ">".$outfilename."0");
    $gscale = CreateScale($glimit, $gstat); 
    PrintScale($gscale);
    close(OUT);
    open(OUT, ">".$outfilename."1");
    PrintStats1($gstat,$glimit,$DoMatrix,$gstep);
    close(OUT);
    open(OUT, ">".$outfilename."2");
    PrintStats2($gstat,$glimit,$DoMatrix,$gstep);
    close(OUT);
    open(OUT, ">".$outfilename."3");
    PrintStats3($gstat,$gwindow_size,$glimit,$DoMatrix,$gstep);
    close(OUT);
}
else
{
    if($outfilename) { open(OUT, ">$outfilename"); }
    else { open(OUT, ">&STDOUT"); }

    if ($GraphMethod == 0) {
	$gscale = CreateScale($glimit, $gstat); PrintScale($gscale);
    } elsif ($GraphMethod == 1) {
	PrintStats1($gstat,$glimit,$DoMatrix,$gstep);
    } elsif ($GraphMethod == 2) {
	PrintStats2($gstat,$glimit,$DoMatrix,$gstep);
    } elsif ($GraphMethod == 3) {
	PrintStats3($gstat,$gwindow_size,$glimit,$DoMatrix,$gstep);
    } else {
	die "Bad examplegraph kind: $GraphMethod";
    }
}
