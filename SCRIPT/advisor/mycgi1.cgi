#!/usr/bin/perl -w

use strict;
use CGI;

my $query	 = new CGI;
my $input_fla	 = $query->param('Formula');
my $input_limit	 = $query->param('Limit');
my (%gsyms,$grefs);

my %gconstrs        = 
    (
     'func'   , 'k',
     'pred'   , 'r',
     'attr'   , 'v',
     'mode'   , 'm',
     'aggr'   , 'g',
     'sel'    , 'u',
     'struct' , 'l'
    );

# returns nr. of syms with repetitions
sub GetQuerySymbols
{
    my ($fla, $syms) = @_;
    my $res = 0;

    while($fla =~ / ([0-9A-Z_]+):(func|pred|attr|mode|aggr|sel|struct) ([0-9]+)/g)
    {
	my $aname	= lc($1);
	my $sname	= $gconstrs{$2}."$3"."_".$aname;

	$syms->{$sname}	= ();	# counts can be here later
	$res++;
    }
    return $res;
}

sub GetRefs
{
    my ($syms, $limit) = @_;
    my @res = (keys %$syms);
    return \@res;
}


print $query->header, 
    $query->start_html('Proof Advisor Output');
#    $query->h1('Hello World');

if((length($input_fla) < 1)
   or ($input_limit < 1)
   or (0 == GetQuerySymbols($input_fla, \%gsyms)))
{
#    print "No fla\n";
    $query->end_html;
    exit;
}

$grefs = GetRefs(\%gsyms, $input_limit);
print "Is fla\n";

my $ref;

foreach $ref (@$grefs)
{
    print "$ref\n\n";
}

$query->end_html;
