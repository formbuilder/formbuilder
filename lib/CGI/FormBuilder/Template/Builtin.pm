
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::Builtin;

=head1 NAME

CGI::FormBuilder::Template::Builtin - Builtin HTML rendering

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new;
    $form->render;

=cut

use Carp;
use strict;

use CGI::FormBuilder::Util;

our $REVISION = do { (my $r='$Revision: 66 $') =~ s/\D+//g; $r };
our $VERSION = '3.0401';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_;
    return bless \%opt, $class;
}

sub prepare {
    my $self = shift;
    my $form = shift;

    my @html = ();  # joined with newline

    # Opening CGI/title gunk 
    my $hd = $form->header;
    if (defined $hd) {
        push @html, ($hd . $form->dtd), htmltag('head');
        push @html, (htmltag('title').$form->title.htmltag('/title')) if $form->title;

        # stylesheet path if specified
        if ($form->{stylesheet} && $form->{stylesheet} ne 1) {
            # user-specified path
            push @html, htmltag('link', { rel  => 'stylesheet',
                                          type => 'text/css',
                                          href => $form->{stylesheet} });
        }
    }

    # JavaScript validate/head functions
    my $js = $form->script;
    push @html, $js if $js;

    # Opening HTML if so requested
    my $font = $form->font;
    my $fcls = $font ? htmltag('/font') : '';
    if (defined $hd) {
        push @html, htmltag('/head'), $form->body;
        push @html, $font if $font;
        push @html, (htmltag('h3').$form->title.htmltag('/h3')) if $form->title;
    }

    # Include warning if noscript
    push @html, $form->noscript if $js;

    # Begin form
    my $txt = $form->text;
    push @html, $txt if $txt;
    push @html, $form->start, '<div>', ($form->statetags . $form->keepextras);

    # Render hidden fields first
    my @unhidden;
    for my $field ($form->field) {
        push(@unhidden, $field), next if $field->type ne 'hidden';
        push @html, $field->tag;   # no label/etc for hidden fields
    }

    # Get table stuff and reused calls
    my $table = $form->table;
    push @html, $table if $table;

    # Render regular fields in table
    for my $field (@unhidden) {
        debug 2, "render: attacking normal field '$field'";
        next if $field->static > 1 && ! $field->tag_value;  # skip missing static vals

        if ($table) {
            my($trid, $laid, $inid, $erid, $cmid, $cl);
            if ($form->{name}) {
                # add id's to all elements
                $trid = tovar("$form->{name}_$field$form->{rowname}");
                $laid = tovar("$form->{name}_$field$form->{labelname}");
                $inid = tovar("$form->{name}_$field$form->{fieldname}");
                $erid = tovar("$form->{name}_$field$form->{errorname}");
                $cmid = tovar("$form->{name}_$field$form->{commentname}");
            }
            push @html, $form->tr(id => $trid);

            $cl = $form->class($form->{labelname});
            my $row = '  ' . $form->td(id => $laid, class => $cl) . $font;
            if ($field->invalid) {
                $row .= $form->invalid_tag($field->label);
            } elsif ($field->required && ! $field->static) {
                $row .= $form->required_tag($field->label);
            } else {
                $row .= $field->label;
            }
            $row .= $fcls . htmltag('/td');
            push @html, $row;

            # tag plus optional errors and/or comments
            $row = '';
            if ($field->invalid) {
                $row .= ' ' . $field->message;
            }
            if ($field->comment) {
                $row .= ' ' . $field->comment unless $field->static;
            }
            $row = $field->tag . $row;
            $cl  = $form->class($form->{fieldname});
            push @html, ('  ' . $form->td(id => $inid, class => $cl) . $font 
                        . $row . $fcls . htmltag('/td'));
            push @html, htmltag('/tr');
        } else {
            # no table
            my $row = $font;
            if ($field->invalid) {
                $row .= $form->invalid_tag($field->label);
            } elsif ($field->required && ! $field->static) {
                $row .= $form->required_tag($field->label);
            } else {
                $row .= $field->label;
            }
            $row .= $fcls;
            push @html, $row;
            push @html, $field->tag;
            push @html, $field->message if $field->invalid;
            push @html, $field->comment if $field->comment;
            push @html, '<br />' if $form->linebreaks;
        }
    }

    # Throw buttons in a colspan
    my $buttons = $form->reset . $form->submit;
    if ($buttons) {
        my $row = '';
        if ($table) {
            my($trid, $inid);
            if ($form->{name}) {
                # add id's
                $trid = tovar("$form->{name}_submit$form->{rowname}");
                $inid = tovar("$form->{name}_submit$form->{fieldname}");
            }
            my $c = $form->class($form->{submitname});
            my %a = $c ? () : (align => 'center');
            $row .= $form->tr(id => $trid) . "\n  "
                  . $form->td(id => $inid, class => $c, colspan => 2, %a) . $font;
        }
        $row .= $buttons;
        if ($table) {
            $row .= htmltag('/font') if $font;
            $row .= htmltag('/td') . "\n" . htmltag('/tr') if $table;
        }
        push @html, $row;
    }

    # Properly nest closing tags
    push @html, htmltag('/table')  if $table;
    push @html, htmltag('/div'), htmltag('/form');   # $form->end
    push @html, htmltag('/font')   if $font && defined $hd;
    push @html, htmltag('/body'),htmltag('/html') if defined $hd;

    # Always return scalar since print() is a list function
    return $self->{output} = join("\n", @html) . "\n"
}

sub render {
    my $self = shift;
    return $self->{output};
}

1;
__END__

=head1 DESCRIPTION

This module provides default rendering for B<FormBuilder>. It is automatically
called by FormBuilder's C<render()> method if no external template is specified.
See the documentation in L<CGI::FormBuilder> for more details.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template::HTML>,
L<CGI::FormBuilder::Template::Text>, L<CGI::FormBuilder::Template::TT2>,
L<CGI::FormBuilder::Template::Fast>

=head1 REVISION

$Id: Builtin.pm 66 2006-09-07 18:14:17Z nwiger $

=head1 AUTHOR

Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

