
package CGI::FormBuilder::Field::hidden;

=head1 NAME

CGI::FormBuilder::Field::hidden - FormBuilder class for hidden fields

=head1 SYNOPSIS

    use CGI::FormBuilder::Field;

    # delegated straight from FormBuilder
    my $f = CGI::FormBuilder::Field->new($form,
                                         name => 'whatever',
                                         type => 'hidden');

=cut

use strict;

our $VERSION = '3.03';

# hidden and password fields are rendered exactly like text fields

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

sub script {
    return '';  # hidden fields are never checked
}

1;

__END__

=head1 DESCRIPTION

This module is used to create B<FormBuilder> elements of a specific type.
Currently, each type module inherits all of its methods from the main
L<CGI::FormBuilder::Field> module except for C<tag()> and C<script()>,
which affect the XHMTL representation of the field.

Please refer to L<CGI::FormBuilder::Field> and L<CGI::FormBuilder> for
documentation.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Field>

=head1 REVISION

$Id: hidden.pm,v 1.12 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nathan Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
