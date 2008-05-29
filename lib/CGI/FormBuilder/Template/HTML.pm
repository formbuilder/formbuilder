
package CGI::FormBuilder::Template::HTML;

=head1 NAME

CGI::FormBuilder::Template::HTML - FormBuilder interface to HTML::Template

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    template => 'form.tmpl',
               );

=cut

use Carp;
use strict;

our $VERSION = '3.03';

use CGI::FormBuilder::Util;
use HTML::Template;
use base 'HTML::Template';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_;

    $opt{die_on_bad_params} = 0;    # force to avoid blow-ups
    $opt{engine} = HTML::Template->new(%opt);

    return bless \%opt, $class;     # rebless
}

sub engine {
    return shift()->{engine};
}

sub render {
    my $self = shift;
    my $form = shift;

    # a couple special fields
    my %tmplvar = $form->tmpl_param;

    # must generate JS first since it affects the others
    $tmplvar{'js-head'}     = $form->script;
    $tmplvar{'form-title'}  = $form->title;
    $tmplvar{'form-start'}  = $form->start . $form->statetags . $form->keepextras;
    $tmplvar{'form-submit'} = $form->submit;
    $tmplvar{'form-reset'}  = $form->reset;
    $tmplvar{'form-end'}    = $form->end;

    # for HTML::Template, each data struct is manually assigned
    # to a separate <tmpl_var> and <tmpl_loop> tag
    for my $field ($form->field) {

        # Extract value since used often
        my @value = $field->tag_value;

        # assign the field tag
        $tmplvar{"field-$field"} = $field->tag;
        debug 2, "<tmpl_var field-$field> = " . $tmplvar{"field-$field"};

        # and the value tag - can only hold first value!
        $tmplvar{"value-$field"} = $value[0];
        debug 2, "<tmpl_var value-$field> = " . $tmplvar{"value-$field"};

        # and the label tag for the field
        $tmplvar{"label-$field"} = $field->label;
        debug 2, "<tmpl_var label-$field> = " . $tmplvar{"value-$field"};

        # and the comment tag
        $tmplvar{"comment-$field"} = $field->comment;

        # and any error
        $tmplvar{"error-$field"} = $field->error;

        # create a <tmpl_loop> for multi-values/multi-opts
        # we can't include the field, really, since this would involve
        # too much effort knowing what type
        my @tmpl_loop = ();
        for my $opt ($field->options) {
            # Since our data structure is a series of ['',''] things,
            # we get the name from that. If not, then it's a list
            # of regular old data that we _toname if nameopts => 1 
            my($o,$n) = optval $opt;
            $n ||= $field->nameopts ? toname($o) : $o;
            my($slct, $chk) = ismember($o, @value) ? ('selected', 'checked') : ('','');
            debug 2, "<tmpl_loop loop-$field> = adding { label => $n, value => $o }";
            push @tmpl_loop, {
                label => $n,
                value => $o,
                checked => $chk,
                selected => $slct,
            };
        }

        # now assign our loop-field
        $tmplvar{"loop-$field"} = \@tmpl_loop;

        # finally, push onto a top-level loop named "fields"
        push @{$tmplvar{fields}}, {
            field   => $field->tag,
            value   => $value[0],
            values  => \@value,
            options => [ $field->options ],
            label   => $field->label,
            comment => $field->comment,
            error   => $field->error,
            loop    => \@tmpl_loop
        }
    }

    # loop thru each field we have and set the tmpl_param
    while(my($param, $tag) = each %tmplvar) {
        $self->{engine}->param($param => $tag);
    }

    # prepend header to template rendering
    return $form->header . $self->{engine}->output;
}

1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<HTML::Template>.
C<HTML::Template> is the default template option and is activated
one of two ways. Either:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => 'form.tmpl',
               );

Or, you can specify any options which C<< HTML::Template->new >>
accepts by using a hashref:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'HTML',
                        filename => 'form.tmpl',
                        shared_cache => 1,
                        loop_context_vars => 1
                    }
                );

In your template, each of the form fields will correspond directly to
a C<< <tmpl_var> >> of the same name prefixed with "field-" in the
template. So, if you defined a field called "email", then you would
setup a variable called C<< <tmpl_var field-email> >> in your template.

In addition, there are a couple special fields:

    <tmpl_var js-head>     -  JavaScript to stick in <head>
    <tmpl_var form-title>  -  The <title> of the HTML form
    <tmpl_var form-start>  -  Opening <form> tag and internal fields
    <tmpl_var form-submit> -  The submit button(s)
    <tmpl_var form-reset>  -  The reset button
    <tmpl_var form-end>    -  Just the closing </form> tag

Let's look at an example C<form.tmpl> template we could use:

    <html>
    <head>
    <title>User Information</title>
    <tmpl_var js-head><!-- this holds the JavaScript code -->
    </head>
    <tmpl_var form-start><!-- this holds the initial form tag -->
    <h3>User Information</h3>
    Please fill out the following information:
    <!-- each of these tmpl_var's corresponds to a field -->
    <p>Your full name: <tmpl_var field-name>
    <p>Your email address: <tmpl_var field-email>
    <p>Choose a password: <tmpl_var field-password>
    <p>Please confirm it: <tmpl_var field-confirm_password>
    <p>Your home zipcode: <tmpl_var field-zipcode>
    <p>
    <tmpl_var form-submit><!-- this holds the form submit button -->
    </form><!-- can also use "tmpl_var form-end", same thing -->

As you see, you get a C<< <tmpl_var> >> for each for field you define.

However, you may want even more control. That is, maybe you want
to specify every nitty-gritty detail of your input fields, and
just want this module to take care of the statefulness of the
values. This is no problem, since this module also provides
several other C<< <tmpl_var> >> tags as well:

    <tmpl_var value-[field]>   - The value of a given field
    <tmpl_var label-[field]>   - The human-readable label
    <tmpl_var comment-[field]> - Any optional comment
    <tmpl_var error-[field]>   - Error text if validation fails

This means you could say something like this in your template:

    <tmpl_var label-email>:
    <input type="text" name="email" value="<tmpl_var value-email>">
    <font size="-1"><i><tmpl_var error-email></i></font>

And B<FormBuilder> would take care of the value stickiness for you,
while you have control over the specifics of the C<< <input> >> tag.
A sample expansion may create HTML like the following:

    Email:
    <input type="text" name="email" value="nate@wiger.org">
    <font size="-1"><i>You must enter a valid value</i></font>

Note, though, that this will only get the I<first> value in the case
of a multi-value parameter (for example, a multi-select list). To
remedy this, if there are multiple values you will also get a
C<< <tmpl_var> >> prefixed with "loop-". So, if you had:

    myapp.cgi?color=gray&color=red&color=blue

This would give the C<color> field three values. To create a select
list, you would do this in your template:

    <select name="color" multiple>
    <tmpl_loop loop-color>
        <option value="<tmpl_var value>"><tmpl_var label></option>
    </tmpl_loop>
    </select>

With C<< <tmpl_loop> >> tags, each iteration gives you several
variables:

    Inside <tmpl_loop>, this...  Gives you this
    ---------------------------  -------------------------------
    <tmpl_var value>             value of that option
    <tmpl_var label>             label for that option
    <tmpl_var checked>           if selected, the word "checked"
    <tmpl_var selected>          if selected, the word "selected"

Please note that C<< <tmpl_var value> >> gives you one of the I<options>,
not the values. Why? Well, if you think about it you'll realize that
select lists and radio groups are fundamentally different from input
boxes in a number of ways. Whereas in input tags you can just have
an empty value, with lists you need to iterate through each option
and then decide if it's selected or not.

When you need precise control in a template this is all exposed to you;
normally B<FormBuilder> does all this magic for you. If you don't need
exact control over your lists, simply use the C<< <tmpl_var field-[name]> >>
tag and this will all be done automatically, which I strongly recommend.

But, let's assume you need exact control over your lists. Here's an
example select list template:

    <select name="color" multiple>
    <tmpl_loop loop-color>
    <option value="<tmpl_var value>" <tmpl_var selected>><tmpl_var label>
    </tmpl_loop>
    </select>

Then, your Perl code would fiddle the field as follows:

    $form->field( 
              name => 'color', nameopts => 1,
              options => [qw(red green blue yellow black white gray)]
           );

Assuming query string as shown above, the template would then be expanded
to something like this:

    <select name="color" multiple>
    <option value="red" selected>Red
    <option value="green" >Green
    <option value="blue" selected>Blue
    <option value="yellow" >Yellow
    <option value="black" >Black
    <option value="white" >White
    <option value="gray" selected>Gray
    </select>

Notice that the C<< <tmpl_var selected> >> tag is expanded to the word
"selected" when a given option is present as a value as well (i.e.,
via the CGI query). The C<< <tmpl_var value> >> tag expands to each option
in turn, and C<< <tmpl_var label> >> is expanded to the label for that
value. In this case, since C<nameopts> was specified to C<field()>, the
labels are automatically generated from the options.

Let's look at one last example. Here we want a radio group that allows
a person to remove themself from a mailing list. Here's our template:

    Do you want to be on our mailing list?
    <p><table>
    <tmpl_loop loop-mailopt>
    <td bgcolor="silver">
      <input type="radio" name="mailopt" value="<tmpl_var value>">
    </td>
    <td bgcolor="white"><tmpl_var label></td>
    </tmpl_loop>
    </table>

Then, we would twiddle our C<mailopt> field via C<field()>:

    $form->field(
              name => 'mailopt',
              options => [
                 [ 1 => 'Yes, please keep me on it!' ],
                 [ 0 => 'No, remove me immediately.' ]
              ]
           );

When the template is rendered, the result would be something like this:

    Do you want to be on our mailing list?
    <p><table>

    <td bgcolor="silver">
      <input type="radio" name="mailopt" value="1">
    </td>
    <td bgcolor="white">Yes, please keep me on it!</td>

    <td bgcolor="silver">
      <input type="radio" name="mailopt" value="0">
    </td>
    <td bgcolor="white">No, remove me immediately</td>

    </table>

When the form was then sumbmitted, you would access the values just
like any other field:

    if ($form->field('mailopt')) {
        # is 1, so add them
    } else {
        # is 0, remove them
    }

Finally, you can also loop through each of the fields using the top-level
C<fields> loop in your template. This allows you to reuse the
same template even if your parameters change. The following template
code would loop through each field, creating a table row for each:

    <table>
    <tmpl_loop fields>
    <tr>
    <td class="small"><tmpl_var label></td>
    <td><tmpl_var field></td>
    </tr>
    </tmpl_loop>
    </table>

Each loop will have a C<label>, C<field>, C<value>, etc, just like above.

For more information on templates, see L<HTML::Template>.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<HTML::Template>

=head1 REVISION

$Id: HTML.pm,v 1.32 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2000-2006 Nathan Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
