#!/usr/bin/perl


# run like:
# time for i in *.prf; do echo $i; hol2nrs $i >> 00; done
#

<>; $name=<>; chop($name);
$_=<>; die "bad" unless m/^>Inherit/;
while(<>)
{
    if(m/^[>]/)
    {
	print (" ", $name, ":", join(",",@refs), ";", join(",",@syms), "\n");
	exit;
    }
    elsif(m/^[ABDLTS].* +(.*)/)
    {
	push(@refs, $1);
    }
    else
    {
	m/^.* (.*)/ or die; push(@syms, $1)
    }
}
