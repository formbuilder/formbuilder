#!/usr/bin/perl -I.

use strict;
use vars qw($TESTING $DEBUG $SKIP);
$TESTING = 1;
$DEBUG = $ENV{DEBUG} || 0;
use Test;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN {
    my $numtests = 4;

    plan tests => $numtests;

    # try to load template engine so absent template does
    # not cause all tests to fail
    eval "require Template";
    $SKIP = $@ ? 'skip: Template Toolkit not installed here' : 0;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}

# No tests written for TT2 because I don't use it and apparently
# nobody else really does either...

skip($SKIP, 1);
skip($SKIP, 1);
skip($SKIP, 1);
skip($SKIP, 1);

