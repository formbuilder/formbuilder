package CGI::FormBuilder::Template::CGI_SSI;

=head1 NAME

CGI::FormBuilder::Template::CGI::SSI - FormBuilder interface to CGI::SSI

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    template => {
                      type=>'CGI_SSI',
                      file=>'form.shtml'
                    }
               );

=cut

use Carp;
use strict;

our $VERSION = '1.0';

#use CGI::FormBuilder::Util;
use CGI::SSI;
use base 'CGI::SSI';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_;

    my %opt2 = %opt;
    delete $opt2{virtual};
    delete $opt2{file};
    delete $opt2{string};
    $opt{engine} = CGI::SSI->new(%opt2);

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

        # and the value tag - can only hold first value!
        $tmplvar{"value-$field"} = $value[0];

        # and the label tag for the field
        $tmplvar{"label-$field"} = $field->label;

        # and the comment tag
        $tmplvar{"comment-$field"} = $field->comment;

        # and any error
        $tmplvar{"error-$field"} = $field->error;

#         # create a <tmpl_loop> for multi-values/multi-opts
#         # we can't include the field, really, since this would involve
#         # too much effort knowing what type
#         my @tmpl_loop = ();
#         for my $opt ($field->options) {
#             # Since our data structure is a series of ['',''] things,
#             # we get the name from that. If not, then it's a list
#             # of regular old data that we _toname if nameopts => 1
#             my($o,$n) = optval $opt;
#             $n ||= $field->nameopts ? toname($o) : $o;
#             my($slct, $chk) = ismember($o, @value) ? ('selected', 'checked') : ('','');
#             debug 2, "<tmpl_loop loop-$field> = adding { label => $n, value => $o }";
#             push @tmpl_loop, {
#                 label => $n,
#                 value => $o,
#                 checked => $chk,
#                 selected => $slct,
#             };
#         }
#
#         # now assign our loop-field
#         $tmplvar{"loop-$field"} = \@tmpl_loop;
#
#         # finally, push onto a top-level loop named "fields"
#         push @{$tmplvar{fields}}, {
#             field   => $field->tag,
#             value   => $value[0],
#             values  => \@value,
#             options => [ $field->options ],
#             label   => $field->label,
#             comment => $field->comment,
#             error   => $field->error,
#             loop    => \@tmpl_loop
#         }
    }

    # loop thru each field we have and set the tmpl_param
    while(my($param, $tag) = each %tmplvar) {
        $self->{engine}->set($param => $tag);
    }

    SWITCH: {
      if($self->{virtual}) {
        return $form->header . $self->engine->include(virtual=>$self->{virtual});
      }
      if($self->{file}) {
        return $form->header . $self->engine->include(file=>$self->{file});
      }
      if($self->{string}) {
        return $form->header . $self->engine->process($self->{string});
      }
    }
}

1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<CGI::SSI>.

You can specify any options which C<< CGI::SSI->new >>
accepts by using a hashref:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'CGI::SSI',
                        file => 'form.shtml',
                        sizefmt => 'abbrev'
                    }
                );

In addition to CGI::SSI B<new> arguments, you can also
specify C<file>, C<virtual>, or C<string> argument.

In your template, each of the form fields will correspond directly to
a C<< <!--#echo var="..." --> >> of the same name prefixed with "field-" in the
template. So, if you defined a field called "email", then you would
setup a variable called C<< <!--#echo var="field-email" --> >> in your template.

In addition, there are a couple special fields:

    <!--#echo var="js-head" -->     -  JavaScript to stick in <head>
    <!--#echo var="form-title" -->  -  The <title> of the HTML form
    <!--#echo var="form-start" -->  -  Opening <form> tag and internal fields
    <!--#echo var="form-submit" --> -  The submit button(s)
    <!--#echo var="form-reset" -->  -  The reset button
    <!--#echo var="form-end" -->    -  Just the closing </form> tag

However, you may want even more control. That is, maybe you want
to specify every nitty-gritty detail of your input fields, and
just want this module to take care of the statefulness of the
values. This is no problem, since this module also provides
several other C<< <!--#echo var="..." --> >> tags as well:

    <!--#echo var="value-[field]" -->   - The value of a given field
    <!--#echo var="label-[field]" -->   - The human-readable label
    <!--#echo var="comment-[field]" --> - Any optional comment
    <!--#echo var="error-[field]" -->   - Error text if validation fails

Loops are unsupported in current version of this package.

For more information on templates, see L<HTML::Template>.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<HTML::Template>

=head1 REVISION

$Id: HTML.pm,v 1.32 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2008 Victor Porton <porton@narod.ru>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
