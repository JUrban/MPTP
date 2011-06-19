#!/usr/bin/perl -w

use strict;
use CGI;
use IO::Socket;

my $query	  = new CGI;
my $input_fla	  = $query->param('Formula');
my $text_mode     = $query->param('Text');
my (%gsyms,$grefs,$ref);
sub min { my ($x,$y) = @_; ($x <= $y)? $x : $y }

my $MyUrl= 'http://mizar.cs.ualberta.ca/~mptp/isawww/library/HOL/';

sub isa2htm
{
    my $in = @_;
    $_ = $in;
    s/_O/./g;
    s/__/_/g;
    my @s = split(/[\.]/, $_);
    return $MyUrl . $s[0] . '?go=' . join('.', @s[1 .. $#s]);
}

print $query->header;
print $query->start_html("HTMLized Output");

$_ = $input_fla;

s/[\n]/<br>/g;
s/\bfact_([a-zA-Z0-9_]+)/"<a href=\"" . isa2htm($1) . "\">fact_$1<\/a>"/ge;

print $_;
$query->end_html;

