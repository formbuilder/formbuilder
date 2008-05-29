
package CGI::FormBuilder::Field::select;

=head1 NAME

CGI::FormBuilder::Field::select - FormBuilder class for select fields

=head1 SYNOPSIS

    use CGI::FormBuilder::Field;

    # delegated straight from FormBuilder
    my $f = CGI::FormBuilder::Field->new($form,
                                         name => 'whatever',
                                         type => 'select');

=cut

use strict;

our $VERSION = '3.03';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use base 'CGI::FormBuilder::Field';

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

sub script {
    my $self = shift;
    my $name = $self->name;

    # The way script() works is slightly backwards: First the
    # type-specific JS DOM code is generated, then this is
    # passed as a string to Field->jsfield, which wraps this
    # in the generic handling.

    # Holders for different parts of JS code
    my $jsfunc  = '';
    my $jsfield = tovar($name);
    my $close_brace = '';
    my $in = indent(my $idt = 1);   # indent

    my $alertstr = escapejs($self->jsmessage);  # handle embedded '
    $alertstr .= '\n';

    # Get value for field from select list
    # Always assume it's multiple to guarantee we get all values
    $jsfunc .= <<EOJS;
    // $name: select list, always assume it's multiple to get all values
    var $jsfield = null;
    var selected_$jsfield = 0;
    for (var loop = 0; loop < form.elements['$name'].options.length; loop++) {
        if (form.elements['$name'].options[loop].selected) {
            $jsfield = form.elements['$name'].options[loop].value;
            selected_$jsfield++;
EOJS

    # Add catch for "other" if applicable
    if ($self->other) {
        my $oth = $self->othername;
        $jsfunc .= <<EOJS;
            if ($jsfield == '$oth') $jsfield = form.elements['$oth'].value;
EOJS
        }

    $close_brace = <<EOJS;

        } // if
    } // for $name
EOJS

    $close_brace .= <<EOJS if $self->required;
    if (! selected_$jsfield) {
        alertstr += '$alertstr';
        invalid++;
    }
EOJS

    # indent the very last if/else tests so they're in the for loop
    $in = indent($idt += 2);

    return $self->jsfield($jsfunc, $close_brace, $in);
}

*render = \&tag;
sub tag {
    local $^W = 0;    # -w sucks
    my $self = shift;
    my $attr = $self->attr;

    my $jspre = $self->{_form}->jsprefix;

    my $tag   = '';
    my @value = $self->tag_value;   # sticky is different in <tag>
    my @opt   = $self->options;
    debug 2, "my(@opt) = \$field->options";

    # Add in our "Other:" option if applicable
    push @opt, [$self->othername, $self->{_form}{messages}->form_other_default]
             if $self->other;

    debug 2, "$self->{name}: generating $attr->{type} input type";

    # First the top-level select
    delete $attr->{type};     # type="select" invalid
    $self->multiple ? $attr->{multiple} = 'multiple'
                    : delete $attr->{multiple};

    belch "$self->{name}: No options specified for 'select' field" unless @opt;

    # Prefix options with "-select-", unless selectname => 0
    if ($self->{_form}->smartness && ! $attr->{multiple}  # set above
        && $self->selectname ne 0)
    {
        # Use selectname if => "choose" or messages otherwise
        my $name = $self->selectname =~ /\D+/
                 ? $self->selectname
                 : $self->{_form}{messages}->form_select_default;
        unshift @opt, ['', $name]
    }

    # Special event handling for our _other field
    if ($self->other && $self->javascript) {
        my $n = @opt - 1;           # last element
        my $b = $self->othername;   # box
        # w/o newlines
        $attr->{onchange} = "if (this.selectedIndex == $n) { "
                          . "${jspre}other_on('$b') } else { ${jspre}other_off('$b') }";
    }

    # render <select> tag
    $tag .= htmltag('select', $attr) . "\n";

    # Stuff for optgroups
    my $optgroups = $self->optgroups;
    my $lastgroup = '';
    my $didgroup  = 0;

    for my $opt (@opt) {
        # Since our data structure is a series of ['',''] things,
        # we get the name from that. If not, then it's a list
        # of regular old data that we toname() if nameopts => 1
        my($o,$n,$g) = optval($opt);
        debug 2, "optval($opt) = ($o,$n,$g)";

        # Must use defined() or else labels of "0" are lost
        unless (defined($n)) {
            $n = $attr->{labels}{$o};
            unless (defined($n)) {
                $n = $self->nameopts ? toname($o) : $o;
            }
        }

        # If we asked for optgroups => 1, then we add an our
        # <optgroup> each time our $lastgroup changes
        if ($optgroups) {
            if ($g && $g ne $lastgroup) {
                # close previous optgroup and start a new one
                $tag .= "  </optgroup>\n" if $didgroup;
                $lastgroup = $g;
                if (UNIVERSAL::isa($optgroups, 'HASH')) {
                    # lookup by name
                    $g = exists $optgroups->{$g} ? $optgroups->{$g} : $g;
                } elsif ($self->nameopts) {
                    $g = toname($g);
                }
                $tag .= '  ' . htmltag('optgroup', label => $g) . "\n";
                $didgroup++;
            } elsif (!$g && $lastgroup) {
                # finished an optgroup but next option is not in one
                $tag .= "  </optgroup>\n" if $didgroup;
                $didgroup = 0;  # reset counter
            }
        }

        my %slct = ismember($o, @value) ? (selected => 'selected') : ();
        $slct{value} = $o;

        $tag .= '  '
              . htmltag('option', %slct)
              . ($self->cleanopts ? escapehtml($n) : $n)
              . "</option>\n";

    }
    $tag .= "  </optgroup>\n" if $didgroup;
    $tag .= '  </select>';

    # add an additional tag for our _other field
    $tag .= ' ' . $self->othertag if $self->other;

    debug 2, "$self->{name}: generated tag = $tag";
    return $tag;       # always return scalar tag
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

$Id: select.pm,v 1.16 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
