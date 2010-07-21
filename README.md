# CGI::FormBuilder - Perl module for easily generating, validating, and processing forms

## Support

Please see [formbuilder.org](http://formbuilder.org) for online docs and tutorials.  In addition, there is a [google discussion group](http://groups.google.com/group/perl-formbuilder) for help and patches.

## Installation

Use CPAN to install, ie:

    cpan CGI::FormBuilder
    
FormBuilder does not have any prerequisites; however, if you want to use templating support, you need to install one of:

* HTML::Template
* Text::Template
* Template Toolkit
* CGI::FastTemplate

Whichever you prefer to use.

## Example

    use CGI::FormBuilder;

    # Assume we did a DBI query to get existing values
    my $dbval = $sth->fetchrow_hashref;

    # First create our form
    my $form = CGI::FormBuilder->new(
                    name     => 'acctinfo',
                    method   => 'post',
                    stylesheet => '/path/to/style.css',
                    values   => $dbval,   # defaults
               );

    # Now create form fields, in order
    # FormBuilder will automatically determine the type for you
    $form->field(name => 'fname', label => 'First Name');
    $form->field(name => 'lname', label => 'Last Name');

    # Setup gender field to have options
    $form->field(name => 'gender',
                 options => [qw(Male Female)] );

    # Include validation for the email field
    $form->field(name => 'email',
                 size => 60,
                 validate => 'EMAIL',
                 required => 1);

    # And the (optional) phone field
    $form->field(name => 'phone',
                 size => 10,
                 validate => '/^1?-?\d{3}-?\d{3}-?\d{4}$/',
                 comment  => '<i>optional</i>');

    # Check to see if we're submitted and valid
    if ($form->submitted && $form->validate) {
        # Get form fields as hashref
        my $field = $form->fields;

        # Do something to update your data (you would write this)
        do_data_update($field->{lname}, $field->{fname},
                       $field->{email}, $field->{phone},
                       $field->{gender});

        # Show confirmation screen
        print $form->confirm(header => 1);
    } else {
        # Print out the form
        print $form->render(header => 1);
    }

## Bug Reports

Please use [github.com issues](http://github.com/formbuilder/formbuilder/issues) for any FormBuilder bugs or features.

## Author

Copyright (c) 2000-2010 [Nate Wiger](http://nateware.com). All Rights Reserved.

This module is free software; you may copy this under the terms of the GNU General Public License, or the Artistic License, copies of which should have accompanied your Perl kit.

FormBuilder is maintained by a team of several, including Danny Liang, Wolfgang Radke, and Derek Wueppelmann.  Your best bet for patches/support/etc is the [google group](http://groups.google.com/group/perl-formbuilder)


