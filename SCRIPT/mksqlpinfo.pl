#!/usr/bin/perl -w

=head1 NAME

mksqlpinfo.pl ( Create fast loadable file for the SQL
                        probleminfo table)

=head1 SYNOPSIS

  # Create fast loadable probleminfo table

 export MPTPDIR=/home/urban/MPTP
 cd $MPTPDIR/SCRIPT
 ./mksqlpinfo.pl > /tmp/pinfo

  # Setup the mptpresults db, load probleminfo into it

 mysql> create database mptpresults;
 mysql> source /home/urban/MPTP/SCRIPT/MPTPResults.sql;
 mysql> LOAD DATA INFILE "/tmp/pinfo" INTO TABLE probleminfo;

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut

use strict;
use MPTPDebug;
use MPTPUtils;

my $fieldsepar  = "\t";     # MySQL field separator
my $linesepar   = "\n";     # MySQL line separator

my $refs   = $GFNAMES{'THR'};
my $pinfos = $MPTPDB."thprobleminfo.db";

open(REFS, $refs)     or die "$refs not readable!";
open(PINFOS, $pinfos) or die "$pinfos not readable!";


my ($ref,$pinfo);
ONE: while($ref = <REFS>)
{
    my ($tname, $aname, $thnr, $prf_length, $drefs, @dir_refs,
	@bg_refs, @conj_syms, @refsyms, @allsyms);

    $pinfo = <PINFOS>; # or die "$refs and $pinfos not synchronized!";

    $ref =~ m/^references\((\w+),(\d+),(\d+),(\d+),\[([^\]]*)\]\)\.$/
	or die "Bad references: $ref";

    ($tname, $prf_length, $drefs) = ($1, $4, $5);
    
    $pinfo =~ /^probleminfo\((\w+),\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\],\[([^\]]*)\]\)\.$/
	or die "Bad probleminfo: $pinfo";

    ($tname eq $1) or die "$refs and $pinfos not synchronized:$tname:$1";

    @bg_refs   = split(/\,/, $2);
    @conj_syms = split(/\,/, $3);
    @refsyms   = split(/\,/, $4);
    @allsyms   = split(/\,/, $5);

    @dir_refs  = split(/\,/, $drefs);

    $tname     =~ /^t(\d+)_(\w+)$/ or die "Bad theorem: $tname";

    ($thnr, $aname)  = ($1,$2);

    next ONE if($aname =~ /^canceled_.*$/); 

    print  $tname,                   $fieldsepar,
           $aname,                   $fieldsepar,
           $thnr,                    $fieldsepar, 
	   $prf_length,              $fieldsepar, 
	   1+$#dir_refs,             $fieldsepar, 
	   $drefs,                   $fieldsepar, 
	   1+$#bg_refs,              $fieldsepar; 
    print  join(",", @bg_refs),      $fieldsepar, 
	   2+$#bg_refs + $#dir_refs, $fieldsepar, 
	   1+$#conj_syms,            $fieldsepar, 
	   join(",", @conj_syms),    $fieldsepar, 
	   1+$#refsyms,              $fieldsepar, 
	   join(",", @refsyms),      $fieldsepar, 
	   1+$#allsyms,              $fieldsepar, 
	   join(",", @allsyms),      $linesepar;
}
