#!/usr/bin/perl


# run like:
# time for i in *.prf; do echo $i; hol2nrs $i >> 00; done
# time for i in [A-Z]*/*.prf; do echo $i; /home/urban/gr/MPTP/SCRIPT/advisor/hol2nrs.pl $i >> 00; done
# isa2nrs.pl 00 >01
# split for X-val: split -l -d ... 01
# prepare train files: perl -e '$i=0; while($i<10) { $j=0; while($j<10) { `cat x0$j>> y0$i` if($i!=$j); $j++ } $i++; }'
# train/test: 
# i=0; /home/urban/gitrepo/MPTP2/MaLARea/bin/snow -train -I y0$i -F y0$i.net  -B :0-11348
# i=0; time /home/urban/gitrepo/MPTP2/MaLARea/bin/snow -test -o allboth -I x0$i -F y0$i.net -L1000 -B :0-11348 > z0$i

# NOTES: 
#
# - see the file commonhol_file_format.txt for the format description
#   and Thm_REAL_ABS_SUB_ABS.prf for an example
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
#$_=<>; die "bad" unless m/^>Inherit/;
my $section = ""; # "Inherit";
while($_=<>)
{

    if(m/^[>](.*)/)
    {
	$section = $1;
	$_=<>;
    }


    if($section =~ m/Inherit|Fetches/)
    {
	if(m/^\d* *[ABDLTS][^ ]* +([^ ]*).*\n/)
	{
	    $refs{$1}++;
	}
	else
	{
	    m/^\d* *[^ ]* ([^ ]*).*\n/ or die "Bad: $_"; $syms{$1}++;
	}
    }
}

# include the symbol
$syms{$name}++ if($kind =~ m/[dD]ef|[dD]ecl|Spec|[tT]ype/);

print (" ", $name, ":", join(",",sort keys %refs), ";", join(",",sort keys %syms), "\n");



