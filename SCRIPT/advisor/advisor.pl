#!/usr/bin/perl -w

=head1 NAME

advisor.pl ( Server translating Mizar symbols to numbers, [starting and]
             talking to snow)

=head1 SYNOPSIS

advisor.pl filestem [pathtosnow [snowport]]
advisor.pl /usr/local/share/mpadata/mpa1 /home/urban/bin/snow 50000

=cut

use strict;
use IO::Socket;

my (%gsyms,$grefs,$client);
my $gsymoffset=100000; # offset at which symbol numbering starts
my %grefnr;     # Ref2Nr hash for references
my @gnrref;     # Nr2Ref array for references

my %gsymnr;   # Sym2Nr hash for symbols
my @gnrsym;   # Nr2Sym array for symbols - takes gsymoffset into account!

my $filestem   = shift(@ARGV);
my $pathtosnow = shift(@ARGV);
my $snowport   = shift(@ARGV);

my $gport = 60000;

die "filestem missing" unless($filestem);

$snowport = 50000 unless(defined($snowport));

# change for verbose logging
sub LOGGING { 0 };

sub StartServer
{    
    my $i = 0;

    open(REFNR, "$filestem.refnr") or die "Cannot read refnr file";
    open(SYMNR, "$filestem.symnr") or die "Cannot read symnr file";

    while($_=<REFNR>) { chop; push(@gnrref, $_); };
    while($_=<SYMNR>) { chop; $gsymnr{$_} = $gsymoffset + $i++; };

    if(defined($pathtosnow))
    {
	my $snowcommand = $pathtosnow." -server " . $snowport 
	    . " -o allboth -F " . $filestem . ".net -A " 
		. $filestem . ".arch > /dev/null 2>&1 &";

	system($snowcommand);
	print "Snow started, may take a while to load\n";
    }
    else
    {
	print "Connecting to Snow\n";
    }
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



sub AskSnow
{
    my ($msg) = @_;
    my $parameters = "-o allboth";
    my @res;
    
    # First, establish a connection with the server.
    my $socket = IO::Socket::INET->new( Proto     => "tcp",
					PeerAddr  => "localhost",
					PeerPort  => $snowport,
				      );
    die "The server is down, sorry" unless ($socket);

    # Next, send the server your parameters.  Y
    # ou can (and should) use the command
    # commented below if you have no parameters to send:
    #send $socket, pack("N", 0), 0;
    send $socket, pack("N", length $parameters), 0;
    print $socket $parameters;

    # Whether you sent parameters or not, 
    # the server will then send you information
    # about the algorithms used in training the network.
    my $message = ReceiveFrom($socket);
    print "Snow: ", $message if(LOGGING);

    # Now, we're ready to start sending examples and receiving the results.
    # Send one example:
    send $socket, pack("N", length $msg), 0;
    print $socket $msg;

    # Receive the server's classification information:
    $message = ReceiveFrom($socket);

    # Last, tell the server that this client is done.
    send $socket, pack("N", 0), 0;
    
    print $message if(LOGGING);
    while($message=~/\b([0-9]+):/g) { push (@res, $1); };
    return \@res;
}


StartServer();


my $server = IO::Socket::INET->new( Proto     => "tcp",
				 LocalPort => $gport,
				 Listen    => SOMAXCONN,
				 Reuse     => 1);

die "cannot setup server" unless $server;
print "[Server $0 accepting clients]\n";



while ($client = $server->accept())
{
    my ($sym,$msg,$msgout,$msgout1,$msg1,@msg2,@res,@res1,@res2);
    $client->autoflush(1);

    $msg = "";

    print "[accepted client]\n";
#    $msg  = ReceiveFrom($client);
#    while( $_=<$client> ) { $msg = $msg . $_; }
    $msg = <$client>;
    print $msg if(LOGGING);
    chop $msg;
    print "[received bytes]\n";
#    @res  = unpack("a", $msg);
    @res = split(/\,/, $msg);
    @res1   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } @res;
    foreach $_ (@res1)
    {
	push(@res2,$_) if("" ne $_);
    }
#    $msgout = pack("a", @res2);
    $msgout = join(",", @res2);
    $msg1 = AskSnow($msgout . ":");
    print @$msg1, "\n" if(LOGGING);
    @msg2 = map { $gnrref[$_] } @$msg1;
    print @msg2, "\n" if(LOGGING);
    $msgout1 = join(",", @msg2);
#    send $client, pack("N", length $msgout), 0;
    print $client $msgout1;
    close $client;
    print "[closed client]\n";
}




