#!/usr/bin/perl
# creating mpadata from HOL Light data, the supposed format are two aligned files
# each line in each starting with trhe theorem name followed by colon
# the symbols files then contains space-separated symbols for each theorem
# and the reference file space-separated references for each theorem
use strict;

die 'syms and refs different' if(`wc -l constrs` != `wc -l refs`);
open(FEATURES, "constrs");
open(IN2, "refs");
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # symbol names as they come
my %cn_nums = (); 

while(<FEATURES>)
{
    my ($name, $fla, $cn, $ref, $def);
    my %features1 = ();
    my %refs1 = ();
    chop($_);
    $_ =~ m/^([^:]+):(.*)/;
    ($name, $fla) = ($1, $2);
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
    $_ = <IN2>;
    chop($_);
    $_ =~ m/^([^:]+):(.*)/;
    die 'files not in sync $1,$name' unless ($1 == $name);
    my $rfs = $2;
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

