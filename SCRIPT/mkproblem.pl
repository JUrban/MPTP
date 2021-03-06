#!/usr/bin/perl -w

=head1 NAME

mkproblem.pl ( Problem generating script for MPTP)

=head1 SYNOPSIS

mkproblem.pl [options] problemnames

mkproblem.pl -tcard_1 -trolle -ccard_2 t39_absvalue by_25_16_2_absvalue

 Options:
   --skipbadrefs[=<arg>],   -s[<arg>]
   --allownonex[=<arg>],    -a[<arg>]
   --basedir=<arg>,         -b<arg>
   --mml_version=<arg>,     -T<arg>
   --memlimit=<arg>,        -M<arg>
   --tharticles=<arg>,      -t<arg>
   --chkarticles=<arg>,     -c<arg>
   --filter=<arg>,          -f<arg>
   --definitions=<arg>,     -D<arg>
   --specfile=<arg>,        -F<arg>
   --allarticles,           -A
   --help,                  -h
   --man

=head1 OPTIONS

=over 8

=item B<<< --skipbadrefs[=<arg>], -s[<arg>] >>>

Skip problems with bad references.

=item B<<< --allownonex[=<arg>], -a[<arg>] >>>

Setting to 0 causes error exit on nonexistant articles.

=item B<<< --basedir=<arg>, -b<arg> >>>

Sets the MPTPDIR to <arg>.

=item B<<< --mml_version=<arg>, -B<T><arg> >>>

Force mkproblem to behave as if working with MML version <arg>.
This now influences only how the non-database type assertions for
numerals are created. Generally, this may influence creation
of any formulas covering various Mizar built-in features in the
future, as they often change across various MML versions.
The <arg> is written in the form 3_44_763, and for
normal usage of the MPTP distribution, the default is OK.
Use this, if you only want to update the MPTP scripts, without
updating the databases to newer MML version.

=item B<<< --memlimit=<arg>, -ME<lt>arg> >>>

Sets memory limit for database caches, not implemented yet.

=item B<<< --tharticles=<arg>, -t<arg> >>>

Do all theorem problems from the article <arg>, this option can be 
repeated to specify multiple articles.

=item B<<< --chkarticles=<arg>, -c<arg> >>>

Do all checker problems from the article <arg>, this option can be 
repeated to specify multiple articles.

=item B<<< --filter=<arg>, -f<arg> >>>

Specify the filtering of the background formulas. 
Default is now 1 - the checker-based signature filtering. 
Setting to 0 does no filtering at all.

=item B<<< --definitions=<arg>, -B<D><arg> >>>

Specify treatment of definitions.
Default is now 0 - the 'definitions' directive is neglected
and definitions must be explicitely specified as references
to be included as axioms for the problems.
1 means that all definitions from the 'definitions' directive
are included as direct references.
2 is like 1, but only definitions from the current article
are used.
3 is as 1, but the definitions are treated as background formulas
instead, i.e. if filtering is activated, they are included only
if the defined symbols appear during the fixpoint computation.
4 is like 3, again with current article definitions only.
Options 2 or 4 are useful when we know that the definitions from
other articles have been taken care of explicitly (e.g. by some
previous experience like Mizar Proof Advisor), but this does not
extend to the current article, which may be new in some sense.

=item B<<< --specfile=<arg>, -B<F><arg> >>>

Read problem specifications from the file <arg>.

=item B<<< --allarticles, -B<A> >>>

Create theorem problems for all articles that are present in
databases.

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 DESCRIPTION

B<mkproblem.pl> gets a list of options and a list of theorem names or
checker problem names (in our format, e.g. t39_absvalue or
by_25_16_2_absvalue), and produces a complete dfg file 
for each of them. This file contains full informations 
necessary for reproval, i.e. the references and all of the background
info (constructor types, requirements, etc.).
Problem files are stored under their articles directories,
in the PROBLEMS directory.

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut

#------------------------------------------------------------------------
#
# File  : mkproblem.pl 
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
use Pod::Usage;
use MPTPDebug;
use MPTPUtils;
use MPTPSgnFilter;


our (
     %gproblems
     #     %th_problems, 
     #     %chk_problems
    );


# %gproblems has for each article following slots:
# 'BG'  - background theory
# 'THE' - theoem problems
# 'CHK' - checker problems
# 'DEF' - definitions moved here from 'BG', if $DEFINITIONS is of some REFS kind
undef %gproblems;
my ($help, $man, @tharticles, @chkarticles); # do all problems for these


my $gaddme = 1;			# Tells to add article to its env. directives
my $FILTER = 1;
my $DEFINITIONS = 0;
my $ProblemSpecFile;            # Input file containing problem specifications
my $DoAllArticles = 0;          # Do all articles in %gcnt

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
#  Global Vars : %gcnt, @ARGV, %gproblems, $ProblemSpecFile
#  Side Effects: Can die, loads %gproblems
#------------------------------------------------------------------------

sub  ProcessArgs
{
    my ($arg, $thnr, $an);

    if(defined $ProblemSpecFile)
    {
	open(SPECFILE, $ProblemSpecFile) or
	    die "$ProblemSpecFile not readable!";

	while (<SPECFILE>) { ProcessArg($_); }
	close(SPECFILE);
    }

    foreach $arg (@ARGV) { ProcessArg($arg); }
}

#------------------------------------------------------------------------
#  Function    : ProcessArg()
#
#  Check the arguments - article names and theorem numbers.
#
#  Input       : -
#  Global Vars : %gcnt, @ARGV, %gproblems, 
#  Side Effects: Can die, loads %gproblems
#------------------------------------------------------------------------

sub  ProcessArg
{
    my ($arg) = @_;
    my ($thnr, $an);

    if ($arg =~ /t(\d+)_(\w+)(\[.*\])?$/)
    {
	$thnr = $1;
	$an   = $2;

	exists $gcnt{$an} or 
	    die "Article $an unknown, add it into db!";
	$thnr <= $gcnt{$an}->{'THE'} or 
	    die "$thnr is greater than the max. theorem number for $an";

	$gproblems{$an}{'THE'}{$thnr} = (defined $3) ? $3 : ();
    }

    elsif ($arg =~ /by_(\d+)_(\d+)_(\d+)_(\w+)/)
    {
	exists $gcnt{$4} or 
	    die "Article $3 unknown, add it into db!";
	$3 <= $gcnt{$4}->{'CHK'} or 
	    die "$3 is greater than the max. checker problem number for $an";
	$gproblems{$4}{'CHK'}{$3} = $arg;
    }

    else
    {
	Usage();
    }
}



sub AddWholeArticles
{
    my ($an, $i);

    foreach $an (@chkarticles)
    {
	exists $gcnt{$an} or 
	    die "Article $an unknown, add it into db!";

	for ($i = 1; $i <= $gcnt{$an}->{'CHK'}; $i++)
	{
	    $gproblems{$an}{'CHK'}{$i} = ()
		unless (exists $gproblems{$an}{'CHK'}{$i});
	}
    }


    foreach $an (@tharticles)
    {
	exists $gcnt{$an} or 
	    die "Article $an unknown, add it into db!";

	for ($i = 1; $i <= $gcnt{$an}->{'THE'}; $i++)
	{
	    $gproblems{$an}{'THE'}{$i} = ()
		unless (ThCanceled($i + $grcn{$an}->{'THE'} - 1));
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
	$gproblems{$key}{'BG'} = CreateBg($key, $gaddme, $DEFINITIONS);


	if(($DEFINITIONS == DEFS_ALL_AS_REFS) 
	   || ($DEFINITIONS == DEFS_SELF_AS_REFS))
	{
	    $gproblems{$key}{'DEF'} = $gproblems{$key}{'BG'}->{'DEF'};
	    delete $gproblems{$key}{'BG'}->{'DEF'};
	}
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
	$mybg,$mysymbols,$dirkind,$j,%bgcache,%bgsyms,$pname);

    foreach $an (sort {$gcnt{$a}->{'ORD'} <=> $gcnt{$b}->{'ORD'}} 
		 keys %gproblems)
    {
	undef %bgcache;
	undef %bgsyms;

	if ($FILTER == 0)
	{
	    $mybg      = $gproblems{$an}{'BG'};
	    GetAllBgSyms($mybg, \%bgsyms);     # OK for any kind of $DEFINITIONS
	}

    TH: foreach $nr ( sort {$a <=> $b} (keys %{$gproblems{$an}{'THE'}}) )
	{
	    %refnbrs = GetThRefs($an, $nr, $gproblems{$an}{'THE'}{$nr});

	    if(exists $gproblems{$an}{'DEF'})  # Add the DEFS if as REFS
	    {
		my $value;
		my %tmp_hash = ();

		@tmp_hash{ @{$refnbrs{'DEF'}} } = ()
		    if(exists $refnbrs{'DEF'});

		foreach $value (@{ $gproblems{$an}{'DEF'}})
		{
		    (exists $tmp_hash{$value}) or push( @{$refnbrs{'DEF'}}, $value);
                }
	    }

	    if (! (exists $refnbrs{'THE'}))
	    {
		print "Problem t$nr\_$an ignored, unexported references\n"
		    if (GWATCHED & WATCH_BADREFS);

		next TH;
	    }

	    if ($FILTER == 0)  # OK for any kind of $DEFINITIONS
	    {
		$mysymbols = AddSymsAndSpecials('THE', \%refnbrs,
						$mybg, \%bgsyms);
	    }
	    else
	    {
		($mybg, $mysymbols) = FilterBg('THE', \%refnbrs,
					       $gproblems{$an}{'BG'}, \%bgcache);
		$mysymbols = GroupDfgSymbols($mysymbols);
	    }

	    $myfname = $MPTPPROBLEMS.$an."/t".$nr."_".$an.".dfg";

	    PrintDfgProblem('THE', $myfname, "t".$nr."_".$an, 
			    $mysymbols, $mybg, \%refnbrs);

	    undef $mybg->{'NDB'} if ($FILTER == 0);
	}

	if ( exists $gproblems{$an}{'CHK'} )
	{
	    OpenChkDb($an);

	CHK: foreach $prb (sort {$a<=>$b} keys %{$gproblems{$an}{'CHK'}})
	    {
		#	      $prb =~ /by_(\d+)_(\d+)_(\d+)_(\w+)/;
		($pname, $chkrefs)  = GetChkRefs($an, $prb);

		# assert($prb eq $pname);

		if ($FILTER == 0)
		{
		    $mysymbols = AddSymsAndSpecials('CHK', $chkrefs,
						    $mybg, \%bgsyms);
		}
		else
		{

		    ($mybg, $mysymbols)	 =
			FilterBg('CHK', $chkrefs,
				 $gproblems{$an}{'BG'}, \%bgcache);
		    $mysymbols		 = GroupDfgSymbols($mysymbols);
		}

		$myfname = $MPTPPROBLEMS.$an."/".$pname.".dfg";

		PrintDfgProblem('CHK', $myfname, $pname, 
				$mysymbols, $mybg, $chkrefs);

		undef $mybg->{'NDB'} if ($FILTER == 0);
	    }

	    CloseChkDb($an);
	}



    }
}



Getopt::Long::Configure ("bundling","no_ignore_case");

GetOptions('skipbadrefs|s:i'   => \$SkipBadThRefsProblems,
	   'allownonex|a:i'    => \$AllowNonExistant,
	   'basedir|b=s'     => \$MPTPDIR,
	   'mml_version|T=s' => \$GMML_VERSION,
	   'memlimit|M=i'    => \$DBMEMLIMIT,
	   'tharticles|t=s'  => \@tharticles,
	   'chkarticles|c=s' => \@chkarticles,
	   'filter|f=i'      => \$FILTER,
	   'definitions|D=i' => \$DEFINITIONS,
	   'specfile|F=s'    => \$ProblemSpecFile,
	   'allarticles|A'   => \$DoAllArticles,
	   'help|h'          => \$help,
	   'man'             => \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);
pod2usage(2) 
    if (($#ARGV < 0) && !(defined $ProblemSpecFile) 
	&& ($#tharticles < 0) && ($#chkarticles < 0)
	&& !($DoAllArticles)); 

pod2usage(2) if($DEFINITIONS > DEFS_SELF_AS_BG);

die "Set the MPTPDIR shell variable, or run with the -b option"
    if ("/" eq $MPTPDIR);


LoadCounts();

PrintCnts() if(GWATCHED & WATCH_COUNTS);
PrintRcns() if(GWATCHED & WATCH_COUNTS);

if($DoAllArticles)
{
    @tharticles = (sort {$gcnt{$a}->{'ORD'} <=> $gcnt{$b}->{'ORD'}}
		   keys %gcnt)
}

ProcessArgs();
OpenDbs();
AddWholeArticles();

# print (keys %gproblems);
CreateDirs();

PrepareBgs();

DoProblems();

__END__
