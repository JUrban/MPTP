#!/usr/bin/perl
# creating mpadata from HOL Light data, the supposed format are two aligned files
# each line in each starting with trhe theorem name followed by colon
# the symbols files then contains space-separated symbols for each theorem
# and the reference file space-separated references for each theorem
use strict;

#die 'syms and refs different' if(`wc -l constrs` != `wc -l refs`);
open(FEATURES, "constrs");
open(REFS, "refs");
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

    do  # here we are skipping redundant entries in FEATURES
    {
	$_ = <FEATURES>;
	chop($_);
	$_ =~ m/^([^:]+):(.*)/ or die "bad line $_";
	($name1, $fla) = ($1, $2);
    }
    until($name1 eq $name);

    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    @features1{ (split(/, /,$fla)) } = ();
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
	print "$namenums{$ref1}$w1," unless ($ref eq "");
    }
    print "$namenums{$name}:\n"
}
open(OUT,">refnr");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

