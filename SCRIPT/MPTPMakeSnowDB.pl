#!/usr/bin/perl -w

=head1 NAME

MPTPMakeSnowDB.pl ( Data generating script for the Snow learning system)

=head1 SYNOPSIS

MPTPMakeSnowDB.pl [options] filename

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

B<MPTPMakeSnowDB.pl> creates the training (filename.train) and 
architecture (filename.arch) files  for the Snow learning system.
The feature numbering is derived from numbering of theroems and
definitions - symbol numbering starts at offset 100000.
The output is: conjecture_symbols,direct_refernces:
Now also prints the symbol2number (.symnr) and ref2number (.refnr)
files - the numbering there is implicit.

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut
use strict;
use Pod::Usage;
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
	    if(!ThCanceled($i + $grcn{$an}->{'THE'} - 1))
	    {
		push(@gnrref, "t$i"."_$an");
		$grefnr{"t$i"."_$an"} = $#gnrref;
		print REFNR "t$i"."_$an\n";
	    }
	}

	for ($i = 1; $i <= $gcnt{$an}->{'DEF'}; $i++)
	{
	    push(@gnrref, "d$i"."_$an");
	    $grefnr{"d$i"."_$an"} = $#gnrref;
	    print REFNR "d$i"."_$an\n";
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
		print SYMNR "$1\n";
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
	    @dir_refs1, @bg_refs, @conj_syms, @conj_syms1, @refsyms, @allsyms);

	$pinfo = <PINFOS>; # or die "$refs and $pinfos not synchronized!";

	$ref =~ m/^references\((\w+),(\d+),(\d+),(\d+),\[([^\]]*)\]\)\.$/
	    or die "Bad references: $ref";

	($tname, $prf_length, $drefs) = ($1, $4, $5);
    
	$pinfo =~ /^probleminfo\((\w+),\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\]\)\.$/
	    or die "Bad probleminfo: $pinfo";

	($tname eq $1) or die "$refs and $pinfos not synchronized:$tname:$1";

	#    @bg_refs   = split(/\,/, $2);
	@conj_syms = map { $gsymnr{$_} if(exists($gsymnr{$_})) }
	                 (split(/\,/, $3));
	#    @refsyms   = split(/\,/, $4);
	#    @allsyms   = split(/\,/, $5);

	@dir_refs  = map { $grefnr{$_} if(exists($grefnr{$_})) }
			 ($tname,split(/\,/, $drefs));

	@conj_syms1 = ();
	foreach $_ (@conj_syms)
	{
	    push(@conj_syms1,$_) if("" ne $_);
	}

	@dir_refs1 = ();
	foreach $_ (@dir_refs)
	{
	    push(@dir_refs1,$_) if("" ne $_);
	}

	$tname     =~ /^t(\d+)_(\w+)$/ or die "Bad theorem: $tname";

	($thnr, $aname)  = ($1,$2);

	next ONE if($aname =~ /^canceled_.*$/); 

	if(-1 == $#conj_syms1)
	{
	    print "No symbols found in: $tname\n!";
	}
	else
	{
	    print TRAIN join(",", @conj_syms1),    $fieldsepar, 
		join(",", @dir_refs1),      $linesepar;
	}
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

pod2usage(2) if ($#ARGV != 0);

my $fname = shift @ARGV;

$SkipBadThRefsProblems = 0;  # Do symbols for thhes with bad refs too



LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

OpenDbs();


open(SYMNR, ">$fname.symnr") or die "$fname.symnr not writable!";
open(REFNR, ">$fname.refnr") or die "$fname.refnr not writable!";

AddNumbers();

open(REFS, $refs)     or die "$refs not readable!";
open(PINFOS, $pinfos) or die "$pinfos not readable!";
open(TRAIN, ">$fname.train") or die "$fname.train not writable!";
open(ARCH, ">$fname.arch") or die "$fname.arch not writable!";

Translate();

print ARCH "-W :0-$#gnrref\n";
