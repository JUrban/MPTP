#------------------------------------------------------------------------
#
# File  : MPTPSgnFilter.pm ( Signature filter for MPTP)
#
# Author: Josef Urban
#
# Does signature-based filtering of the background
# article theories.
#
# Assumed naming conventions - see %GFLA_DB_KIND
# Checker problems:
# normal reference:      "t\d+_r_by_\d+_\d+_\w+"
# local const. type:     "t\d+_t_by_\d+_\d+_\w+"
# local const. equality: "t\d+_e_by_\d+_\d+_\w+"
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
#     New
#------------------------------------------------------------------------

package MPTPSgnFilter;
use strict;
use warnings;
use MPTPUtils;
use MPTPDebug;

our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    use Exporter   ();

    @ISA         = qw(Exporter);
    @EXPORT      = qw(@GIGNORED
                      &CollectSymbols
		      &GetDirectSyms
		      &GetAllBgSyms
		      &FilterBgWithSyms
		      &AddSymsAndSpecials
		      &FilterBg);
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}
use vars (@EXPORT, @EXPORT_OK);


# Symbols we ignore, variables have to be handled specially
@GIGNORED = ( "", "and", "equal", "forall", "not", "implies", 
	      "equiv", "or", "exists", "true", "false");

# Following are caching hashes useful when processing
# multiple problems.
# The symbol info could actually be stored in separate
# databases, but my current handling of redefinitions prevents
# a simple lookup by number (and I do not want other than 
# RECNO databases until it is really needed, to have all files
# Prolog readable). Some of these things may change later.

# Existential mode theorems and existential clusters are not 
# needed now. 

# For each constructor we have a hash, where key is number
# of the formula in the respective database and value
# (if already computed) is the array of symbols of that formula.
# my %Types; # now $C->{'DCO'}
# my %Props; # now $C->{'PRO'}

# For functor clusters, we want to store the underlying term,
# and the succedent symbols.
# my %FunCl; # now $C->{'CLF'}

# For conditional clusters, we want to store all antecedent
# symbols (contain the underlying type), and the succedent symbols.
# my %ConCl; # now $C->{'CLC'}

# For requirements we want all symbols to be present before
# adding - maybe a bit strong. Some are (e.g. number types)
# created manually, and thus not in the cache, however
# the processing info for them is hidden in the 'SPC' slot.

my @GCACHETOKENS = ('DCO', 'PRO', 'DEF', 'CLF', 'CLC', 'DRE');

#------------------------------------------------------------------------
#  Function    : CollectSymbols()
#
#  Get the nonvariable user symbols from a string.
#  
#  Assumptions: 
#   We split on non-word characters, so no dfg or user symbol
#   may contain them, and every word character is part of some
#   dfg or user symbol. All variables start with a capital letter.
#
#  Input       : string containing dfg and user symbols
#  Global Vars : -
#  Output      : hash of the symbol
#------------------------------------------------------------------------

sub CollectSymbols
{
    my %symbols;
    my $symb;

    @symbols{ (split /\W+/, $_[0]) } = ();

    foreach $symb (@GIGNORED)
    {
	delete $symbols{$symb};
    }

    foreach $symb (keys %symbols)
    {
	delete $symbols{$symb} if( $symb =~ m/^[A-Z].*/ );
    }

    return  \%symbols;

}

#------------------------------------------------------------------------
#  Function    : GetMatchingParen()
#
#  Return the index of matching parenthesis in string for  
#  given position (only in forward direction). 
#  More such funcs would call for Prolog implementation,
#  but I need very little of this now and try to keep things
#  simple.
#
#  Input       : string, position, initial balance 
#                (can be negative - no sense now)
#  Global Vars : -
#  Output      : the matching paren position
#------------------------------------------------------------------------

sub GetMatchingParen
{
    my ($s, $beg, $balance) = @_;

    $_ = $s;
    pos($_) = 1 + $beg;    # match from here

    while( ($balance != 0) && ( m/([()])/gc ) ) 
    {
	$balance += ($1 eq '(')? 1 : -1;
    }

    return pos($_);
}

#------------------------------------------------------------------------
#  Function    : InitCache()
#
#  Symbols for bg formulas are put into the cache,
#  clusters are split into antecedent and succedent symbols
#  and graphs are built for fast firing of clusters and
#  requirements.
#
#  Input       : the cache pointer, the background
#  Side Effects: Initializes the cache, I/O
#  Global Vars : -
#  Output      : -
#------------------------------------------------------------------------

my $CANCELED_DEF_SYNBOL = "_"; # used in defsymbols

sub InitCache
{
    my ($C, $bg) = @_;
    my ($j, $symb, $content, $ante, $succ,
	$succstr, $firstpar, $anteend, $li);

    %{ $C->{'DCO'} }      = ();     # symbols from DCO flas
    %{ $C->{'PRO'} }      = ();     # symbols from PRO flas
    %{ $C->{'CLF'} }      = ();     # symbols from CLF flas
    %{ $C->{'CLC'} }      = ();     # symbols from CLC flas
    %{ $C->{'DRE'} }      = ();     # symbols from DRE flas
    %{ $C->{'GRAPH'} }    = ();     # graph for CLF, CLC and DRE symbols

    %{ $C->{'SPC'} }      = %{ $bg->{'SPC'} }; # better get a copy

    foreach $j (@{$bg->{'DCO'}})
    {
	$D{'DCO'}[$j]          =~ m/^\s*formula\((.*)\ndt(\w+)\)$/s
	    or die "Bad DCO fla at $j:$1,$2\n";

	($content, $symb)      =  ($1, $2);
	($symb)                =  split(/__/, $symb); # remove redef
	$C->{'DCO'}{$symb}{$j} =  CollectSymbols($content);
    }

    foreach $j (@{$bg->{'PRO'}})
    {
	$D{'PRO'}[$j]          =~ m/^\s*formula\((.*)\np\d+_(\w+)\)$/s
	    or die "Bad PRO fla at $j:$1,$2\n";

	($content, $symb)      =  ($1, $2);
	($symb)                =  split(/__/, $symb); # remove redef
	$C->{'PRO'}{$symb}{$j} =  CollectSymbols($content);
    }

    foreach $j (@{$bg->{'DEF'}})
    {
	my $dname;

	$D{'DEFSYMS'}[$j]     =~ m/^\s*defines\((d\d+_\w+),(\w+)\)$/
	    or die "Bad DEFSYMS at $j:$1,$2";

	($dname, $symb) = ($1, $2);

	if($CANCELED_DEF_SYNBOL ne $symb)
	{
	    $D{'DEF'}[$j]         =~ m/^\s*formula\((.*)\n(d\d+_\w+)\)$/s
		or die "Bad DEF fla at $j:$1,$2,$3\n";

	    $dname eq $2 or die "DEFSYMS and DEF not in sync at $j";

	    $content      =  $1;

	    $C->{'DEF'}{$symb}{$j} =  CollectSymbols($content);
	}
    }

    foreach $j (@{$bg->{'DRE'}})
    {
	$D{'DRE'}[$j]          =~ m/^\s*formula\((.*)\nrq\d+_\w+\)$/s
	    or die "Bad DRE fla at $j:$1,$2\n";

	$ante                   =  CollectSymbols($1);	
	$C->{'DRE'}{$j}{'ANTE'} =  $ante;
	$C->{'DRE'}{$j}{'FIRE'} =  keys %$ante;

	foreach $symb ( keys %$ante )
	{
	    push @{ $C->{'GRAPH'}{'DRE'}{$symb} }, $j;
	}
    }


    $li = length("implies(");    # to be explicit below

    foreach $j (@{$bg->{'CLC'}})
    {
	$D{'CLC'}[$j]        =~ 
	    m/^\s*formula\((forall\(\[[^\]]*\]\W*)?\s*(.*)\ncc\d+_\w+\)$/s
		or die "Bad CLC fla at $j:$1,$2\n";

	$content             =  $2;

	if($content =~ m/^implies\(.*$/s )
	{
	    $firstpar= index($content, "(", 1+$li);     # shaky
	    $anteend = GetMatchingParen($content, 1+$firstpar, 1);
	    $ante    = CollectSymbols( substr($content, $li, $anteend-$li));
	    $succ    = CollectSymbols( substr($content, 1+$anteend) );
	}
	else
	{
	    $ante    =  {};
	    $succ    =  CollectSymbols($content);
	}

	$C->{'CLC'}{$j}{'ANTE'} =  $ante;
	$C->{'CLC'}{$j}{'SUCC'} =  $succ;
	$C->{'CLC'}{$j}{'FIRE'} =  keys %$ante;

	foreach $symb ( keys %$ante )
	{
	    push @{ $C->{'GRAPH'}{'CLC'}{$symb} }, $j;
	}

    }

# We match the top functor symbol here too,
# supposing that it comes right after the first attribute
# in succedent - hopefully correct.

    foreach $j (@{$bg->{'CLF'}})
    {
	$D{'CLF'}[$j]        =~ 
	    m/^\s*formula\((forall\(\[[^\]]*\]\W*)?\s*(.*)\nfc\d+_\w+\)$/s
		or die "Bad CLF fla at $j:$1,$2\n";

	$content          =  $2;

	if($content =~ m/^implies\(.*$/s )
	{
	    $firstpar= index($content, "(", 1+$li);     # shaky
	    $anteend = GetMatchingParen($content, 1+$firstpar, 1);
	    $ante    = CollectSymbols( substr($content, $li, $anteend-$li));
	    $succ    = CollectSymbols( substr($content, 1+$anteend) );
	    $succstr = substr($content, 1+$anteend);
	}
	else
	{
	    $ante    =  {};
	    $succ    =  CollectSymbols($content);
	    $succstr =  $content;
	}

# The '?' here for non-greediness, we need to get the first
# attribute, there could be problems with others.

	$succstr     =~ m/^(.*?\W)?v\d+_\w+\W+(\w+).*/s
	    or die "Bad CLF succedent term at $j:$succstr\n$D{'CLF'}[$j]\n";

	@$ante{ ( $2 ) }  = ();    # add to ante
	
	$C->{'CLF'}{$j}{'ANTE'} =  $ante;
	$C->{'CLF'}{$j}{'SUCC'} =  $succ;
	$C->{'CLF'}{$j}{'FIRE'} =  keys %$ante;

	foreach $symb ( keys %$ante )
	{
	    push @{ $C->{'GRAPH'}{'CLF'}{$symb} }, $j;
	}

    }
}



#------------------------------------------------------------------------
#  Function    : InitCacheGraphs()
#
#  Prepare the cache cluster and DRE graphs for fresh processing -
#  restore the 'FIRE' counts;
#
#  Input       : the cache pointer
#  Side Effects: Initializes the cache 'FIRE' links
#  Global Vars : -
#  Output      : -
#------------------------------------------------------------------------

sub InitCacheGraphs
{
    my ($C) = @_;
    my ($kind, $j);

    foreach $kind ('CLF', 'CLC', 'DRE')
    {
	foreach $j (keys %{ $C->{$kind} })
	{
	    $C->{$kind}{$j}{'FIRE'} = keys %{$C->{$kind}{$j}{'ANTE'}};
	}
    }
}

#------------------------------------------------------------------------
#  Function    : PrintCache()
#
#  Just debugging now. Clusters occupy two lines.
#
#  Input       : the cache pointer
#  Side Effects: I/O
#  Global Vars : -
#  Output      : -
#------------------------------------------------------------------------

sub PrintCache
{
    my ($C) = @_;
    my ($kind, $current, $key1, $key2);

    print "BGCache:\n";

    foreach $kind (@GCACHETOKENS)
    {
	print "$kind\n";
	$current = \%{$C->{$kind}};

	foreach $key1 (keys %$current)
	{
	    foreach $key2 (keys  %{ $current->{$key1}})
	    {
		print "$key1:\t$key2:\t",
		       ('FIRE' eq $key2)? $current->{$key1}{$key2} :
			   join(",", keys %{ $current->{$key1}{$key2} }), 
		       "\n";
	    }
	}
    }

    foreach $kind ('CLF', 'CLC', 'DRE')
    {
	print "GRAPH:$kind\n";
	$current = \%{$C->{'GRAPH'}{$kind}};

	foreach $key1 (keys %$current)
	{
	    print "$key1:\t",
	           join(",", @{ $current->{$key1} }), 
		   "\n";
	}
    }

    print "SPC:\n";
    print join(",", (keys %{ $C->{'SPC'} } )), "\n";
    
}

#------------------------------------------------------------------------
#  Function    : AddTypesPropsAndDefs()
#
#  Add numbers of 'DCO' and 'PRO' flas for delta symbols to 
#  $addedbg, add symbols of that flas to $newsyms.
#
#  Input       : pointer to added bg, pointer to newly added 
#                symbols, pointer to delta symbols (newly added 
#                in previous step), cache of bg symbols
#  Side Effects: adds numbers of 'DCO' and 'PRO' flas to $addedbg, 
#                adds symbols of that flas to $newsyms
#  Global Vars : -
#  Output      : number of added formulas
#------------------------------------------------------------------------

sub AddTypesPropsAndDefs
{
    my ($addedbg, $newsyms, $deltasyms, $C) = @_;
    my ($sym, $kind, $j, $result);

    $result = 0;

    foreach $sym (keys %$deltasyms)
    {
	foreach $kind ('DCO', 'PRO', 'DEF')
	{
	    if(exists $C->{$kind}{$sym})
	    {
		foreach $j ( keys %{ $C->{$kind}{$sym} } )
		{
		    push @{ $addedbg->{$kind} }, $j;
		    @$newsyms{(keys %{ $C->{$kind}{$sym}{$j} })} = ();
		    $result++;
		}
	    }
	}
    }
    return $result;
}


#------------------------------------------------------------------------
#  Function    : AddClusters()
#
#  Do cluster firing for delta symbols, and appropriate
#  flas and newsymbols additions.
#
#  Input       : pointer to added bg, pointer to newly added 
#                symbols, pointer to delta symbols (newly added 
#                in previous step), cache of bg symbols
#  Side Effects: adds numbers of cluster flas to $addedbg, 
#                adds symbols of that flas to $newsyms
#  Global Vars : -
#  Output      : number of added cluster formulas
#------------------------------------------------------------------------

sub AddClusters
{
    my ($addedbg, $newsyms, $deltasyms, $C) = @_;
    my ($sym, $kind, $j, $result);

    $result = 0;

    foreach $sym (keys %$deltasyms)
    {
	foreach $kind ('CLF', 'CLC')
	{
	    if(exists $C->{'GRAPH'}{$kind}{$sym})
	    {
		foreach $j ( @{ $C->{'GRAPH'}{$kind}{$sym} } )
		{
		    if( 0 == --$C->{$kind}{$j}{'FIRE'} )
		    {
			push @{ $addedbg->{$kind} }, $j;
			@$newsyms{ (keys %{ $C->{$kind}{$j}{'SUCC'} }) } = ();
			$result++;
		    }
		}
	    }
	}
    }
    return $result;
}


#------------------------------------------------------------------------
#  Function    : AddRequirements()
#
#  Add numbers of 'DRE' flas for delta symbols to 
#  $addedbg, add symbols of that flas to $newsyms.
#  We require all symbols in the fla to be already 
#  present, which maybe a bit strong.
#
#  Input       : pointer to added bg, pointer to newly added 
#                symbols, pointer to delta symbols (newly added 
#                in previous step), cache of bg symbols
#  Side Effects: adds numbers of 'DRE' flas to $addedbg, 
#                adds symbols of that flas to $newsyms
#  Global Vars : -
#  Output      : number of added formulas
#------------------------------------------------------------------------

sub AddRequirements
{
    my ($addedbg, $newsyms, $deltasyms, $C) = @_;
    my ($sym, $kind, $j, $result);

    $result = 0;

    foreach $sym (keys %$deltasyms)
    {
	if(exists $C->{'GRAPH'}{'DRE'}{$sym})
	{
	    foreach $j ( @{ $C->{'GRAPH'}{'DRE'}{$sym} } )
	    {
		if( 0 == --$C->{'DRE'}{$j}{'FIRE'} )
		{
		    push @{ $addedbg->{'DRE'} }, $j;
		    $result++;
		}
	    }
	}

    }
    return $result;
}



#------------------------------------------------------------------------
#  Function    : AddSpecial()
#
#  Add the 'NDB' flas for delta symbols according 
#  to the 'SPC' slot of the cache to $addedbg, add 
#  symbols of that flas to $newsyms.
#  Anything having the 'SPC' slot can be used,
#  so we use it for completing bg when no filtering is
#  used too.
#  This can be used for all kinds of extraordinary hacks,
#  now just for adding number types according to requirements.
#  Very hardcoded, fix here if requirements change.
#
#  Input       : pointer to added bg, pointer to newly added 
#                symbols, pointer to delta symbols (newly added 
#                in previous step), cache of bg symbols
#  Side Effects: adds new 'NDB' flas  to $addedbg, 
#                adds symbols of that flas to $newsyms
#  Global Vars : -
#  Output      : number of added formulas
#------------------------------------------------------------------------

sub AddSpecial
{
    my ($addedbg, $newsyms, $deltasyms, $C) = @_;
    my ($sym, $result, $zero, $fla);

    $result = 0;

    foreach $sym (keys %$deltasyms)
    {
	if( $sym =~ m/^\d+$/ )
	{
	    $zero = ($sym eq "0");

# v1_xboole_0 is "empty"

	    if((exists $C->{'SPC'}{"boole"}) && ! $zero)
	    {

		$fla = "\nformula( not(v1_xboole_0($sym)),"
		    ."\nndb$sym\_boole)";
		$addedbg->{'NDB'}{"ndb$sym\_boole"} = $fla;
		$newsyms->{"v1_xboole_0"} = ();
		$result++;
	    }

# m1_subset_1 is "Element", k5_ordinal2 is "NAT"

	    if($GMML_VERSION eq '3_44_763')
	    {
		if(exists $C->{'SPC'}{"arytm"})
		{
		    $fla = "\nformula( m1_subset_1($sym,k5_ordinal2),"
			."\nndb$sym\_arytm)";
		    $addedbg->{'NDB'}{"ndb$sym\_arytm"} = $fla;
		    @$newsyms{ ("m1_subset_1", "k5_ordinal2") } = ();
		    $result++;
		}
	    }
	    elsif(exists $C->{'SPC'}{"numerals"})
	    {

		$fla = "\nformula( m1_subset_1($sym,k5_ordinal2),"
		    ."\nndb$sym\_numerals)";
		$addedbg->{'NDB'}{"ndb$sym\_numerals"} = $fla;
		@$newsyms{ ("m1_subset_1", "k5_ordinal2") } = ();
		$result++;
	    }

# v4_ordinal2 is "natural"
	    
	    if(exists $C->{'SPC'}{"numerals"})
	    {
		$fla = "\nformula( v4_ordinal2($sym),\nndb$sym\_numerals)";
		$addedbg->{'NDB'}{"ndb$sym\_numerals"} = $fla;
		$newsyms->{"v4_ordinal2"} = ();
		$result++;
	    }

# "positive" not done yet
#	    if(exists $C->{'SPC'}{"real"})

	}

    }
    return $result;
}


#------------------------------------------------------------------------
#  Function    : OneStep()
#
#  Adds flas for delta symbols to $addedbg, adds
#  symbols of that flas to $newsyms. Returns number
#  of added flas.
#
#  Input       : pointer to added bg, pointer to newly added 
#                symbols, pointer to delta symbols (newly added 
#                in previous step), cache of bg symbols
#  Side Effects: adds numbers of flas to $addedbg, 
#                adds symbols of that flas to $newsyms
#  Global Vars : -
#  Output      : number of added formulas
#------------------------------------------------------------------------

sub OneStep
{
    my ($addedbg, $newsyms, $deltasyms, $C) = @_;
    my ($sym, $kind, $j, $result);

    $result = 0;

    $result  += AddTypesPropsAndDefs($addedbg, $newsyms, $deltasyms, $C);
    $result  += AddClusters($addedbg, $newsyms, $deltasyms, $C);
    $result  += AddRequirements($addedbg, $newsyms, $deltasyms, $C);
    $result  += AddSpecial($addedbg, $newsyms, $deltasyms, $C);
    return $result;
}

#------------------------------------------------------------------------
#  Function    : FixPoint()
#
#  Do the fixpoint computation of necessary symbols
#  and related background formulas.
#  Return the necessary bg formulas and pass
#  by ref all user symbols in the problem.
#
#  Input       : initial symbols, complete bg, cache of bg symbols
#  Side Effects: $allsyms changed, I/O
#  Global Vars : -
#  Output      : hash of bg formulas
#  TODO        : implement incomplete strategies: only given nr. of passes
#------------------------------------------------------------------------

sub FixPoint
{
    my ($allsyms, $deltasyms, $allbg, $bgcache) = @_;
    my ($newsyms, %addedbg, $sym);
    my ($alladded, $added) = (0, 0);

    $newsyms = {};
    undef %addedbg;

    do
    {	
	$added      =  OneStep(\%addedbg, $newsyms, $deltasyms, $bgcache);
	$alladded   += $added;

	foreach $sym (keys %$newsyms)
	{
	    delete $newsyms->{$sym} if( exists $allsyms->{$sym} );
	}
		
	if( GWATCHED & WATCH_FILTER_FIXPOINT)
	{
	    print "FIXPOINT: $added formulas added in last step\n";
	    print "NEWSYMBOLS: ", join(",",(keys %$newsyms)), "\n"
		if( GWATCHED & WATCH_FILTER_SYMBOLS);
	}

	@$allsyms{ (keys %$newsyms) } = ();	
	%$deltasyms = ();
	$deltasyms  = $newsyms;
	$newsyms    = {};

    } 
    while( $added > 0);

    return \%addedbg;
}

#------------------------------------------------------------------------
#  Function    : GetDirectSyms()
#
#  Get the symbols from the direct references.
#  Pass them back in $refsyms.
#
#  Input       : refs kind (THE or CHK), refs, pointer to symbols hash
#  Side Effects: $refsyms changed
#  Global Vars : -
#  Output      : -
#------------------------------------------------------------------------

sub GetDirectSyms
{
    my ($kind, $refs, $refsyms) = @_;
    my ($refkind, $j, $ref, $onesyms);

    if($kind eq 'THE')
    {
	foreach $refkind (keys %$refs)   # now 'THE' and 'DEF'
	{
	    foreach $j (@{ $refs->{$refkind}})
	    {
		$D{$refkind}[$j]   =~ m/^\s*formula\((.*)\n\w+\)$/s
		    or die "Bad $refkind fla at $j\n";
		
		$onesyms           =  CollectSymbols($1);
		@$refsyms{ (keys %$onesyms) } = ();
	    }
	}
    }
    else
    {
	($kind eq 'CHK') or die "Bad problem kind: $kind";

	foreach $ref (@$refs)
	{
	    $ref     =~ m/^\s*formula\((.*)\n\w+\)$/s
		or die "Bad checker fla: $ref\n";

	    $onesyms =  CollectSymbols($1);
	    @$refsyms{ (keys %$onesyms) } = ();
	}	
    }
}


#------------------------------------------------------------------------
#  Function    : GetAllBgSyms()
#
#  Get the symbols from the background.
#  Pass them back in $refsyms.
#
#  Input       : background, pointer to symbols hash
#  Side Effects: $refsyms changed
#  Global Vars : -
#  Output      : -
#------------------------------------------------------------------------

sub GetAllBgSyms
{
    my ($bg, $refsyms) = @_;
    my ($dirkind, $j, $ref, $onesyms);

    foreach $dirkind ( @GBGTOKENS )  # omitting 'NDB' and 'SPC'
    {
	foreach $j (@{ $bg->{$dirkind}})
	{
	    $D{$dirkind}[$j]   =~ m/^\s*formula\((.*)\n\w+\)$/s
		or die "Bad $dirkind fla at $j\n";
	    
	    $onesyms           =  CollectSymbols($1);
	    @$refsyms{ (keys %$onesyms) } = ();
	}
    }
}


#------------------------------------------------------------------------
#  Function    : FilterBgWithSyms()
#
#  Does the fixpoint work with initial symbols already
#  given in the hash pointer $refsyms.
#  See the doc for FilterBg.
#
#  Input       : article background theory, cache from previous 
#                filtering, symbols in the initial references
#  Side Effects: $refsyms changed, $bgcache changed
#  Global Vars : -
#  Output      : $result, $refsyms
#------------------------------------------------------------------------

sub FilterBgWithSyms
{    
    my ($oldbg, $bgcache, $refsyms) = @_;
    my (%newsyms, $onesyms, $result);

    if(! exists $bgcache->{'DCO'})
    {
	InitCache($bgcache, $oldbg);
    }
    else
    {
	InitCacheGraphs($bgcache);
	$bgcache->{'NDB'} = ();      
    }

    @newsyms{ (keys %$refsyms) } = ();  # need a copy

    if( GWATCHED & WATCH_FILTER_BGCACHE ) { PrintCache($bgcache) };

    print "PROBLEM SYMBOLS:start: ", join(",",(keys %$refsyms)), "\n"
	if( GWATCHED & WATCH_FILTER_SYMBOLS );

    $result = FixPoint($refsyms, \%newsyms, $oldbg, $bgcache);


    print "PROBLEM SYMBOLS:end: ", join(",",(keys %$refsyms)), "\n"
	if( GWATCHED & WATCH_FILTER_SYMBOLS );
    

    return ($result, $refsyms);
}

#------------------------------------------------------------------------
#  Function    : AddSymsAndSpecials()
#
#  Top-level function when filtering is not used.
#  Add the symbols from direct refs to bg symbols, 
#  fetch the special flas for them. This theoretically means
#  we should do fixpoint computation, but specials add no new
#  numbers now, and other symbols should be already in the bg.
#  Pass them back in $refsyms.
#
#  Input       : kind, refs, background, pointer to bg symbols hash
#  Side Effects: $bg->{'NDB'} changed
#  Global Vars : -
#  Output      : grouped symbols
#------------------------------------------------------------------------


sub AddSymsAndSpecials
{    
    my ($kind, $refs, $bg, $bgsyms) = @_;
    my (%refsyms,$groupedsyms,$numsyms,$spcsyms);

    print "PROBLEM SYMBOLS:bg: ", join(",",(keys %$bgsyms)), "\n"
	if( GWATCHED & WATCH_FILTER_SYMBOLS );

    GetDirectSyms($kind, $refs, \%refsyms);

    print "PROBLEM SYMBOLS:direct: ", join(",",(keys %refsyms)), "\n"
	if( GWATCHED & WATCH_FILTER_SYMBOLS );

    @refsyms{ (keys %$bgsyms) } = ();  
    $groupedsyms = GroupDfgSymbols(\%refsyms);
    if (defined $groupedsyms->{'NUM'})
    {
	@$numsyms{ @{$groupedsyms->{'NUM'}} } = ();	
	AddSpecial($bg, $spcsyms, $numsyms, $bg);
    }

    return $groupedsyms;
}




#------------------------------------------------------------------------
#  Function    : FilterBg()
#
#  Filter the article background theory for a problem.
#  The word 'filter' is not exact now, because we also add here
#  "special" formulas (now type formulas for numbers). It has
#  to be handled here, since it adds new symbols.
#
#  Algorithm: 
#
#  Existence of redefined modes is redundant,
#  mode existence is often subsumed by cluster existence,
#  properties of redefined constructors are subsumed if
#  stated for the originals.
#  Typing theorems added only after the typed constructor occured
#  earlier. This is correct for checker problems. For theorem
#  problems, e.g. a "take" statement could occur inside a proof -
#  this requires deeper analysis.
#  The same holds for properties, fclusters, cclusters and 
#  requirements. Mode and cluster existence can probably be pruned
#  always for checker problems, not for theorem problems.
#  There is a strong assumption for most of the filtering, that
#  the mechanisms in Mizar are really only one-directional, i.e.
#  clusters do not fire in the inverted direction, etc. This is
#  easily violated e.g. in proofs by contradiction.
#
#  The solution for non-checker proofs is to collect symbols from
#  all proof items (and not just the references). That way, we
#  should be again in the safer area of reasoning about Mizar checker.
#  Approximation by taking symbols just from the references could
#  however be quite good for the first version.
#
#
#  Input       : problem kind ('THE', 'CHK'), problem references
#                (hash for 'THE', array for 'CHK'),
#                 article background theory,
#                cache from previous filtering
#  Global Vars : %gcnt, %GNTOKENS
#  Output      : filtered background theory
#  Side Effects: I/O
#------------------------------------------------------------------------

sub FilterBg
{    
    my ($kind, $refs, $oldbg, $bgcache) = @_;
    my (%refsyms);

    GetDirectSyms($kind, $refs, \%refsyms);
    return FilterBgWithSyms($oldbg, $bgcache, \%refsyms);
}

1;
