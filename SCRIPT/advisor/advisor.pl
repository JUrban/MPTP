#!/usr/bin/perl -w

use strict;
use IO::Socket;

my (%gsyms,$grefs);

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

my $gport = 60000;
my $server = IO::Socket::INET->new( Proto     => "tcp",
				 LocalPort => $gport,
				 Listen    => SOMAXCONN,
				 Reuse     => 1);

die "cannot setup server" unless $server;
print "[Server $0 accepting clients]\n";

my $client;

while ($client = $server->accept())
{
    my ($msg,$msgout,@res,@res1);
    $client->autoflush(1);

    $msg = "";

    print "[accepted client]\n";
#    $msg  = ReceiveFrom($client);
#    while( $_=<$client> ) { $msg = $msg . $_; }
    $msg = <$client>;
    print "[received bytes]\n";
#    @res  = unpack("a", $msg);
    @res = split(/\,/, $msg);
    print @res, "\n";
    @res1   = sort @res;
#    $msgout = pack("a", @res1);
    $msgout = join(",", @res1);
#    send $client, pack("N", length $msgout), 0;
    print $client $msgout;
    close $client;
    print "[closed client]\n";
}




