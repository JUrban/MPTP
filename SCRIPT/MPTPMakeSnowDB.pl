#!/usr/bin/perl -w

=head1 NAME

MPTPMakeSnowDB.pl ( Data generating script for the Snow learning system)

=head1 SYNOPSIS

MPTPMakeSnowDB.pl [options]

 Options:
   --basedir=<arg>,         -b<arg>
   --help,                  -h
   --man

=head1 OPTIONS

=over 8

=item B<<< --basedir=<arg>, -b<arg> >>>

Sets the MPTPDIR to <arg>.

=item B<<< --memlimit=<arg>, -ME<lt>arg> >>>

Sets memory limit for database caches, not implemented yet.

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 DESCRIPTION

B<MPTPMakeSnowDB.pl> creates snowpinfo.db, indexed as theorems.db.
The feature numbering is derived from numbering of theroems and
definitions - symbol numbering atrts at offset 100000.
The output is: conjecture_symbols,direct_refernces:

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut
use strict;
use Getopt::Long;
use MPTPDebug;
use MPTPUtils;

my $fieldsepar  = ",";       # Snow field separator
my $linesepar   = ":\n";     # Snow line separator

my $refs   = $GFNAMES{'THR'};
my $pinfos = $MPTPDB."thprobleminfo.db";

my $gsymoffset=100000; # offset at which symbol numbering starts

my %grefnr;     # Ref2Nr hash for references
my @gnrref;     # Nr2Ref array for references

my %gsymnr;   # Sym2Nr hash for symbols
my @gnrsym;   # Nr2Sym array for symbols - takes gsymoffset into account!

=head2 AddNumbers()

  Title	       : AddNumbers()
  Usage	       : AddNumbers()
  Function     : Number theorems, definitions and symbols
  Returns      : -
  Global Vars  : %gcnt, @ARGV, %gproblems, %grefnr, @gnrref,%gsymnr,@gnrsym
  Args	       : -
  Side Effects : %grefnr,@gnrref,%gsymnr,@gnrsym
=cut
sub AddNumbers
{
    my ($an, $i, $j, $start, $end, $kind);

    foreach $an (sort {$gcnt{$a}->{'ORD'} <=> $gcnt{$b}->{'ORD'}}
		 keys %gcnt)
    {
	for ($i = 1; $i <= $gcnt{$an}->{'THE'}; $i++)
	{
	    push(@gnrref, "t$i"."_$an");
	    $grefnr{"t$i"."_$an"} = $#gnrref;
	}

	for ($i = 1; $i <= $gcnt{$an}->{'DEF'}; $i++)
	{
	    push(@gnrref, "d$i"."_$an");
	    $grefnr{"d$i"."_$an"} = $#gnrref;
	}

	foreach $kind ('DSF', 'DSP')
	{
	    $start = $grcn{$an}->{$kind};
	    $end   = $start + $gcnt{$an}->{$kind};

	    for ($j = $start; $j < $end; $j++)
	    {
		$D{$kind}[$j]  =~ m/^\W+arity\((\w+),(\d+)\)$/s;
		push(@gnrsym, $1);
		$gsymnr{$1}    = $gsymoffset + $#gnrsym;
	    }
	}
    }
}

sub Translate
{
    my ($ref,$pinfo);
 ONE: while($ref = <REFS>)
    {
	my ($tname, $aname, $thnr, $prf_length, $drefs, @dir_refs,
	    @bg_refs, @conj_syms, @refsyms, @allsyms);

	$pinfo = <PINFOS>; # or die "$refs and $pinfos not synchronized!";

	$ref =~ m/^references\((\w+),(\d+),(\d+),(\d+),\[([^\]]*)\]\)\.$/
	    or die "Bad references: $ref";

	($tname, $prf_length, $drefs) = ($1, $4, $5);
    
	$pinfo =~ /^probleminfo\((\w+),\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\]\)\.$/
	    or die "Bad probleminfo: $pinfo";

	($tname eq $1) or die "$refs and $pinfos not synchronized:$tname:$1";

	#    @bg_refs   = split(/\,/, $2);
	@conj_syms = map($gsymnr{$_}, (split(/\,/, $3)));
	#    @refsyms   = split(/\,/, $4);
	#    @allsyms   = split(/\,/, $5);

	@dir_refs  = map($grefnr{$_}, ($tname,split(/\,/, $drefs)));

	$tname     =~ /^t(\d+)_(\w+)$/ or die "Bad theorem: $tname";

	($thnr, $aname)  = ($1,$2);

	next ONE if($aname =~ /^canceled_.*$/); 

	print  join(",", @conj_syms),    $fieldsepar, 
	    join(",", @dir_refs),      $linesepar;
    }
}

my ($help, $man);
Getopt::Long::Configure ("bundling");

GetOptions('basedir|b=s'     => \$MPTPDIR,
	   'memlimit|m=i'    => \$DBMEMLIMIT,
	   'help|h'          => \$help,
	   'man'             => \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);

die "Set the MPTPDIR shell variable, or run with the -b option"
    if ("/" eq $MPTPDIR);

# pod2usage(2) if ($#ARGV <= 0)

$SkipBadThRefsProblems = 0;  # Do symbols for thhes with bad refs too



LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

OpenDbs();
AddNumbers();

open(REFS, $refs)     or die "$refs not readable!";
open(PINFOS, $pinfos) or die "$pinfos not readable!";

Translate();

