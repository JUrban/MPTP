#!/usr/bin/perl
# creating mpadata from MML Query data, not completely finished yet
use strict;

#$BASEDIR = "4.19.880";
#chdir "$BASEDIR/tmp" or die 'no basedir/tmp';
system "grep -h \"theorem\\|scheme\" ../dli/*.dli > constrs0";
`grep -h \"^[0-9A-Z_]\\+:\\(sch\\|def\\|th\\)\" ../itm/*.outref |sort > refs`;
`grep -v \"theorem(.VERUM)\" constrs0 |sort >constrs`;
die 'dli and outref different' if(`wc -l constrs` != `wc -l refs`);
open(IN1, "constrs");
open(IN2, "refs");
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # theorem names as they come
my %cn_nums = (); 

while(<IN1>)
{
    my ($name, $fla, $cn, $ref, $def);
    my %cns1 = ();
    my %refs1 = ();
    $_ =~ m/(.*)=(.*)/;
    ($name, $fla) = ($1, $2);
    $def = ($name =~ m/:def/)? 1:0;
    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    while($fla =~ m/([0-9A-Z_]+:(sel|attr|mode|pred|func|struct|aggr) \d+)/g)
    {
	$cns1{$1} = ();
    }
    foreach $cn (keys %cns1)
    {
	if( !(exists $cn_nums{$cn})) 
	{
	    push @cn_arr, $cn;
	    $cn_nums{$cn} = $#cn_arr;
	}
	my $nr = 100000+$cn_nums{$cn};
	print "$nr,";
    }
    $_ = <IN2>;
    $_ =~ m/(.*)=(.*)/;
    die 'files not in sync $1,$name' unless ($1 == $name);
    my $rfs = $2;
    while($rfs =~ m/([0-9A-Z_]+):(sch|def|th)? ?(\d+)/g)
    {
	my ($art,$nr,$what);
	$what = (defined $2)? $2:'th';
	($art, $nr) = ($1, $3);
	$refs1{$art . ':' . $what . ' ' . $3} = ();
    }
    foreach $ref (keys %refs1)
    {
	unless( exists $namenums{$ref})
	{
	    push @namearr, $ref;
	    $namenums{$ref} = $#namearr;
	}
	print "$namenums{$ref}," unless($def);
    }
    print "$namenums{$name}:\n"
}
open(OUT,">refnr");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

