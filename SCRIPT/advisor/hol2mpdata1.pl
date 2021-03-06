#!/usr/bin/perl
# creating mpadata from HOL Light data, the supposed format are two aligned files
# each line in each starting with trhe theorem name followed by colon
# the symbols files then contains space-separated symbols for each theorem
# and the reference file space-separated references for each theorem
use strict;

my $constrfile = shift;
my $reffile = shift;
my $ext = shift;  # optional extension for the refnr and symnr files
my $symsonly = shift; # (default 0): optionally totally ignore proof references, only learn on each theorems's symbols

die "at least two arguments expected" unless defined($constrfile) && defined($reffile);

$ext = defined($ext) ? ".$ext" : '';
$symsonly = 0 unless(defined($symsonly));

#die 'syms and refs different' if(`wc -l constrs` != `wc -l refs`);

# temporary hash for feature file lines, we no longer make assumptions
# about the order in FEATURES
my %featmp = (); 

open(FEATURES, $constrfile) or die;
while(<FEATURES>)
{
    chop($_);
    $_ =~ m/^([^:]+):(.*)/ or die "bad line $_";    
    $featmp{$1}=$2;
}
close(FEATURES);

open(REFS, $reffile) or die;
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # symbol names as they come
my %cn_nums = (); 


# FEATURES can now contain more entries than REFS, because some
# conjunctions are removed from refs (replaced totally by their
# conjuncts). The order should be preserved in both files.
while(<REFS>)
{
    my ($cn, $name1, $fla, $ref, $def);
    my %features1 = ();
    my %refs1 = ();
    chop($_);
    $_ =~ m/^([^:]+):(.*)/ or die "bad line $_";
    my ($name, $rfs) = ($1, $2);
    my $rfs = $2;

    if(exists($featmp{$name}))
    {
	$fla = $featmp{$name};
    }
    else { die "no features for $name"; }

    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    @features1{ (split(/, +/,$fla)) } = ();
    foreach $cn (keys %features1)
    {
	if( !(exists $cn_nums{$cn})) 
	{
	    push @cn_arr, $cn;
	    $cn_nums{$cn} = $#cn_arr;
	}
	my $nr = 1000000+$cn_nums{$cn};
	print "$nr," unless ($cn eq "");
    }
    @refs1{ (split(/ /,$rfs)) } = ();
    foreach $ref (keys %refs1)
    {
	my ($ref1,$w1) = ($ref,'');
	if($ref=~ m/(.*)([(].*[)])/) { ($ref1,$w1) = ($1,$2); }
	unless( exists $namenums{$ref1})
	{
	    push @namearr, $ref1;
	    $namenums{$ref1} = $#namearr;
	}
	if(0==$symsonly) { print "$namenums{$ref1}$w1," unless ($ref eq ""); }
    }
    print "$namenums{$name}:\n"
}
open(OUT,">refnr$ext");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr$ext");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

