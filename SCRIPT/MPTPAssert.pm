#------------------------------------------------------------------------
#
# File  : MPTPAssert.pm ( Assertion macros for MPTP)
#
# Author: Josef Urban
#
# Set the GASSERTIONS macro to include asssertions about
# the required parts of MPTP. Done a bit differently from
# GWATCHED, not to have to quote GASSERTIONS all the time.
# Also there is a general (unspecific) ASSERT.
# Default is no assertions.
#
#
# Changes
#
# <1> Mon Oct 20 13:51:18 2003
#     New
#------------------------------------------------------------------------

package MPTPAssert;
use strict;
use warnings;


our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    use Exporter   ();

    @ISA         = qw(Exporter);
    @EXPORT      = qw(
		      &ASSERT_COUNTS
		      &ASSERT_RAWBG
		      &ASSERT_BADREFS
		      &ASSERT_DB
		      &ASSERT_FILTER_BGCACHE
		      &ASSERT_FILTER_SYMBOLS
		      &ASSERT_FILTER_FIXPOINT
                      &ASSERT_BAD_SYMBOLS
                      &ASSERT_BAD_FRM_NAMES
                      &ASSERT
		      );
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ( FIELDS => [ @EXPORT_OK, @EXPORT ] );
}

sub ASSERTION_NONE             ()  { 0 }
sub ASSERTION_COUNTS           ()  { 1 }
sub ASSERTION_RAWBG            ()  { 2 }
sub ASSERTION_BADREFS          ()  { 4 }
sub ASSERTION_DB               ()  { 8 }
sub ASSERTION_FILTER_BGCACHE   ()  { 128 }
sub ASSERTION_FILTER_SYMBOLS   ()  { 256 }
sub ASSERTION_FILTER_FIXPOINT  ()  { 512 }
sub ASSERTION_FILTER           ()  { ASSERTION_FILTER_BGCACHE  |
				     ASSERTION_FILTER_SYMBOLS  |
				     ASSERTION_FILTER_FIXPOINT  }
sub ASSERTION_BAD_SYMBOLS      ()  { 1024 }
sub ASSERTION_BAD_FRM_NAMES    ()  { 2048 }
sub ASSERTION_BAD_NAMES        ()  { ASSERTION_BAD_SYMBOLS     |
				     ASSERTION_BAD_FRM_NAMES    }
sub ASSERTION_GENERAL          ()  { 1 << 30 }
sub ASSERTION_ALL              ()  { ASSERTION_COUNTS          |
				     ASSERTION_RAWBG           |
				     ASSERTION_BADREFS         |
				     ASSERTION_DB              |
				     ASSERTION_FILTER          |
				     ASSERTION_BAD_NAMES       |
				     ASSERTION_GENERAL          }


# sub GASSERTIONS () { ASSERTION_ALL }
# sub GASSERTIONS () { ASSERTION_FILTER }
# sub GASSERTIONS () { ASSERTION_GENERAL }
 sub GASSERTIONS () { ASSERTION_ALL }
# sub GASSERTIONS () { ASSERTION_BADREFS }

sub ASSERT_COUNTS           ()  { GASSERTIONS & ASSERTION_COUNTS }
sub ASSERT_RAWBG            ()  { GASSERTIONS & ASSERTION_RAWBG }
sub ASSERT_BADREFS          ()  { GASSERTIONS & ASSERTION_BADREFS }
sub ASSERT_DB               ()  { GASSERTIONS & ASSERTION_DB }
sub ASSERT_FILTER_BGCACHE   ()  { GASSERTIONS & ASSERTION_FILTER_BGCACHE }
sub ASSERT_FILTER_SYMBOLS   ()  { GASSERTIONS & ASSERTION_FILTER_SYMBOLS }
sub ASSERT_FILTER_FIXPOINT  ()  { GASSERTIONS & ASSERTION_FILTER_FIXPOINT }
sub ASSERT_BAD_SYMBOLS      ()  { GASSERTIONS & ASSERTION_BAD_SYMBOLS }
sub ASSERT_BAD_FRM_NAMES    ()  { GASSERTIONS & ASSERTION_BAD_FRM_NAMES }
sub ASSERT                  ()  { GASSERTIONS & ASSERTION_GENERAL }



