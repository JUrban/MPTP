#!/usr/bin/perl -w

use strict;
use CGI;
use IO::Socket;

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


sub ReceiveFrom #($socket)
{
  my($socket) = $_[0];
  my($length, $char, $msg, $message, $received);

  $received = 0;
  $message = "";
  while ($received < 4)
  {
    recv $socket, $msg, 4 - $received, 0;
    $received += length $msg;
    $message .= $msg;
  }
  $length = unpack("N", $message);

  $received = 0;
  $message = "";
  while ($received < $length)
  {
    recv $socket, $msg, $length - $received, 0;
    $received += length $msg;
    $message .= $msg;
  }

  return $message;
}

my $ghost = "localhost";
my $gport = "60000";

sub GetRefs
{
    my ($syms, $limit) = @_;
#    my $msg = pack("a", (keys %$syms));
    my ($msgin, @res);

    my $EOL = "\015\012";
    my $BLANK = $EOL x 2;
    my $remote = IO::Socket::INET->new( Proto     => "tcp",
					PeerAddr  => $ghost,
					PeerPort  => $gport,
				      );
    unless ($remote) { die "cannot connect to advisor daemon on $ghost" }
    $remote->autoflush(1);
 #   send $remote, pack("N", length $msg), 0;
 #   print $remote $msg;
    print $remote join(",",(keys %$syms)) . $BLANK;
    $msgin = "";
#    while( $_=<$remote>) { $msgin = $msgin . $_ };
    $msgin = <$remote>;
    @res  = split(/\,/, $msgin);
#    $msgin = ReceiveFrom($remote);
#    @res = unpack("a", $msgin);
#    send $remote, pack("N", 0), 0;
    close $remote;

    return \@res;
}

print $query->header;
print $query->start_html("Proof Advisor Output");
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
