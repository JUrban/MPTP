#------------------------------------------------------------------------
#
# File  : MPTPUtils.pm ( Basic utilities for MPTP)
#
# Author: Josef Urban
#
# Provides access functions to the MPTP databases and
# basic problem creation functions.
# Utilities in this module are (and should be) independent of
# formula names (like "p1_r1_hidden") - these are important
# in the signature filter module (MPTPSgnFilter).
# Possible exception is lookup of checker problems.
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
#     New
#------------------------------------------------------------------------

package MPTPUtils;
use strict;
use warnings;
use DB_File;
use MPTPDebug;

our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    use Exporter   ();

    @ISA         = qw(Exporter);
    @EXPORT      = qw($MPTPDIR
		      $DBMEMLIMIT
		      $AllowNonExistant
		      $SkipBadThRefsProblems

		      $MPTPDB  
		      $MPTPBYS     
		      $MPTPPROBLEMS
		      $MPTPTMPDBDIR
		      %GFNAMES 
		      @GCNTOKENS   
		      @GDBTOKENS    
		      @GDIRTOKENS
		      @GBGTOKENS 
		      %GBGNAMES
		      %gcnt    
		      %grcn        
		      %garities
		      %D            

		      &LoadCounts
		      &OpenDbs
		      &OpenChkDb
		      &CloseChkDb
		      &Env2List
		      &CreateBg
		      &ThCanceled
		      &GetThRefs
		      &GetChkRefs
		      &Arity
		      &GroupDfgSymbols
		      &PrintDfgProblem
		      &PrintCnts
		      &PrintRcns
		      );
    @EXPORT_OK   = qw(%GDBINFOS
		      &LoadOneCnt
		      );
    %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}
use vars (@EXPORT, @EXPORT_OK);


# The directory with MPTP
$MPTPDIR       = $ENV{MPTPDIR}."/";

#$MPTPDIR       = "/g/miz_source/dbsupp1/dbtest/foo/";

# How much memory you want to give for db caching.
# Setting it to higher values increases speed, but only up to the
# overall size of all datbases :-).

$DBMEMLIMIT    = 10000000;      


# Set to 0 if you want error exit on nonexistant articles
$AllowNonExistant = 1;

# Set to 0 if problems with scheme or unexported references
# should not be skipped

$SkipBadThRefsProblems = 1;

# All other variables are internal, mess at your own risk

$MPTPDB        = $MPTPDIR."DB/";            # DB files
$MPTPBYS       = $MPTPDB."BYS/";            # Checker problem files    
$MPTPTMPDBDIR  = $MPTPDB."TMPDB/";          # temp. DB files
$MPTPPROBLEMS  = $MPTPDIR."PROBLEMS/";      # Checker problem files    


# Small performance hack for output of symbols
my $gsymbskip     = length("arity");


%GFNAMES       = (
    'THE'           , $MPTPDB."theorems.db",
    'DEF'           , $MPTPDB."definitions.db",
    'DCO'           , $MPTPDB."constrtypes.db",
    'DEM'           , $MPTPDB."exmodes.db",
    'PRO'           , $MPTPDB."properties.db",
    'CLE'           , $MPTPDB."exclusters.db",
    'CLF'           , $MPTPDB."funcclusters.db",
    'CLC'           , $MPTPDB."condclusters.db",
    'DSF'           , $MPTPDB."funcarities.db",
    'DSP'           , $MPTPDB."predarities.db",
    'THR'           , $MPTPDB."references.db",
    'DRE'           , $MPTPDB."requirements.db",
    'EVL'           , $MPTPDB."environments.db",
    'CNT'           , $MPTPDB."counts.db",
    'RCN'           , $MPTPDB."runningcounts.db"
    );


# The tokens we store counts for in (running)counts.db
@GCNTOKENS = ('THE','DEF','DCO','DEM','PRO','CLE',
	      'CLF','CLC','DSF','DSP','DRE','CHK');

# The tokens for databases
@GDBTOKENS = ('THE','DEF','DCO','DEM','PRO','CLE','CLF',
	      'CLC','DSF','DSP','THR','DRE','EVL');


# These are conveniences for directives

# dirVocabulary,dirNotations, dirDefinitions,dirTheorems,
# dirSchemes,dirClusters, dirConstructors,dirRequirements, dirProperties

# Order of environment directives in .evl (and thus $D{'EVL'}).
@GDIRTOKENS = ('VOC','DNO','DEF','THE','SCH','DCL','DCO','DRE','PRP');


# Background theory is expressed by these tokens.
# 'NDB' token is nonstandard, it is used for additional
# formulas (e.g. types of numbers) that cannot be in DB.
# 'SPC' is hidden completely, is used for keeping needed
# processing info, now just the requirement articles.
@GBGTOKENS  = ('DCO', 'DEM', 'PRO', 'CLE', 'CLF', 'CLC', 'DRE');

# Long names for pretty printing
%GBGNAMES   = 
    (
     'DCO', "Constructor types",
     'DEM', "Mode existence",
     'PRO', "Constructor properties",
     'CLE', "Existential clusters",
     'CLF', "Functor clusters",
     'CLC', "Conditional clusters",
     'DRE', "Requirements",
     'NDB', "Special non-DB formulas"
     );


# Counts
%gcnt       = ();  
%grcn       = ();   

# Fast arity cache - article symbols loaded on demand from db
%garities   = ();


#------------------------------------------------------------------------
#  Function    : LoadOneCnt()
#
#  Returns a new record containing the counts  
#
#  Input       : list of counts for one article
#------------------------------------------------------------------------

sub LoadOneCnt
{
    return {
	'THE' => $_[0],
	'DEF' => $_[1],
	'DCO' => $_[2],
	'DEM' => $_[3],
	'PRO' => $_[4],
	'CLE' => $_[5],
	'CLF' => $_[6],
	'CLC' => $_[7],
	'DSF' => $_[8],
	'DSP' => $_[9],
	'DRE' => $_[10],
	'CHK' => $_[11],
	'ORD' => $_[12]
	};
}


#------------------------------------------------------------------------
#  Function    : LoadCounts()
#
#  Loads the counts into %gcnt and %grcn from files.
#
#  Input       : -
#  Global Vars : %gcnt, %grcn, %GFNAMES
#  Side Effects: I/O
#------------------------------------------------------------------------

sub LoadCounts
{
    my $order = 0;

    undef %gcnt;
    keys(%gcnt) = 2047;     # There will be 1000 articles shortly :-)
    undef %grcn;
    keys(%grcn) = 2047;     

    open(LCNT, $GFNAMES{'CNT'}) or 
	die "$GFNAMES{'CNT'} not readable, database damaged!";

    while (<LCNT>) 
    {
	/counts[(](\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\w+)[)][.]/;
	$gcnt{$13} = LoadOneCnt $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$order;
	$order++;
    }
    close(LCNT);

    open(LRCN, $GFNAMES{'RCN'}) 
	or die "$GFNAMES{'RCN'} not readable, database damaged!";

    while (<LRCN>) 
    {
	/counts[(](\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\w+)[)][.]/;
	$grcn{$13} = LoadOneCnt $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$order;
	$order++;
    }
    close(LRCN);
}


#------------------------------------------------------------------------
#  Function    : PrintCnts()
#
#  Print %gcnt in exactly the format of counts.db;
#  only debugging now.
#
#  Input       : -
#  Global Vars : %gcnt, %GNTOKENS
#  Side Effects: I/O
#------------------------------------------------------------------------

sub PrintCnts
{
    my ($an, $i);

    foreach $an (sort {$gcnt{$a}->{'ORD'} <=> $gcnt{$b}->{'ORD'}} 
		 keys %gcnt)
    {
	printf "counts(";
	foreach $i (@GCNTOKENS)
	{
	    printf $gcnt{$an}->{$i}.",";
	}
	printf "$an).\n";
    }
}

#------------------------------------------------------------------------
#  Function    : PrintRcns()
#
#  Print %grcn in exactly the format of runningcounts.db;
#  only debugging now.
#
#  Input       : -
#  Global Vars : %grcn, %GNTOKENS
#  Side Effects: I/O
#------------------------------------------------------------------------

sub PrintRcns
{
    my ($an, $i);

    foreach $an (sort {$grcn{$a}->{'ORD'} <=> $grcn{$b}->{'ORD'}} 
		 keys %grcn)
    {
	printf "runningcounts(";
	foreach $i (@GCNTOKENS)
	{
	    printf $grcn{$an}->{$i}.",";
	}
	printf "$an).\n";
    }
}


#------------------------------------------------------------------------
#  Function    : OpenDbs()
#
#  Set the dbinfo for the databases and open them into $D{'THE'},$D{'DEF'},
#  etc. The cache should be set here!
#
#  Input       : -
#  Global Vars : @GDBTOKENS, %GDBINFOS, %D, %GFNAMES
#  Side Effects: I/O
#------------------------------------------------------------------------

sub OpenDbs
{

    my $dbkind;

    undef %GDBINFOS; # Infos for the dbs, e.g. for setting cachesizes
    undef %D;

    foreach $dbkind (@GDBTOKENS)
    {
	$GDBINFOS{$dbkind} =  new DB_File::RECNOINFO ;
	$GDBINFOS{$dbkind}->{'bval'} = ".";
	tie(@{$D{$dbkind}}, "DB_File", $GFNAMES{$dbkind}, 
	    O_RDWR, 0640, $GDBINFOS{$dbkind}) or 
		die "Nonexistant db!";
	print "$dbkind succesfully opened from $GFNAMES{$dbkind}\n"
	    if(GWATCHED & WATCH_DB);
    }

#    print $D{'THE'}[1] ;
}



#------------------------------------------------------------------------
#  Function    : OpenChkDb()
#
#  Open the article db of checker probllems.
#  The cache should be set here!
#
#  Input       : article name
#  Global Vars : %D
#  Side Effects: I/O
#------------------------------------------------------------------------

sub OpenChkDb
{
    my ($an) = @_;
    my ($absname, $dbname, $chkdbinfo); 
    
    $absname   = $MPTPBYS.$an.".bys.gz";
    $dbname    = $MPTPTMPDBDIR.$an.".bys";
    
    (0 == system(("gzip -dc ".$absname." > ".$dbname)))
	or die "Failed to uncompress $absname into $dbname: $?";

    print "$absname succesfully uncompressed to $dbname\n"
	if(GWATCHED & WATCH_DB);

    $chkdbinfo = new DB_File::RECNOINFO;    
    $chkdbinfo->{'bval'} = ".";

    tie(@{$D{'CHK'}}, "DB_File", $dbname, 
	O_RDWR, 0640, $chkdbinfo) or 
	    die "Nonexistant db!";
    
    print "CHK succesfully opened from $dbname\n"
	if(GWATCHED & WATCH_DB);

}


#------------------------------------------------------------------------
#  Function    : CloseChkDb()
#
#  Close the article db of checker probllems.
#
#  Input       : article name
#  Global Vars : %D
#  Side Effects: I/O
#------------------------------------------------------------------------

sub CloseChkDb
{
    my ($an) = @_;
    my ($absname, $dbname, $chkdbinfo); 
    
    $dbname    = $MPTPTMPDBDIR.$an.".bys";

    tied(@{$D{'CHK'}}) or die "Attempt to close nonopen db: $an\n";

    untie(@{$D{'CHK'}});
    undef(@{$D{'CHK'}});

    (0 == system(("rm -r -f ".$dbname)))
	or die "Failed to remove unused DB $dbname: $?";

    print "CHK in $dbname succesfully closed\n"
	if(GWATCHED & WATCH_DB);
}

#------------------------------------------------------------------------
#  Function    : Env2List()
#
#  Parse the record into a hash of lists. 
#  Requires that there are no spaces in the record.
#
#  Input       : number of one record in $D{'EVL'} (environment.db)
#  Global Vars : %gcnt, %GNTOKENS, %D
#  Side Effects: I/O
#------------------------------------------------------------------------

sub Env2List
{
    my ($ac)   = @_;
    my ($lstart, $lenv, %ldirs, @tmp, $i);

    $lstart = 1 + index($D{'EVL'}[$ac], '[');
    $lenv = substr($D{'EVL'}[$ac], $lstart); # Removes the first '[' too.
    chop($lenv); 
    chop($lenv);                       # Removes the last ']'.
#    print "$lenv\n";
    
    @tmp = split /\],\[/, $lenv; 
    push(@tmp, "") while($#tmp < $#GDIRTOKENS); # Pad empty fields

# This is incorrect check, 'split' deletes trailing empty fields
#    ($#tmp == $#GDIRTOKENS) or die "\nError in envorinments.db";

    for( $i = 0; $i <= $#GDIRTOKENS; $i++)
    {
#	print "\n$tmp[$i]: ";
	$ldirs{$GDIRTOKENS[$i]} = [ split /\,/, $tmp[$i] ];
#	print @{ $ldirs{$GDIRTOKENS[$i]}};
    }
    return %ldirs;
}






# Create background theory for one article.
# BUG here! The first item in db does not begin with \n !
# We do not keep the background theory as a text - it's a bit 
# inefficient. We represent it as an array, containing for each
# database file the array of necessary record numers - such info
# can be replayed quickly, and can even be stored.

#------------------------------------------------------------------------
#  Function    : CreateBg()
#
#  Return a record consisting for each dbkind of the pointers 
#  (record numbers in the db) of the 
#  background items needed for the article. This can be either 
#  stored or used for some more elaborate pruning.
#  The symbol arities are not exported here, since signature
#  filtering will usually be applied after this.
#
#  Input       : name of article, bool to tell if the article
#                should be adde to its directives
#  Global Vars : %gcnt, %GNTOKENS
#  Side Effects: I/O
#  TODO        : schemes not considered yet, needs special handling.
#------------------------------------------------------------------------

sub CreateBg
{
    my ($an, $addme) = @_;                     # Gets article name.
    my ($i, $j, $start, $end, $ac, %lreq, %ldirs, $dirkind, @dir, $an1);
    my $result = 
    { 'DCO' => [], 'DEM' => [], 'PRO' => [], 'CLE' => [], 
      'CLF' => [], 'CLC' => [], 'DRE' => [], 'SPC' => []};
#  'DSF' => [], 'DSP' => [] };

    $ac    = $gcnt{$an}->{'ORD'};    # Find article's nr.
    %ldirs =  Env2List($ac) ;

#   We handle the clusters separately now

    @ldirs{('CLE','CLF','CLC')} = 
	($ldirs{'DCL'},$ldirs{'DCL'},$ldirs{'DCL'});

    @ldirs{('DEM','PRO')} = ($ldirs{'DCO'},$ldirs{'DCO'});

    if(GWATCHED & WATCH_RAWBG) { print "BG theory for $an:\n" };

    @lreq{ ( @{ $ldirs{'DRE'}} ) } = ();  # need a hash of requir. names
    $result->{'SPC'} = \%lreq;

    if(GWATCHED & WATCH_RAWBG) 
    {
	print "SPC:\n", join(",", keys %{$result->{'SPC'}} ), "\n";
    };


    foreach $dirkind ( @GBGTOKENS )  # omitting 'NDB' and 'SPC'
    {
	@dir = @{ $ldirs{$dirkind}};
	
	push(@dir, $an) if( $addme );

#	print "@dir\n";
#	print "$ldirs{$dirkind}\n";
	if(GWATCHED & WATCH_RAWBG) { print "$dirkind:\n" };

	foreach $an1 (@dir) 
	{

	    if(! exists $gcnt{$an1} )
	    {
		if($AllowNonExistant != 0)
		{
		    print "Warning: $an1 not in db!\n" 
			if(GWATCHED & WATCH_BADREFS);
		}
		else
		{
		    die "Error: $an1 not in db!\n";
		}
	    }
	    else
	    {
		$start = $grcn{$an1}->{$dirkind};  # Start of .dco in $D_DCO
		$end   = $start + $gcnt{$an1}->{$dirkind};

		if(GWATCHED & WATCH_RAWBG) {print "\n$start,$end,$an1"};

		for($j = $start; $j < $end; $j++)
		{	    
		    push @{$result->{$dirkind}}, $j;

		    if(GWATCHED & WATCH_RAWBG) 
		    {
			print $D{$dirkind}[$j], ".\n";
		    };
		}
	    }
	}
    }
    return $result;
}


sub ThCanceled
{
    my ($thnr) = @_;

    return (0 < index($D{'THR'}[$thnr], "_canceled_"));
}

#------------------------------------------------------------------------
#  Function    : GetThRefs()
#
#  Get the references for a theorem problem,
#  the hypothesis is added as first. If SkipBadThRefsProblems,
#  bad problems return empty list.
#  CAUTION: Relies on the fact that THR is numbered as THE.
#
#
#  Input       : name of article, number of theorem
#  Global Vars : %gcnt, %GNTOKENS
#  Output      : hash of record numbers (in THE,DEF) of the refs
#  Side Effects: I/O, possible eroor reporting
#------------------------------------------------------------------------

sub GetThRefs
{
    my ($an, $thnr) = @_;
    my ($thpos,$rstart,$rstring,@threfs,%refnbrs,
	$ref,$rkind,$nr1,$an1,$dkind);

    $thpos   = $thnr + $grcn{$an}->{'THE'} - 1;  
    $rstart  = 1 + index($D{'THR'}[$thpos], '[');
    $rstring = substr($D{'THR'}[$thpos], $rstart); # Removes the first '[' too.
    chop($rstring); 
    chop($rstring);                       # Removes the last ']'.

    @threfs  = split /\,/, $rstring;
    push @{$refnbrs{'THE'}} , $thpos ;

  REF: foreach $ref (@threfs)
  {
      $ref =~  /^([asdt])(\d+)(_(\w+))?$/ or
	  die "Bad reference $ref";
      
      ($rkind,$nr1,$an1) = ($1, $2, $4);

      if(($rkind eq 'a') || ($rkind eq 's'))
      {
	  return () if ($SkipBadThRefsProblems == 1);

	  if(GWATCHED & WATCH_BADREFS)
	  {
	      print "Ignoring nonexported reference $ref\n";
	  }

	  next REF;
      }
	    
      $dkind = ($rkind eq 't')?'THE':'DEF';
      push @{$refnbrs{$dkind}}, $nr1 + $grcn{$an1}->{$dkind} - 1; 

  }

    return %refnbrs;
}


#------------------------------------------------------------------------
#  Function    : GetChkRefs()
#
#  Get the references for a checker problem,
#  the hypothesis is added as first. If SkipBadThRefsProblems,
#  bad problems return empty list.
#  The checker problem DB for the article must be open 
#  here already in $D{'CHK'}.
#  
#
#  Input       : name of article, problem number
#  Global Vars : %gcnt, %GNTOKENS
#  Output      : name, pointer to array of formulas, first is conjecture
#  Side Effects: I/O, possible eroor reporting
#------------------------------------------------------------------------

sub GetChkRefs
{
    my ($an, $nr) = @_;
    my ($nstart, $nend, $pname, $pstart, $pstring, @chkrefs, $i);

    $pstring = $D{'CHK'}[$nr-1];
    $nstart  = index($pstring, "by_");
    $nend    = index($pstring, ",");
    $pname   = substr($pstring, $nstart, $nend-$nstart);
    $pstart  = 1 + index($pstring, '[');
    $pstring = substr($pstring, $pstart);  # Removes the first '[' too.
    chop($pstring); 
    chop($pstring);                        # Removes the last ']'.

    @chkrefs = split /\nformula\(/, $pstring;

    shift @chkrefs if( $chkrefs[0] =~ m/^\s*$/ ); # first may be empty

    for($i=0; $i < $#chkrefs; $i++)
    {
	chop($chkrefs[$i]);    # last comma
	$chkrefs[$i] = "\nformula(".$chkrefs[$i];
    }

    $chkrefs[$#chkrefs] = "\nformula(".$chkrefs[$#chkrefs];

    return ($pname, \@chkrefs);
}

#------------------------------------------------------------------------
#  Function    : Arity()
#
#  Get symbol's arity, error if none. Loads
#  all symbols of the article into %garities if 
#  not there yet.
#
#  Input       : the symbol
#  Global Vars : %garities, %gcnt, %grcn, %D,
#  Side Effects: I/O
#------------------------------------------------------------------------

sub Arity
{
    my ($sym) = @_;

    if(! exists $garities{$sym})
    {
	my ($an, $kind, $start, $end, $j);

	(($sym =~ m/^[gklmruv]\d+_(\w+)$/) && (exists $gcnt{$1}))
	    or die "Bad symbol detected: $sym\n";

	$an = $1;

	foreach $kind ('DSF', 'DSP')
	{
	    $start = $grcn{$an}->{$kind};  
	    $end   = $start + $gcnt{$an}->{$kind};

	    for($j = $start; $j < $end; $j++)
	    {
		$D{$kind}[$j]  =~ m/^\W+arity\((\w+),(\d+)\)$/s;
		$garities{$1}  =  $2;
	    }
	}

	exists $garities{$sym} or
	    die "Bad symbol detected: $sym\n";
    }

    return $garities{$sym};
}

#------------------------------------------------------------------------
#  Function    : GroupDfgSymbols()
#
#  Divide the symbols according to their origin -
#  now 'DSF', 'DSP', 'NUM', 'CONST', 'SCHFUNC', SCHPRED'  
#  and 'SETOF'
#
#  Input       : hash of symbols
#  Side Effects: -
#------------------------------------------------------------------------

sub GroupDfgSymbols
{
    my ($syms) = @_;
    my ($sym, $kind, %new);

    foreach $sym (keys %$syms)
    {
	if( $sym =~ m/^([gklmruv])\d+_\w+$/ )
	{
	    $kind = (($1 eq 'k')||($1 eq 'g')||($1 eq 'u'))? 'DSF':'DSP';
	}
	elsif( $sym =~ m/^(c)?\d+$/ )
	{
	    $kind = (defined $1)? 'CONST':'NUM';
	}
	elsif( $sym =~ m/^([fp])?\d+_\d+$/ )
	{
	    $kind = ($1 eq 'f')? 'SCHFUNC':'SCHPRED';
	}	
	else 
	{
	    die "Bad symbol detected: $sym\n" 
		unless( $sym eq 'setof' );
	    $kind = 'SETOF';
	}

	push @{ $new{$kind} }, $sym;
    }
    return \%new;
}

#------------------------------------------------------------------------
#  Function    : PrintDfgProblem()
#
#  Print the whole DFG problem into $myfname.
#
#  Input       : kind ('THE' or 'CHK'),file name, problem name, 
#                symbols, background theory and problem references
#  Side Effects: I/O
#------------------------------------------------------------------------

sub PrintDfgProblem
{
    my ($kind, $myfname, $myname, $mysymbols, $mybg, $myrefs) = @_;
    my ($sym,$j,$k,$bgkind,$conj);

    open(OUT,">$myfname"); 
    print OUT ("begin_problem($myname).\n",
	       "list_of_descriptions.\n",
	       "name({*$myname*}).\n",
	       "author({*Mizar Mathematical Library*}).\n",
	       "status(unsatisfiable).\n",
	       "description({*Problem generated from MML by MPTP*}).\n",
	       "end_of_list.\n\n",
	       "list_of_symbols.\n",	     
	       "functions[\n\n",
	       "% Article functors:\n");

    $k=0;    
    foreach $sym ( @{ $mysymbols->{'DSF'}})
    {	
	print OUT ( "($sym,", Arity($sym), "),\t");
	print OUT "\n" if(3 == (3 & ++$k));
    }

    print OUT "\n\n% Numerals' arities:\n";
    $k=0;
    foreach $sym ( @{ $mysymbols->{'NUM'}})
    {	
	print OUT "($sym,0),\t";
	print OUT "\n" if(3 == (3 & ++$k));
    }

    print OUT "\n\n% Constants' arities:\n";
    $k=0;
    foreach $sym ( @{ $mysymbols->{'CONST'}})
    {	
	print OUT "($sym,0),\t";
	print OUT "\n" if(3 == (3 & ++$k));
    }

    print OUT "\n\n% Scheme functors:\n";
    $k=0;
    foreach $sym ( @{ $mysymbols->{'SCHFUNC'}})
    {	
	$sym =~ m/^f\d+_(\d+)$/;
	print OUT "($sym,$1),\t";
	print OUT "\n" if(3 == (3 & ++$k));
    }

    print OUT ( "(setof,0)\n].\n\n",
		"predicates[\n\n",
		"% Scheme predicates:\n");


    
    $k=0;
    foreach $sym ( @{ $mysymbols->{'SCHPRED'}})
    {	
	$sym =~ m/^p\d+_(\d+)$/;
	print OUT "($sym,$1),\t";
	print OUT "\n" if(3 == (3 & ++$k));
    }


    print OUT "\n\n% Article predicates:\n";
    for($k=0; $k < $#{$mysymbols->{'DSP'}}; $k++)
    {
	$sym = $mysymbols->{'DSP'}[$k];
	print OUT ( "($sym,", Arity($sym), "),\t");
	print OUT "\n" if(3 == (3 & $k));
    }

    if(0 <= $#{$mysymbols->{'DSP'}})
    {
	$sym = $mysymbols->{'DSP'}[$k];
	print OUT ( "($sym,", Arity($sym), ")");
    }

    print OUT ("\n].\n\n",
	       "end_of_list.\n",
	       "list_of_formulae(axioms).\n\n");

    foreach $bgkind (@GBGTOKENS)
    {
	print OUT "\n% $GBGNAMES{$bgkind}:\n\n";
	foreach $j ( @{ $mybg->{$bgkind}})
	{	
	    print OUT ( $D{$bgkind}[$j], ".\n");
	}
    }

    print OUT "\n% ", $GBGNAMES{'NDB'}, ":\n\n";
    foreach $sym ( keys %{ $mybg->{'NDB'}})
    {	
	print OUT ( $mybg->{'NDB'}{$sym}, ".\n");
    }


    print OUT "\n% Direct references:\n\n";
    if ($kind eq 'THE')
    {
	foreach $j ( @{ $myrefs->{'DEF'}})
	{	
	    print OUT ( $D{'DEF'}[$j], ".\n");
	}

	for($k=1; $k <= $#{$myrefs->{'THE'}}; $k++)
	{
	    $j = $myrefs->{'THE'}[$k];
	    print OUT ( $D{'THE'}[$j], ".\n");
	}

	$conj = $D{'THE'}[$myrefs->{'THE'}[0]];
    }
    else
    {
	($kind eq 'CHK') or die "Bad problem kind\n";

	for($k=1; $k <= $#{@$myrefs}; $k++)
	{
	    print OUT ( $myrefs->[$k], ".\n");
	}

	$conj = $myrefs->[0];
    }

    print OUT ("\nend_of_list.\n\n",
	       "list_of_formulae(conjectures).\n\n",
	       $conj, ".\n\n",
	       "end_of_list.\n\n",
	       "end_problem.\n");

    close OUT;
}



#  LoadCounts();

#  OpenDbs();

#    %n =  Env2List(97) ;
#  #  $k[1] = { Env2List(97) };
#  #  $k[2] = { Env2List(25) };
#  #  print "\n";

#  for( $i = 0; $i <= $#GDIRTOKENS; $i++)
#      {
#  #	print "\n$tmp[$i]: ";
#  #	$ldirs{$GDIRTOKENS[$i]} = [ split /\,/, $tmp[$i] ];
#  	print "$GDIRTOKENS[$i]: ";
#  	print @{ $n{$GDIRTOKENS[$i]}};
#  	print "\n";
#      }

#    print @{ $n{ 'VOC' } };
#  print "\n";
#  print @{ $k[2]{'VOC'} };
# CreateBg("setwop_2", 1);

1;
