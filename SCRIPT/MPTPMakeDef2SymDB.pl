#!/usr/bin/perl -w

=head1 NAME

MPTPMakeDef2SymDB.pl ( Create file associating definitions with symbols defined )

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut

use strict;
use Getopt::Long;
use Pod::Usage;
use MPTPDebug;
use MPTPUtils;
use MPTPSgnFilter;


#------------------------------------------------------------------------
#  Function    : GetFirstSymbol()
#
#  Get the first nonvariable user symbol from a string.
#  
#  Assumptions: 
#   We split on non-word characters, so no dfg or user symbol
#   may contain them, and every word character is part of some
#   dfg or user symbol. All variables start with a capital letter.
#
#  Input       : string containing dfg and user symbols
#  Global Vars : -
#  Output      : the first symbol
#------------------------------------------------------------------------

my %gignored_hash;
@gignored_hash{ @GIGNORED } = ();

sub GetFirstSymbol
{
    my @symbols;
    my $i   = -1;
    my $bad = 1;
    

    @symbols = (split /\W+/, $_[0]);

    while($bad && (++$i <= $#symbols))
    {
	$bad = ((exists $gignored_hash{$symbols[$i]}) || 
		($symbols[$i] =~ m/^[A-Z].*/));
    }

    if($bad)
    {
	$i = ("" eq $symbols[0])? 2 : 1;

	die "No symbol found in: $_[0],$symbols[0],$symbols[1]"
	    unless(("not" eq $symbols[$i-1]) && ("equal" eq $symbols[$i]))
    }
    return $symbols[$i];
}


# ##REQUIRE: first symbol in the last def line is the defined symbol.
# Problem is that some definitions redefine "equal".
# ###TODO: The loop now goes only to last-but-one item,
#          since the last is a newline - fix this in MPTP0.2
sub PrintDefSymbols
{
    my $i = -1;
    my ($content, $nr, $aname, $dname, $first_symbol);

 ONE: while (exists $D{'DEF'}[++$i+1])
    {
	$D{'DEF'}[$i]         =~ m/^\s*formula\((.*)\nd(\d+)_(\w+)\)$/s
	    or die "Bad DEF fla at $i:$D{'DEF'}[$i],$1,$2,$3\n\n\n";
	
	($content, $nr, $aname)      =  ($1, $2, $3);
	
	$dname = "d".$nr."_".$aname;

	if($aname =~ /^canceled_.*$/)
	{
	    print DEFSYMS "\ndefines($dname,_).";
	    next ONE;
	}

	$content   =~ m/\n([^\n]+)$/s or die "Bad DEF fla at $i:$_";

	$first_symbol = GetFirstSymbol($1);

	print DEFSYMS "\ndefines($dname,$first_symbol).";
    }
}


die "Set the MPTPDIR shell variable"
    if ("/" eq $MPTPDIR);

die "The defsymbols database already exists, remove it manually first"
    if (-r $MPTPDB."defsymbols.db");

LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

OpenDbs();

open(DEFSYMS, ">".$MPTPDB."defsymbols.db");

PrintDefSymbols();
close(DEFSYMS);
