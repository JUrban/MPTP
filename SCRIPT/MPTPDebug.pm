#------------------------------------------------------------------------
#
# File  : MPTPDebug.pm ( Debugging macros for MPTP)
#
# Author: Josef Urban
#
# Set the GWATCHED macro to watch the required
# parts of MPTP  on STDOUT. Default is just
# printing of nonexistant references.
#
#
# Changes
#
# <1> Tue Feb 11 21:26:44 2003
#     New
#------------------------------------------------------------------------

package MPTPDebug;
use strict;
use warnings;


our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    use Exporter   ();

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
		      &GWATCHED
		      &WATCH_NONE
		      &WATCH_COUNTS
		      &WATCH_RAWBG
		      &WATCH_BADREFS
		      &WATCH_DB
		      &WATCH_FILTER_BGCACHE
		      &WATCH_FILTER_SYMBOLS
		      &WATCH_FILTER_FIXPOINT		      
		      &WATCH_FILTER
		      );
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}

sub WATCH_NONE             ()  { 0 }
sub WATCH_COUNTS           ()  { 1 }
sub WATCH_RAWBG            ()  { 2 }
sub WATCH_BADREFS          ()  { 4 }
sub WATCH_DB               ()  { 8 }
sub WATCH_FILTER_BGCACHE   ()  { 128 }
sub WATCH_FILTER_SYMBOLS   ()  { 256 }
sub WATCH_FILTER_FIXPOINT  ()  { 512 }
sub WATCH_FILTER           ()  { WATCH_FILTER_BGCACHE  | 
				 WATCH_FILTER_SYMBOLS  |
				 WATCH_FILTER_FIXPOINT  }

sub WATCH_ALL              ()  { WATCH_COUNTS          |
				 WATCH_RAWBG           |
				 WATCH_BADREFS         |
				 WATCH_DB              |
				 WATCH_FILTER           }

# sub GWATCHED () { WATCH_ALL }
# sub GWATCHED () { WATCH_FILTER }
# sub GWATCHED () { WATCH_NONE }
sub GWATCHED () { WATCH_BADREFS }


