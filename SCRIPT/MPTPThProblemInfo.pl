#!/usr/bin/perl -w
#------------------------------------------------------------------------
#
# File  : MPTPThProblemInfo.pl (Create thprobleminfo.db)
#
# Author: Josef Urban
#
# Creates thprobleminfo.db, indexed as theorems.db,
# and containing additional info about the problems 
# created from the theorems. This is used later e.g.
# for the SQL probleminfo table (together with refereces.db).
# Output fields now:
#  bg_references		BLOB,		/* List of their names */
#  conjecture_syms	BLOB,
#  direct_refs_syms	BLOB,
#  problem_syms		BLOB,			/* All symbols */
#
#
# Changes
#
# <1> Tue Mar 18 20:37:55 2003
#     New
#------------------------------------------------------------------------
use strict;
use Getopt::Long;
use MPTPDebug;
use MPTPUtils;
use MPTPSgnFilter;

our (
     %gproblems
#     %th_problems, 
#     %chk_problems
    );

undef %gproblems;

my $gaddme = 1;  # Tells to add article to its env. directives
my $outputdb = $MPTPDB."thprobleminfo.db";


sub Usage 
{
    print " Creates thprobleminfo.db, indexed as theorems.db,
 and containing additional info about the problems 
 created from the theorems. This is used later e.g.
 for the SQL probleminfo table (together with refereces.db).
 Takes the list of mml articles as arguments - should correspond
 to articles in theorems.db.
 Use the -b option to override the MPTPDIR variable.";
    exit;
}

Getopt::Long::Configure ("bundling");

GetOptions('basedir|b=s'     => \$MPTPDIR,
	   'memlimit|m=i'    => \$DBMEMLIMIT)
    or Usage();


if ($#ARGV <= 0)
{
    Usage();
}

# my $mmllar = $ARGV[0];

$SkipBadThRefsProblems = 0;  # Do symbols for thhes with bad refs too


#------------------------------------------------------------------------
#  Function    : AddWholeArticles()
#
#  Add the theorems to be process
#
#  Input       : -
#  Global Vars : %gcnt, @ARGV, %gproblems, 
#  Side Effects: Can die, loads %gproblems
#------------------------------------------------------------------------
sub AddWholeArticles
{
    my ($i);

#    open(IN, $mmllar) or die "Input file unreadable";

    while($_ = shift @ARGV)
    {
	exists $gcnt{$_} or 
	    die "Article $_ unknown, add it into db!";

	for($i = 1; $i <= $gcnt{$_}->{'THE'}; $i++)
	{
	    $gproblems{$_}{'THE'}{$i} = ();
#		unless(ThCanceled($i + $grcn{$_}->{'THE'} - 1));
	}
    }
#    close(IN);
}
    
sub PrepareBgs
{
    my $key;

    foreach $key (keys %gproblems)
    {
	$gproblems{$key}{'BG'} = CreateBg($key, $gaddme);
    }
}

#------------------------------------------------------------------------
#  Function    : PrintProblemInfo()
#
#  Print one line of thprobleminfo
#
#  Input       : -
#  Global Vars : %D, OUT
#  Side Effects: Can die, I/O
#------------------------------------------------------------------------

sub PrintProblemInfo
{
    my ($tname, $mybg, $conj_syms, $refsyms, $allsyms) = @_;
    my ($j, $k, $sym, $bgkind);

    print OUT ("probleminfo(",$tname,",[");

    if(defined %$mybg)
    {
	$k = 0;
	foreach $bgkind (@GBGTOKENS)
	{
	    if(exists $mybg->{$bgkind})
	    {
		foreach $j (sort {$a <=> $b} @{ $mybg->{$bgkind}})
		{	
		    $D{$bgkind}[$j] =~ m/^\s*formula\(.*\n(\w+)\)$/s
			or die "Bad $bgkind fla at $j:$D{$bgkind}[$j]\n";

		    print OUT "," if($k++ > 0);
		    print OUT $1;
		}
	    }
	}

	foreach $sym ( keys %{ $mybg->{'NDB'}})
	{	
	    print OUT "," if($k++ > 0);
	    print OUT $sym;
	}
    }
    print OUT "],[";
    print OUT join(",", (sort keys %$conj_syms));
    print OUT "],[";
    print OUT join(",", (sort keys %$refsyms));
    print OUT "],[";
    print OUT join(",", (sort keys %$allsyms));
    print OUT "]).\n";
}

#------------------------------------------------------------------------
#  Function    : DoProblems()
#
#  Create the problems. The existence check is supposed
#  to be done before calling this. 
#
#  Input       : problem references, article background theory
#  Global Vars : %gcnt, %GNTOKENS
#  Output      : filtered background theory
#  Side Effects: I/O
#------------------------------------------------------------------------

sub DoProblems
{
    my ($an,$nr,$prb,%refnbrs,$ref,$chkrefs, $mybg,
	$mysymbols,$dirkind,$j,%bgcache,$conj_syms,%refsyms,%oldsyms);

    open(OUT, ">$outputdb") or die "$outputdb not writable!";

    foreach $an (sort {$gcnt{$a}->{'ORD'} <=> $gcnt{$b}->{'ORD'}} 
		 keys %gproblems)
    {
	undef %bgcache;

      TH: foreach $nr ( sort {$a <=> $b} (keys %{$gproblems{$an}{'THE'}}) )
      {
	  %refsyms = ();      
	  %oldsyms = ();  

	  if(ThCanceled($nr + $grcn{$an}->{'THE'} - 1))
	  {
	      %$mybg = ();                     # bg_references
	      %$conj_syms = ();                 # conjecture_syms
	      %$mysymbols = ();                 # problem_syms		

	      PrintProblemInfo("t$nr"."_canceled_".$an, $mybg, 
			       $conj_syms, \%refsyms, $mysymbols);
	      next TH;
	  }

	  %refnbrs = GetThRefs($an, $nr);

	  $D{'THE'}[$refnbrs{'THE'}[0]] =~ m/^\s*formula\((.*)\n\w+\)$/s
	      or die "Bad THE fla at $refnbrs{'THE'}[0]\n";
	  
	  $conj_syms =  CollectSymbols($1);
	  
#  	  if(! (exists $refnbrs{'THE'}))
#  	  {
#  	      print "Problem t$nr\_$an ignored, unexported references\n"
#  		  if(GWATCHED & WATCH_BADREFS);

#  	      PrintProblemInfo("t$nr_$an", $mybg, $conj_syms,
#  			       \%refsyms, $mysymbols);
#  	      next TH;
#  	  }

	  GetDirectSyms('THE', \%refnbrs, \%refsyms);
	  @oldsyms{ (keys %refsyms) } = ();  # save a copy


	  ($mybg, $mysymbols) = FilterBgWithSyms($gproblems{$an}{'BG'}, 
						 \%bgcache, \%refsyms);
	  PrintProblemInfo("t$nr"."_".$an, $mybg, $conj_syms,
			   \%oldsyms, $mysymbols);

      }
    }
    close(OUT);
}


LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

OpenDbs();
AddWholeArticles();

# print (keys %gproblems);

PrepareBgs();

DoProblems();

