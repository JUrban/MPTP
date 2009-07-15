#!/usr/bin/perl

=head1 NAME

isa2nrs.pl (creating numbered data for SNoW from Isabelle data)

=head1 SYNOPSIS

./isa2nrs.pl isaproofs > snowdata

=head1 DESCRIPTION

Create numbered data for SNoW from Isabelle data.
The supposed format is one file
each line in each starting with the theorem name followed by colon;
then come the references (possibly none) comma-separated and ended by semicolon, and
the comma-separated symbols ended by newline.

=cut


use strict;

# die 'syms and refs different' if(`wc -l constrs` != `wc -l refs`);
#open(IN1, "constrs");
#open(IN2, "refs");
my $gsymoffset    = 100000; # offset at which symbol numbering starts
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # symbol names as they come
my %cn_nums = (); 

while(<>)
{
    my ($name, $def, $refs_string, $symbols_string);
    my %cns1 = ();
    my %refs1 = ();
    chop($_);
#    $_ =~ m/([^: ]+):([^;]*);([^;]*);.*/ or die "Bad line $_";
    # some lines are bad: [] T : ; "all", "=="  at line 4864.
    s/([,:;]) */$1/g;
    if ($_ =~ m/^[^:]* ([^: ]+):([^;]*);(.*)/)
    {
       ($name, $refs_string, $symbols_string) = ($1, $2, $3);
       unless( exists $namenums{$name})
       {
	   push @namearr, $name;
	   $namenums{$name} = $#namearr;
       }
       @cns1{ (split(/,/, $symbols_string)) } = ();
       foreach my $cn (keys %cns1)
       {
	   if( !(exists $cn_nums{$cn}))
	   {
	       push @cn_arr, $cn;
	       $cn_nums{$cn} = $#cn_arr;
	   }
	   my $nr = $gsymoffset + $cn_nums{$cn};
	   print "$nr," unless ($cn eq "");
       }
       @refs1{ (split(/,/, $refs_string)) } = ();
       foreach my $ref (keys %refs1)
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
}
open(OUT,">refnr");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

