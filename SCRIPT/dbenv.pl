#!/usr/bin/perl -w

# Environment massaging script for MPTP

$dirnbr = 9; # number of directives in .evl
@dirs   = ([],[],[],[],[],[],[]);
$codirnr  = 6; # order of the constr. directive 
$f=$ARGV[0]; 
$sg = $f.".sgl";
open(SGL, $sg) or die "File not found $sg";
$c=<SGL>; 
while($c-- > 0) 
{
    $a=<SGL>; 
    chop($a);
    push @co, lc($a);
#    print "$a\n";
}
# print @co;

$ev = $f.".evl";
open(EVL, $ev) or die "File not found $ev";
for($i=0; $i<$dirnbr; $i++)
{
    $c=<EVL>; 
    while($c-- > 0) 
    {
	$a=<EVL>; 
	chop($a);
#	$dirs[$i][1+$#{$dirs[$i]}] = lc($a);
	push @{$dirs[$i]}, lc($a);
#	print "$a\n";
	$a=<EVL>;
    }
}

@{$dirs[$codirnr]} = @co;

print "env(";
for($i=0; $i<$dirnbr; $i++)
{
    if($i>0) 
    {
	print ",";
    }
    print "[";
    for($j=0; $j<=$#{$dirs[$i]}; $j++)
    {
	if($j>0) 
	{
	    print ",";
	}
	print $dirs[$i][$j];
    }
    print "]";
}
print ").\n";
