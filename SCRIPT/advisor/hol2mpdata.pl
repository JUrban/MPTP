#!/usr/bin/perl
# creating mpadata from HOL Light data, the supposed format are two aligned files
# each line in each starting with trhe theorem name followed by colon
# the symbols files then contains space-separated symbols for each theorem
# and the reference file space-separated references for each theorem
use strict;

die 'syms and refs different' if(`wc -l constrs` != `wc -l refs`);
open(IN1, "constrs");
open(IN2, "refs");
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # symbol names as they come
my %cn_nums = (); 

while(<IN1>)
{
    my ($name, $fla, $cn, $ref, $def);
    my %cns1 = ();
    my %refs1 = ();
    chop($_);
    $_ =~ m/^([^:]+):(.*)/;
    ($name, $fla) = ($1, $2);
    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    @cns1{ (split(/ /,$fla)) } = ();
    foreach $cn (keys %cns1)
    {
	if( !(exists $cn_nums{$cn})) 
	{
	    push @cn_arr, $cn;
	    $cn_nums{$cn} = $#cn_arr;
	}
	my $nr = 100000+$cn_nums{$cn};
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
	unless( exists $namenums{$ref})
	{
	    push @namearr, $ref;
	    $namenums{$ref} = $#namearr;
	}
	print "$namenums{$ref}," unless ($ref eq "");
    }
    print "$namenums{$name}:\n"
}
open(OUT,">refnr");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

