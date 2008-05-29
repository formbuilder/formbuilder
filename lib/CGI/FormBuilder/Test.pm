
# Copyright (c) 2005 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Use "perldoc CGI::FormBuilder::Test" to read full documentation.

package CGI::FormBuilder::Test;

=head1 NAME

CGI::FormBuilder::Test - Test harness for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder::Test;

    my $test = 1;
    for (@tests) {
        my $outfile = outfile($test++);

    }

=cut

use strict;

our $VERSION = '3.03';
our $DEBUG = 0;

use Exporter;
use base 'Exporter';
our @EXPORT = qw(outfile);

use File::Basename;
use File::Spec::Functions;

sub outfile ($) {
    my($file, $dir) = fileparse($0);
    $file =~ s/-.*//;   # just save "1a-", "3d-", etc
    my $out = catfile($dir, sprintf("$file-test%2.2d.html", $_[0]));
    open(O, $out) || warn "Can't open $out: $!\n";
    return join '', <O>;
}

1;

=head1 DESCRIPTION

=head1 VERSION

$Id: Test.pm,v 1.14 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
