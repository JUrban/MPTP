#!/usr/bin/perl -w
#------------------------------------------------------------------------
#
# File  : mkproblem.pl ( Problem generating script for MPTP)
#
# Author: Josef Urban
#
# Gets a list of options and a list of theorem names or
# checker problem names (in our format, e.g. "t39_absvalue" or
# "by_25_16_absvalue"), and produces
# a complete dfg file for each of them. This file
# contains full informations necessary for reproval,
# i.e. the references and all of the background
# info (constructor types, requirements, etc.).
#
# Problem files are stored under their articles' directories.
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
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
my (@tharticles, @chkarticles); # do all problems for these


my $gaddme = 1;  # Tells to add article to its env. directives

sub Usage 
{
    print "Need a list of problem names like 't39_absvalue' for 
theorem problems and 'by_25_16_2_absvalue' for checker problems.\nUse the -t option (e.g. -tcard_1 -treal_1) to do all theorems for an article, and the -c option to do all checker problems for an article.\nUse the -b option to override the MPTPDIR variable.";
    exit;
}


#------------------------------------------------------------------------
#  Function    : ProcessArgs()
#
#  Check the arguments - article names and theorem numbers.
#
#  Input       : -
#  Global Vars : %gcnt, @ARGV, %gproblems, 
#  Side Effects: Can die, loads %gproblems
#------------------------------------------------------------------------

sub  ProcessArgs
{
    my ($arg, $thnr, $an);

    foreach $arg (@ARGV)
    {
	if ($arg =~ /t(\d+)_(\w+)/)
	{
	    $thnr = $1;
	    $an   = $2;

	    exists $gcnt{$an} or 
		die "Article $an unknown, add it into db!";
	    $thnr <= $gcnt{$an}->{'THE'} or 
		die "$thnr is greater than the max. theorem number for $an";

	    $gproblems{$an}{'THE'}{$thnr} = ();
#	    push @{ $gproblems{$an}{'THE'}}, $thnr;
	}

	elsif ($arg =~ /by_(\d+)_(\d+)_(\d+)_(\w+)/)
	{
	    exists $gcnt{$4} or 
		die "Article $3 unknown, add it into db!";
	    $3 <= $gcnt{$4}->{'CHK'} or 
		die "$3 is greater than the max. checker problem number for $an";
	    $gproblems{$4}{'CHK'}{$3} = $arg;
#	    push @{ $gproblems{$4}{'CHK'}}, $arg;
	}

	else
	{
	    Usage();
	}
    }
}


sub AddWholeArticles
{
    my ($an, $i);

    foreach $an (@chkarticles)
    {
	exists $gcnt{$an} or 
	    die "Article $an unknown, add it into db!";

	for($i = 1; $i <= $gcnt{$an}->{'CHK'}; $i++)
	{
	    $gproblems{$an}{'CHK'}{$i} = ()
		unless(exists $gproblems{$an}{'CHK'}{$i});
	}
    }


    foreach $an (@tharticles)
    {
	exists $gcnt{$an} or 
	    die "Article $an unknown, add it into db!";

	for($i = 1; $i <= $gcnt{$an}->{'THE'}; $i++)
	{
	    $gproblems{$an}{'THE'}{$i} = ()
		unless(ThCanceled($i + $grcn{$an}->{'THE'} - 1));
	}
    }

}



#------------------------------------------------------------------------
#  Function    : CreateDirs()
#
#  Create the directories in %gproblems, probably can set %errno,
#  no checking now.
#
#  Input       : -
#  Global Vars : %gproblems
#  Side Effects: I/O
#------------------------------------------------------------------------

sub CreateDirs
{
    my $dir;

    foreach $dir (keys %gproblems)
    {
	mkdir $MPTPPROBLEMS.$dir;
    }
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
    my ($an,$nr,$prb,%refnbrs,$ref,$myfname,$chkrefs,
	$mybg,$mysymbols,$dirkind,$j,%bgcache,$pname);

    foreach $an (keys %gproblems)
    {
	undef %bgcache;

      TH: foreach $nr ( sort {$a <=> $b} (keys %{$gproblems{$an}{'THE'}}) )
      {
	  %refnbrs = GetThRefs($an, $nr);
	  
	  if(! (exists $refnbrs{'THE'}))
	  {
	      print "Problem t$nr\_$an ignored, unexported references\n"
		  if(GWATCHED & WATCH_BADREFS);

	      next TH;
	  }

	  ($mybg, $mysymbols) = 
	      FilterBg('THE', \%refnbrs, $gproblems{$an}{'BG'}, \%bgcache);

	  $mysymbols = GroupDfgSymbols($mysymbols);
#	  $mybg = $gproblems{$an}{'BG'};
#	  $mysymbols = GetSymbols( $mybg, \%refnbrs);
	  $myfname = $MPTPPROBLEMS.$an."/t".$nr."_".$an.".dfg";

	  PrintDfgProblem('THE', $myfname, "t".$nr."_".$an, 
			  $mysymbols, $mybg, \%refnbrs);
      }

	if( exists $gproblems{$an}{'CHK'} )  
	{
	    OpenChkDb($an);
	
	  CHK: foreach $prb (sort {$a<=>$b} keys %{$gproblems{$an}{'CHK'}})
	  {
#	      $prb =~ /by_(\d+)_(\d+)_(\d+)_(\w+)/;
	      ($pname, $chkrefs)  = GetChkRefs($an, $prb);

# assert($prb eq $pname);

	      ($mybg, $mysymbols) = 
		  FilterBg('CHK', $chkrefs, 
			   $gproblems{$an}{'BG'}, \%bgcache);

	      $mysymbols = GroupDfgSymbols($mysymbols);
#	  $mybg = $gproblems{$an}{'BG'};
#	  $mysymbols = GetSymbols( $mybg, \%refnbrs);
	      $myfname = $MPTPPROBLEMS.$an."/".$pname.".dfg";

	      PrintDfgProblem('CHK', $myfname, $pname, 
			      $mysymbols, $mybg, $chkrefs);
	  }

	    CloseChkDb($an);
	}



    }
}



Getopt::Long::Configure ("bundling");

GetOptions('skipbadrefs|s:i'   => \$SkipBadThRefsProblems,
	   'allownonex|a:i'    => \$AllowNonExistant,
	   'basedir|b=s'     => \$MPTPDIR,
	   'memlimit|m=i'    => \$DBMEMLIMIT,
	   'tharticles|t=s'  => \@tharticles,
	   'chkarticles|c=s' => \@chkarticles)
    or Usage();


if (($#ARGV < 0) && ($#tharticles < 0) && ($#chkarticles < 0)) 
{
    Usage();
}

die "Set the MPTPDIR shell variable, or run with the -b option"
    if("/" eq $MPTPDIR);


LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

ProcessArgs();
OpenDbs();
AddWholeArticles();

# print (keys %gproblems);
CreateDirs();

PrepareBgs();

DoProblems();
