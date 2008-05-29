
package CGI::FormBuilder::Field::file;

=head1 NAME

CGI::FormBuilder::Field::file - FormBuilder class for file fields

=head1 SYNOPSIS

    use CGI::FormBuilder::Field;

    # delegated straight from FormBuilder
    my $f = CGI::FormBuilder::Field->new($form,
                                         name => 'whatever',
                                         type => 'file');

=cut

use strict;

our $VERSION = '3.0302';

# hidden and password fields are rendered exactly like text fields

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

*render = \&tag;
sub tag {
    my $self = shift;
    # special catch to make life easier (too action-at-a-distance?)
    # if there's a 'file' field, set the form enctype if they forgot
    if ($self->{_form}->smartness) {
        $self->{_form}{enctype} ||= 'multipart/form-data';
        debug 2, "verified enctype => 'multipart/form-data' for 'file' field";
    }
    return $self->SUPER::tag(@_);
}

1;

__END__

=head1 DESCRIPTION

This module is internally used by B<FormBuilder> to create and maintain
field information. Usually, you will not want to directly access this
set of data structures. However, one big exception is if you are going
to micro-control form rendering. In this case, you will need to access
the field objects directly.

To do so, you will want to loop through the fields in order:

    for my $field ($form->field) {

        # $field holds an object stringified to a field name
        if ($field =~ /_date$/) {
            $field->sticky(0);  # clear CGI value
            print "Enter $field here:", $field->tag;
        } else {
            print $field->label, ': ', $field->tag;
        }
    }

As illustrated, each C<$field> variable actually holds a stringifiable
object. This means if you print them out, you will get the field name,
allowing you to check for certain fields. However, since it is an object,
you can then run accessor methods directly on that object.

The most useful method is C<tag()>. It generates the HTML input tag
for the field, including all option and type handling, and returns a 
string which you can then print out or manipulate appropriately.

Second to this method is the C<script> method, which returns the appropriate
JavaScript validation routine for that field. This is useful at the top of
your form rendering, when you are printing out the leading C<< <head> >> section
of your HTML document. It is called by the C<$form> method of the same name.

The following methods are provided for each C<$field> object.

=head1 METHODS

=head2 new($form, %args)

This creates a new C<$field> object. The first argument must be a reference
to the top-level C<$form> object, for callbacks. The remaining arguments
should be hash, of which one C<key/value> pair must specify the C<name> of
the field. Normally you should not touch this method. Ever.

=head2 field(%args)

This is a delegated field call. This is how B<FormBuilder> tweaks its fields.
Once you have a C<$field> object, you call this method the exact same way
that you would call the main C<field()> method, minus the field name. Again
you should use the top-level call instead.

=head2 jsfield()

Returns the appropriate JavaScript validation code (see above).

=head2 label($str)

This sets and returns the field's label. If unset, it will be generated
from the name of the field.

=head2 tag($type)

Returns an XHTML form input tag (see above). By default it renders the
tag based on the type set from the top-level field method:

    $form->field(name => 'poetry', type => 'textarea');

However, if you are doing custom rendering you can override this temporarily
by passing in the type explicitly. This is usually not useful unless you
have a custom rendering module that forcibly overrides types for certain
fields.

=head2 type($type)

This sets and returns the field's type. If unset, it will automatically 
generate the appropriate field type, depending on the number of options and
whether multiple values are allowed:

    Field options?
        No = text (done)
        Yes:
            Less than 'selectnum' setting?
                No = select (done)
                Yes:
                    Is the 'multiple' option set?
                    Yes = checkbox (done)
                    No:
                        Have just one single option?
                            Yes = checkbox (done)
                            No = radio (done)

For an example, view the inside guts of this module.

=head2 validate($pattern)

This returns 1 if the field passes the validation pattern(s) and C<required>
status previously set via required() and (possibly) the top-level new()
call in FormBuilder. Usually running per-field validate() calls is not
what you want. Instead, you want to run the one on C<$form>, which in
turn calls each individual field's and saves some temp state.

=head2 invalid

This returns the opposite value that C<validate()> would return, with
some extra magic that keeps state for form rendering purposes.

=head2 value($val)

This sets the field's value. It also returns the appropriate value: CGI if
set, otherwise the manual default value. Same as using C<field()> to
retrieve values.

=head2 tag_value()

This obeys the C<sticky> flag to give a different interpretation of CGI
values. B<Use this to get the value if generating your own tag.> Otherwise,
ignore it completely.

=head2 cgi_value()

This always returns the CGI value, regardless of C<sticky>.

=head2 def_value()

This always returns the default value, regardless of C<sticky>.

=head2 accessors

In addition to the above methods, accessors are provided for directly 
manipulating values as if from a C<field()> call:

    Accessor                Same as...                        
    ----------------------- -----------------------------------
    $f->force(0|1)          $form->field(force => 0|1)
    $f->options(\@opt)      $form->field(options => \@opt)
    $f->multiple(0|1)       $form->field(multiple => 0|1)
    $f->message($mesg)      $form->field(message => $mesg)
    $f->jsmessage($mesg)    $form->field(jsmessage => $mesg)
    $f->jsclick($code)      $form->field(jsclick => $code)
    $f->sticky(0|1)         $form->field(sticky => 0|1);
    $f->force(0|1)          $form->field(force => 0|1);
    $f->growable(0|1)       $form->field(growable => 0|1);
    $f->other(0|1)          $form->field(other => 0|1);

=head1 SEE ALSO

L<CGI::FormBuilder>

=head1 REVISION

$Id: file.pm,v 1.13 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

:wn

