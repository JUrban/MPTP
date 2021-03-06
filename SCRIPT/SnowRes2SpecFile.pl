#!/usr/bin/perl -w

=head1 NAME


SnowRes2SpecFile.pl ( Snow predictions to mkproblem's input )

=head1 SYNOPSIS

  # Train snow with Naive Bayes targets 0-41079 on $NAME.train,
  # test then on $NAME.test, limiting prediction output to 100 best hits,
  # create problem specifications taking the best 30 predictions as axioms,
  # create the problems according to the specifications

 snow -train -I $NAME.train -F $NAME.net -B :0-41079
 snow -test -o allboth -I $NAME.test -F $NAME.net -B :0-41079 | LimitSnow.pl 100 > $NAME.res
 SnowRes2SpecFile.pl -l30 -r$NAME.refnr <$NAME.res > $NAME.spec
 mkproblem.pl -F $NAME.spec

 Options:
   --reftable=<arg>,        -r<arg>
   --limit=<arg>,           -l<arg>
   --help,                  -h
   --man

=head1 OPTIONS

=over 8

=item B<<< --reftable=<arg>, -r<arg> >>>

Mandatory argument giving the translation table for references 
(.refnr), this file is produced by the MPTPMakeSnowDB.pl 
data generating script, when preparing learning.

=item B<<< --limit=<arg>, -l<arg> >>>

Limit the number of Snow predictions used as axioms to
this value.

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 DESCRIPTION

Output on stdout B<mkproblem.pl>'s problem specification file
created from the Snow predictions (result file).
We assume that the first reference in the 'Example' header is
the target, which is correct for current version of Snow (3.0.3).

=cut

use strict;
use Pod::Usage;
use Getopt::Long;
use MPTPDebug;
use MPTPUtils;
use MPTPSgnFilter;

my $glimit;     # How many references we want
my $reftable;   # Translation table for references (*.refnr),
                # one refname in line, 0-based

my $gonly_smaller_refs = 1;   # Only smaller refs are allowed
my $gone_setof = 1;           # Allow at most one reference containing "setof"

my @gnrref;     # Nr2Ref array for references

my ($help, $man);
Getopt::Long::Configure ("bundling");

GetOptions('reftable|r=s'    => \$reftable,
	   'limit|l=i'       => \$glimit,
	   'help|h'          => \$help,
	   'man'             => \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);

pod2usage(2) unless (defined $reftable);

$glimit    = 30 unless(defined($glimit));

LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

OpenDbs();

# Load refnr
open(REFNR, "$reftable") or die "Cannot read refnr file";
while($_=<REFNR>) { chop; push(@gnrref, $_); };
close REFNR;



sub LOG_SETOF () { 1 }

open(SETOF_REPORT, ">setofs.report") if LOG_SETOF;



sub ArticleDef
{
   my ($axiom, $target) = @_;
   my $ax_name = $gnrref[$axiom];
   my $tg_name = $gnrref[$target];
   my ($nr, $an);

   $ax_name =~ /^([dt])(\d+)_(\w+)$/  or die "Bad ref: $ax_name at $axiom";

   if('t' eq $1) {return 0;}

   ($nr, $an) = ($2, $3);
   $tg_name =~ /^t(\d+)_(\w+)$/  or die "Bad ref: $tg_name at $axiom";

   return ($2 eq $an);
}

sub CheckSetof
{
   my ($axiom) = @_;
   my $name = $gnrref[$axiom];
   my ($rkind, $nr, $an, $rpos, $content, $conj_syms);

   $name =~ /^([dt])(\d+)_(\w+)$/  or die "Bad ref: $name at $axiom";

   $rkind = ('d' eq $1) ? 'DEF' : 'THE';
   ($nr, $an) = ($2, $3);
   $rpos   = $nr + $grcn{$an}->{$rkind} - 1;
   $D{$rkind}[$rpos]         =~ m/^\s*formula\((.*)\n[dt](\d+)_(\w+)\)$/s
           or die "Bad $rkind fla at $rpos:$_,$1,$2,$3\n";

   $content      =  $1;

   $conj_syms =  CollectSymbols($content);

   print SETOF_REPORT "setof in $name\n"
     if(LOG_SETOF && (exists $conj_syms->{'setof'}));

   return (exists $conj_syms->{'setof'});
}


sub SetofOK
{
   my ($axiom,$setof_count) = @_;
   my $res = CheckSetof($axiom);

   $$setof_count += ($res)? 1 : 0;

   print SETOF_REPORT "rejecting\n"
     if(LOG_SETOF && ($res && ($$setof_count > 1)));

   return  (!($res) || ($$setof_count < 2));
}

# Skip to the first example
do { $_=<> } while($_ && !($_=~/Example/));

die "STDIN contains no example predictions!"
    unless ($_=~/Example/);


my @predictions = ();
my $target = 0;
my $setof_count;
my $gexample_nr = 0;

while ($_)
{
    if (/Example/)        # Start a new example
    {
	if($gexample_nr++ > 0)   # cleanup the previous if any
	{
	    print (join(",", @predictions), "]\n");
	}

	@predictions = ();

	/Example.*:(.*)/ or die "Bad Example $_";
	my @wanted = split /\, /, $1;
	$target = $wanted[0];

	die "Target $target has no name in $reftable!"
	    unless (exists $gnrref[$target]);

	if($gone_setof)
	{
	  $setof_count = (CheckSetof($target))? 1 : 0;
	}
	  

	print ($gnrref[$target], "[");
    }
    else
    {
	/^(\d+):.*/ or die "Bad prediction: $_";
	my $axiom = $1;
	die "Reference $axiom has no name in $reftable!"
	    unless (defined $gnrref[$axiom]);

	if(((1+$#predictions) < $glimit)
	   && (!($gonly_smaller_refs) || ($axiom < $target) || ArticleDef($axiom,$target))
	   && (!($gone_setof) || SetofOK($axiom,\$setof_count)))
	{
	    push(@predictions, $gnrref[$axiom]);
	}
    }
    $_=<>;
}

if($gexample_nr > 0)   # cleanup the last one
{
    print (join(",", @predictions), "]\n");
}
