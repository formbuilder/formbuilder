
package CGI::FormBuilder::Field::static;

=head1 NAME

CGI::FormBuilder::Field::static - FormBuilder class for static fields

=head1 SYNOPSIS

    use CGI::FormBuilder::Field;

    # delegated straight from FormBuilder
    my $f = CGI::FormBuilder::Field->new($form,
                                         name => 'whatever',
                                         type => 'static');

=cut

use strict;

our $VERSION = '3.0302';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use base 'CGI::FormBuilder::Field';

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

sub script {
    return '';        # static fields get no messages
}

*render = \&tag;
sub tag {
    local $^W = 0;    # -w sucks
    my $self = shift;
    my $attr = $self->attr;

    my $jspre = $self->{_form}->jsprefix;

    my @tag;
    my @value = $self->tag_value;   # sticky is different in <tag>
    my @opt   = $self->options;
    debug 2, "my(@opt) = \$field->options";

    # Add in our "Other:" option if applicable
    push @opt, [$self->othername, $self->{_form}{messages}->form_other_default]
             if $self->other;

    debug 2, "$self->{name}: generating $attr->{type} input type";

    # static fields are actually hidden
    $attr->{type} = 'hidden';

    # We iterate over each value - this is the only reliable
    # way to handle multiple form values of the same name
    # (i.e., multiple <input> or <hidden> fields)
    @value = (undef) unless @value; # this creates a single-element array

    for my $value (@value) {
        my $tmp = '';
 
        # setup the value
        $attr->{value} = $value;      # override
        delete $attr->{value} unless defined $value;

        # render the tag
        $tmp .= htmltag('input', $attr);

        #
        # If we have options, lookup the label instead of the true value
        # to print next to the field. This will happen when radio/select
        # lists are converted to 'static'.
        #
        for (@opt) {
            my($o,$n) = optval($_);
            if ($o eq $value) {
                $n ||= $attr->{labels}{$o} || ($self->nameopts ? toname($o) : $o);
                $value = $n;
                last;
            }
        }

        # print the value out too when in a static context
        $tmp .= escapehtml($value);
        push @tag, $tmp;
    }

    debug 2, "$self->{name}: generated tag = @tag";
    return join ' ', @tag;       # always return scalar tag
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

$Id: static.pm,v 1.12 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
