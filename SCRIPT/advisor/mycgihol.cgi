#!/usr/bin/perl -w

use strict;
use CGI;
use IO::Socket;

my $query	  = new CGI;
my $input_fla	  = $query->param('Formula');
my $input_limit	  = $query->param('Limit');
my $text_mode     = $query->param('Text');
my (%gsyms,$grefs,$ref);
my $ghost	  = "localhost";
my $gport	  = "65000";
sub min { my ($x,$y) = @_; ($x <= $y)? $x : $y }

# returns nr. of syms with repetitions
sub GetQuerySymbols
{
    my ($fla, $syms) = @_;
    my $res = 0;

    while($fla =~ m/(`[^` ]+`)/g)
    {
#      push @syms, $1;
	$syms->{$1}	= ();	# counts can be here later
	$res++;
    }
    return $res;
}

# limit not used here yet
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
	print "The server is down, sorry\n";
	$query->end_html unless($text_mode);
	exit;
    }
    $remote->autoflush(1);
    print $remote join(",",(keys %$syms)) . "\n";
    $msgin = <$remote>;
    @res  = split(/\,/, $msgin);
    close $remote;
    return \@res;
}


print $query->header;
unless($text_mode)
{
    print $query->start_html("Proof Advisor Output");
}

if((length($input_fla) < 1)
   or ($input_limit < 1)
   or (0 == GetQuerySymbols($input_fla, \%gsyms)))
{
    print "Insufficient input: \n";
    print "$input_fla\n";
    $query->end_html unless($text_mode);
    exit;
}

$grefs = GetRefs(\%gsyms, $input_limit);
if($#{ @$grefs} < 1)
{
    print "Input contained no known symbols, no advice given\n";
    $query->end_html unless($text_mode);
    exit;
}


my $i = -1;
my $outnr = min($input_limit, 1+$#{ @$grefs});

unless($text_mode)
{
    print "<pre>";
    print $query->h2("References sorted by expected importance");
}

my $megrezurl = "http://megrez.mizar.org/cgi-bin/meaning.cgi";
my $merakurl  = "http://merak.pb.bialystok.pl/cgi-bin/mmlquery/meaning";
while(++$i < $outnr)
{
    my $ref = $grefs->[$i];
#    MPTP-like constructors commented, we now expect Query-like format
#    $ref=~/^([td])([0-9]+)_(.*)/ or die "Bad reference $ref\n";
#    ($kind, $nr, $an) = ($1, $2, $3);
#    $kind = ($kind eq "t")? "th" : "def";
	print "$ref\n";
}

unless($text_mode)
{
    print "<pre/>";
    print $query->end_html;
}
