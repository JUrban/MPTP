#!/usr/bin/perl -w

use strict;
use CGI;
use IO::Socket;

my $query	  = new CGI;
my $input_fla	  = $query->param('Formula');
my $input_limit	  = $query->param('Limit');
my (%gsyms,$grefs,$ref);
my $ghost	  = "localhost";
my $gport	  = "60000";
my %gconstrs      =
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

    while($fla =~ /\b([0-9A-Z_]+):(func|pred|attr|mode|aggr|sel|struct) ([0-9]+)/g)
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
    my ($msgin, @res);
    my $EOL = "\015\012";
    my $BLANK = $EOL x 2;
    my $remote = IO::Socket::INET->new( Proto     => "tcp",
					PeerAddr  => $ghost,
					PeerPort  => $gport,
				      );
    unless ($remote)
    {
	print "The server is down, sorry";
	$query->end_html;
	exit;
    }
    $remote->autoflush(1);
    print $remote join(",",(keys %$syms)) . $BLANK;
    $msgin = <$remote>;
    @res  = split(/\,/, $msgin);
    close $remote;
    return \@res;
}




print $query->header;
print $query->start_html("Proof Advisor Output");

if((length($input_fla) < 1)
   or ($input_limit < 1)
   or (0 == GetQuerySymbols($input_fla, \%gsyms)))
{
    print "No fla\n";
    $query->end_html;
    exit;
}

$grefs = GetRefs(\%gsyms, $input_limit);

foreach $ref (@$grefs)
{
    print "$ref\n\n";
}

$query->end_html;
