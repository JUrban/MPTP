#!/usr/bin/perl -w
#------------------------------------------------------------------------
#
# File  : MPTPParseSPASS.pl (SPASS results parser)
#
# Author: Josef Urban
#
# Gets a file F containing one or more SPASS results
# and outputs files F.proved, F.proof and F.unproved
# in a MySQL fast-loadable format.
# The SQL format must correspond to the tables created 
# by the sql script MPTPResults.sql.
# The first column in these tables is auto-incremented id,
# which is same for the 'proved' and 'proof' table.
# To have the tables consistent, starting value of id for
# the 'proved' and 'unproved' table may be passed as a parameter.
#
# Changes
#
# <1> Tue Mar 18 20:37:55 2003
#     New
#------------------------------------------------------------------------
use strict;
use Getopt::Long;
use MPTPDebug;
use MPTPUtils;

my $ProvedStart        = 1;
my $UnprovedStart      = 1;
my $Format             = "DFG";   
my $Prover             = "SPASS_2_0";   
my $time_limit	       = 4;			# In seconds 
my $memory_limit       = 200000;		# In kb 
my $prover_parameters  = "-TimeLimit=4 -Memory=200000000 -PGiven=0 PProblem=0 -DocProof" ;
my $start_date	       = "2003/03/15";                    # mandatory
my $hostname	       = "lipa.ms.mff.cuni.cz";
my $machine_cpu	       = "P4";
my $machine_memory     = 512232;		# In kb 
my $machine_os	       = "Linux";

my $escapechar  = '\\';
my $fieldsepar  = "\t";     # MySQL field separator
my $linesepar   = "\n";     # MySQL line separator



sub Usage 
{
    print "Gets a file F containing one or more SPASS results
 and outputs files F.proved, F.proof and F.unproved
 in a MySQL fast-loadable format.
 The SQL format must correspond to the tables created 
 by the sql script MPTPResults.sql.
 The first column in these tables is auto-incremented id,
 which is same for the 'proved' and 'proof' table.
 To have the tables consistent, starting value of id for
 the 'proved' and 'unproved' table may be passed as a parameter,
 using the --provedstart (-p) or --unprovedstart(-u) options.
 The only required parameter is --start_date (-d) specified
 as YYYY/MM/DD (2003/03/15).";
    exit;
}

Getopt::Long::Configure ("bundling");

GetOptions('provedstart|p:i'         => \$ProvedStart,
	   'unprovedstart|u:i'       => \$UnprovedStart,
	   'Format|F:s'              => \$Format,
	   'Prover|P:s'              => \$Prover,
	   'time_limit|t:i'          => \$time_limit,	    
	   'memory_limit|m:i'        => \$memory_limit,
	   'prover_parameters|r:s'   => \$prover_parameters,
	   'start_date|d=s'          => \$start_date,
	   'hostname|h:s'            => \$hostname,
	   'machine_cpu|c:s'         => \$machine_cpu,
	   'machine_memory|M:i'      => \$machine_memory,
	   'machine_os|o:s'          => \$machine_os)

    or Usage();


if ($#ARGV != 0)
{
    Usage();
}


my $gproved       = $ProvedStart;
my $gunproved     = $UnprovedStart;
my $gresfname     = $ARGV[0];
my $provedfname   = $gresfname.".proved";
my $unprovedfname = $gresfname.".unproved";
my $prooffname    = $gresfname.".proof";

open(IN, $gresfname)              or die "Input file unreadable";
open(PROVED, ">$provedfname")     or die "$provedfname not writable";
open(UNPROVED, ">$unprovedfname") or die "$unprovedfname not writable";
open(PROOF, ">$prooffname")       or die "$prooffname not writable";

#------------------------------------------------------------------------
#  Function    : DoOneResult()
#
#  Parse oe result from input, write into outpur.
#
#  Input       : -
#  Global Vars : 
#  Side Effects: 
#------------------------------------------------------------------------

sub DoOneResult
{
    my ($result) = @_;
    my ($fout, $fla, %used);


    my ($count, $pname,   $aname,       $thnr, 
	$res,   $derived, $backtracked, $kept,
	$memory_allocated,
	$time,  $input_time, $flotter_time, $inferences_time,
	$backtracking_time,  $reduction_time);
	
	
    my ($proof_length, $proof_depth, @used_flas, 
	@used_refs, @used_bg);

  SWITCH: for $_ ($result)
  {
      /^\s*Proof found.\s*$/         && do { $res = 'PROOF'; last;};
      /^\s*Completion found.\s*$/   && do { $res = 'COMPLETION'; last;};
      /^\s*Ran out of time.\s*$/     && do { $res = 'TIMELIMIT'; last;};
      /^\s*Ran out of memoory.\s*$/  && do { $res = 'MEMLIMIT'; last;};

      $res = 'UNKNOWN';
  }

    $_ = <IN>;

    /^Problem:\s*t(\d+)_(\w+).*$/ 
	or die "Bad problem name: $_";

    ($thnr, $aname) = ($1, $2);
    $pname          = "t".$thnr."_".$aname;

    $_ = <IN>;

    /^\s*SPASS derived\s*(\d+)\s*clauses,\s*backtracked\s*(\d+)\s*clauses\s*and\s*kept\s*(\d+)\s*clauses\.\s*$/
	or die "Bad problem clauses info: $_";
    
    ($derived, $backtracked, $kept) = ($1, $2, $3);

    $_ = <IN>;

    /^\s*SPASS allocated\s*(\d+)\s*KBytes\.\s*$/ 
	or die "Bad problem memory info: $_";

    $memory_allocated = $1;

    $_ = <IN>;

    /^SPASS spent\s*(\d+):(\d+):(\d+)[.](\d+)\s*on the problem\.\s*$/
	or die "Bad problem time info: $_";

    $time = $3+(60*$2)+(3600*$1);


    $_ = <IN>;

    /^\s*(\d+):(\d+):(\d+)[.](\d+)\s*for the input\.\s*$/
	or die "Bad problem input time info: $_";

    $input_time = $3+(60*$2)+(3600*$1);

    $_ = <IN>;

    /^\s*(\d+):(\d+):(\d+)[.](\d+)\s*for the FLOTTER CNF translation\.\s*$/
	or die "Bad problem flotter time info: $_";

    $flotter_time = $3+(60*$2)+(3600*$1);
	
    $_ = <IN>;

    /^\s*(\d+):(\d+):(\d+)[.](\d+)\s*for inferences\.\s*$/
	or die "Bad problem inferences time info: $_";

    $inferences_time = $3+(60*$2)+(3600*$1);

    $_ = <IN>;

    /^\s*(\d+):(\d+):(\d+)[.](\d+)\s*for the backtracking\.\s*$/
	or die "Bad problem backtracking time info: $_";

    $backtracking_time = $3+(60*$2)+(3600*$1);

    $_ = <IN>;

    /^\s*(\d+):(\d+):(\d+)[.](\d+)\s*for the reduction\.\s*$/
	or die "Bad problem reduction time info: $_";

    $reduction_time = $3+(60*$2)+(3600*$1);

	    
    if($res eq 'PROOF')
    {
# proof must be given
	$_ = <IN>;

	$count = $gproved++;
#	$fout  = PROVED;
	%used  = ();

	while(($_ = <IN>) && /^\s*$/) {};
	    
	/^Here is a proof with depth\s*(\d+),\s*length\s*(\d+)\s*:\s*$/
	    or die "Bad proof info: $_";
	  

	($proof_depth, $proof_length) = ($1, $2);

	print PROOF ($count, $fieldsepar, $pname, $fieldsepar);
	while(($_ = <IN>) && ! (/^Formulae.*/))
	{
	    chop($_);
	    print PROOF ($_,$escapechar,"\n");
	}

	print PROOF $linesepar;

	$_= /^Formulae used in the proof\s*:(.*)$/
	    or die "Bad used formulas info: $_";

	@used{ split(/ +/, $1) } = ();
	delete $used{""};
	@used_flas = sort keys %used;

	foreach $fla (@used_flas)
	{
	    if($fla =~ /^[td]\d+.*$/)
	    {
		push @used_refs, $fla;
	    }
	    else
	    {
		push @used_bg, $fla;
	    }
	}

	print  PROVED
	   ($count,              $fieldsepar, 
            $pname,              $fieldsepar,   
            $aname,              $fieldsepar,       
	    $thnr,               $fieldsepar, 
	    $Format,             $fieldsepar, 
	    $Prover,             $fieldsepar,
	    $res,                $fieldsepar);

	print  PROVED ($proof_depth,    $fieldsepar, 
		       $proof_length,   $fieldsepar);


	print  PROVED
	   ($derived,            $fieldsepar, 
	    $backtracked,        $fieldsepar, 
	    $kept,               $fieldsepar,
	    $memory_allocated,   $fieldsepar,
	    $time,               $fieldsepar,  
	    $input_time,         $fieldsepar, 
	    $flotter_time,       $fieldsepar, 
	    $inferences_time,    $fieldsepar,
	    $backtracking_time,  $fieldsepar,  
	    $reduction_time,     $fieldsepar,
	    $time_limit,         $fieldsepar,
	    $memory_limit,       $fieldsepar,
	    $prover_parameters,  $fieldsepar,
	    $start_date,         $fieldsepar,
	    $hostname,           $fieldsepar,
	    $machine_cpu,        $fieldsepar,
	    $machine_memory,     $fieldsepar,
	    $machine_os);
	
	print PROVED
	    ($fieldsepar,
	     1+$#used_flas,             $fieldsepar, 
	     join(",", @used_flas),     $fieldsepar, 
	     1+$#used_refs,             $fieldsepar, 
	     join(",", @used_refs),     $fieldsepar, 
	     1+$#used_bg,               $fieldsepar, 
	     join(",", @used_bg),       $fieldsepar);

	print PROVED $linesepar;

    }
    else
    {
	$count = $gunproved++;
#	$fout  = UNPROVED;
    

	print  UNPROVED
	   ($count,              $fieldsepar, 
            $pname,              $fieldsepar,   
            $aname,              $fieldsepar,       
	    $thnr,               $fieldsepar, 
	    $Format,             $fieldsepar, 
	    $Prover,             $fieldsepar,
	    $res,                $fieldsepar);

	print UNPROVED
	   ($derived,            $fieldsepar, 
	    $backtracked,        $fieldsepar, 
	    $kept,               $fieldsepar,
	    $memory_allocated,   $fieldsepar,
	    $time,               $fieldsepar,  
	    $input_time,         $fieldsepar, 
	    $flotter_time,       $fieldsepar, 
	    $inferences_time,    $fieldsepar,
	    $backtracking_time,  $fieldsepar,  
	    $reduction_time,     $fieldsepar,
	    $time_limit,         $fieldsepar,
	    $memory_limit,       $fieldsepar,
	    $prover_parameters,  $fieldsepar,
	    $start_date,         $fieldsepar,
	    $hostname,           $fieldsepar,
	    $machine_cpu,        $fieldsepar,
	    $machine_memory,     $fieldsepar,
	    $machine_os);

	print UNPROVED $linesepar;
    }
}




while(<IN>)
{
    if(m/^SPASS beiseite:(.*)$/)
    {
	DoOneResult($1);
    }
}


close(IN);
close(PROVED);
close(UNPROVED);
close(PROOF);
