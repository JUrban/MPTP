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
    my ($in) = @_;
    $_ = $in;
    s/_O/./g;
    s/__/_/g;
    my @s = split(/[\.]/, $_);
    return $MyUrl . $s[0] . '.html?go=' . join('.', @s[1 .. $#s]);
}

sub isa2title
{
    my ($in) = @_;
    $_ = $in;
    s/_O/./g;
    s/__/_/g;
    my @s = split(/[\.]/, $_);
    return $s[0] . '.' . join('.', @s[1 .. $#s]);
}

print $query->header;
print $query->start_html("HTMLized Output");

$_ = $input_fla;

s/[\n]/<br>/g;
s/\bfact_([a-zA-Z0-9_]+)/"<a title=\"" . isa2title($1) . "\" href=\"" . isa2htm($1) . "\">fact_$1<\/a>"/ge;
s/([^a-zA-Z0-9_])(t?c_)([a-zA-Z0-9_]+)/"$1<a title=\"" . isa2title($3) . "\" href=\"" . isa2htm($3) . "\">$2$3<\/a>"/ge;

print $_;
$query->end_html;

