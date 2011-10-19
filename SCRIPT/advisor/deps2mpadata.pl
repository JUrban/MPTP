#!/usr/bin/perl
# creating mpadata from the fine deps table
use strict;

my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # constr names as they come
my %cn_nums = (); 

my %d2m =
    (
     'rcluster', 'rc',
     'ccluster', 'cc',
     'fcluster', 'fc',
     'theorem', 't',
     'deftheorem', 'd',
     
    );


# memorized trnslation table for speed
my %j2mt = ();

sub j2m
{
    my ($d) = @_;
    return $j2mt{$d} if(exists $j2mt{$d});

    $d =~ m/^([a-z0-9_]+):([a-z0-9]+):\d+$/ or die "$d";
    my ($article, $k, $nr) = ($1, $2, $3);
    my $k1;

    if($k =~ m/([rcf])cluster/) { $k1 = $1 . 'c';  }
    elsif($k =~ m/([gklmruv])constructor/) { $k1 = 'dt_' . $1; }
    elsif($k =~ m/([gklmruv])identification/) { $k1 = 'ie' ; } #just 'k'
    elsif($k =~ m/([gklmruvj])pattern/) { $k1 = 'pattern'; }
    elsif($k =~ m/deftheorem|definiens/) { $k1 = 'd'; }
    elsif($k =~ m/theorem/) { $k1 = 't' ; }
    elsif($k =~ m/scheme/) { $k1 = 's' ; }
    elsif($k =~ m/lemma/) { $k1 = 'lemma'; }
    else { die "$d:::  $k"; }
    my $mn = $k1 . $nr . '_' . $article;
    $j2mt{$d} = [$k1, $mn];
    return $j2mt{$d};
}


while(<>)
{
  s/[\r\n]//;
  my @deps= split(/ +/);
  my ($k, $frst) = @{j2m($deps[0])};
#  if($k ~= m/^(t|s|d|ie|[rcf]c)$/)
  if($k =~ m/^t$/)
  {
      print ($frst , ' ');

      my %cns1 = ();
      my %refs1 = ();
   
      foreach my $d (@deps[1..$#deps])
      {
	  my ($k1, $d1) = @{j2m($d)};
	  if($k1 =~ m/dt_[a-z]/) {  $cns1{$d1} = (); }
	  elsif($k1 =~ m/^(t|s|d|ie|[rcf]c)$/) { $refs1{$d1} = (); }
      }
      print (join(' ', keys %refs1), "\n");
  }
}


=begin GHOSTCODE
	  foreach my $cn (keys %cns1)
	  {
	      if( !(exists $cn_nums{$cn})) 
	      {
		  push @cn_arr, $cn;
		  $cn_nums{$cn} = $#cn_arr;
	      }
	      my $nr = 200000+$cn_nums{$cn};
	      print ($nr , ',');
	  }

	  print $namenums{$frst};

	  unless( exists $namenums{$frst})
	  {
		  push @namearr, $frst;
		  $namenums{$frst} = $#namearr;
	  }

	  if($k ~= m/^(t|s|ie|[rcf]c)$/)
	  foreach my $ref (keys %refs1)
	  {
	      unless( exists $namenums{$ref})
	      {
		  push @namearr, $ref;
		  $namenums{$ref} = $#namearr;
	      }
	      print "$namenums{$ref}," unless($def);
	  }
    print "$namenums{$name}:\n"


  }
}

  foreach my $d (@deps)
  {
      $d =~ m/^([a-z0-9]+):([a-z0-9]+):\d+$/ or die "$d";
      my ($article, $k, $nr) = ($1, $2, $3);
      my $k1;

      if($k =~ m/([rcf])cluster/) { $k1 = $1 . 'c';  }
      elsif($k =~ m/([gklmruv])constructor/) { $k1 = 'dt_' . $1; }
      elsif($k =~ m/([gklmruv])identification/) { $k1 = 'dt_' . $1; }
      elsif($k =~ m/([gklmruv])pattern/) { $k1 = 'dt_' . $1; }
      elsif($k =~ m/deftheorem|definiens/) { $k1 = 'd'; }
      elsif($k =~ m/theorem/) { $k1 = 't' ; }
      elsif($k =~ m/scheme/) { $k1 = 's' ; }
      elsif($k =~ m/theorem/) { $k1 = 't' ; }

    my ($name, $fla, $cn, $ref, $def);
    my %cns1 = ();
    my %refs1 = ();
    $_ =~ m/(.*)=(.*)/;
    ($name, $fla) = ($1, $2);
    $def = ($name =~ m/:def/)? 1:0;
    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    while($fla =~ m/([0-9A-Z_]+:(sel|attr|mode|pred|func|struct|aggr) \d+)/g)
    {
	$cns1{$1} = ();
    }



}



#$BASEDIR = "4.19.880";
#chdir "$BASEDIR/tmp" or die 'no basedir/tmp';
system "grep -h \"theorem\\|scheme\" ../dli/*.dli > constrs0";
`grep -h \"^[0-9A-Z_]\\+:\\(sch\\|def\\|th\\)\" ../itm/*.outref |sort > refs`;
`grep -v \"theorem(.VERUM)\" constrs0 |sort >constrs`;
die 'dli and outref different' if(`wc -l constrs` != `wc -l refs`);
open(IN1, "constrs");
open(IN2, "refs");
my @namearr = (); # theorem names as they come
my %namenums = (); 
my @cn_arr = (); # theorem names as they come
my %cn_nums = (); 

while(<IN1>)
{
    my ($name, $fla, $cn, $ref, $def);
    my %cns1 = ();
    my %refs1 = ();
    $_ =~ m/(.*)=(.*)/;
    ($name, $fla) = ($1, $2);
    $def = ($name =~ m/:def/)? 1:0;
    unless( exists $namenums{$name})
    {
	push @namearr, $name;
	$namenums{$name} = $#namearr;
    }
    while($fla =~ m/([0-9A-Z_]+:(sel|attr|mode|pred|func|struct|aggr) \d+)/g)
    {
	$cns1{$1} = ();
    }
    foreach $cn (keys %cns1)
    {
	if( !(exists $cn_nums{$cn})) 
	{
	    push @cn_arr, $cn;
	    $cn_nums{$cn} = $#cn_arr;
	}
	my $nr = 100000+$cn_nums{$cn};
	print "$nr,";
    }
    $_ = <IN2>;
    $_ =~ m/(.*)=(.*)/;
    die 'files not in sync $1,$name' unless ($1 == $name);
    my $rfs = $2;
    while($rfs =~ m/([0-9A-Z_]+):(sch|def|th)? ?(\d+)/g)
    {
	my ($art,$nr,$what);
	$what = (defined $2)? $2:'th';
	($art, $nr) = ($1, $3);
	$refs1{$art . ':' . $what . ' ' . $3} = ();
    }
    foreach $ref (keys %refs1)
    {
	unless( exists $namenums{$ref})
	{
	    push @namearr, $ref;
	    $namenums{$ref} = $#namearr;
	}
	print "$namenums{$ref}," unless($def);
    }
    print "$namenums{$name}:\n"
}
open(OUT,">refnr");
map { print OUT "$_\n"; } @namearr;
close(OUT);

open(OUT,">symnr");
map { print OUT "$_\n"; } @cn_arr;
close(OUT);

=end GHOSTCODE
=cut
