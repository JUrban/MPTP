#!/usr/bin/perl


# run like:
# time for i in *.prf; do echo $i; hol2nrs $i >> 00; done
# isa2nrs.pl 00 >01

# NOTES: 
#
# - defined symbols (constants) typically create also a definitional
# theorem with the same name. In .prf files they can appear both as C
# and as D. In the .prf files corresponding to definitions, we should
# add the symbol also to @syms.

# TODO:
#
# It seems that we also have terms in the .prf file - could be used
# for even finer feature representation.


my %refs = ();
my %syms = ();

my $kind = <>;
chop($kind);
my $name = <>;
chop($name);
$_=<>; die "bad" unless m/^>Inherit/;
my $section = "Inherit";
while(<>)
{

    if(m/^[>](.*)/)
    {
	$section = $1;
    }


    if($section =~ m/Inherit|Fetches/)
    {
	if(m/^[ABDLTS].* +(.*)/)
	{
	    $refs{$1}++;
	}
	else
	{
	    m/^.* (.*)/ or die; $syms{$1}++;
	}
    }
}

# include the symbol
$syms{$name}++ if($kind =~ m/[dD]ef|[dD]ecl|Spec|[tT]ype/);

print (" ", $name, ":", join(",",sort keys %refs), ";", join(",",sort keys %syms), "\n");



