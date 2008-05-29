
# Copyright (c) 2005 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::__LANG__;

=head1 NAME

CGI::FormBuilder::Messages::__LANG__ - __LANG__ messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'auto');

=cut

use strict;
use utf8;

our $VERSION = '3.03';

# First, create a hash of messages for this language
# Then, change "__LANG__" to the POSIX locale, such as "en_US" or "da_DK"
our %MESSAGES = (
    lang                  => '__LANG__',
    charset               => 'utf-8',

    js_invalid_start      => '%s error(s) were encountered with your submission:',
    js_invalid_end        => 'Please correct these fields and try again.',

    js_invalid_input      => '- Invalid entry for the "%s" field',
    js_invalid_select     => '- Select an option from the "%s" list',
    js_invalid_multiple   => '- Select one or more options from the "%s" list',
    js_invalid_checkbox   => '- Check one or more of the "%s" options',
    js_invalid_radio      => '- Choose one of the "%s" options',
    js_invalid_password   => '- Invalid entry for the "%s" field',
    js_invalid_textarea   => '- Please fill in the "%s" field',
    js_invalid_file       => '- Invalid filename for the "%s" field',
    js_invalid_default    => '- Invalid entry for the "%s" field',

    js_noscript           => 'Please enable Javascript or use a newer browser.',

    form_required_text    => 'Fields that are %shighlighted%s are required.',

    form_invalid_text     => '%s error(s) were encountered with your submission. '
                           . 'Please correct the fields %shighlighted%s below.',

    form_invalid_input    => 'Invalid entry',
    form_invalid_hidden   => 'Invalid entry',
    form_invalid_select   => 'Select an option from this list',
    form_invalid_checkbox => 'Check one or more options',
    form_invalid_radio    => 'Choose an option',
    form_invalid_password => 'Invalid entry',
    form_invalid_textarea => 'Please fill this in',
    form_invalid_file     => 'Invalid filename',
    form_invalid_default  => 'Invalid entry',

    form_grow_default     => 'Additional %s',
    form_select_default   => '-select-',
    form_other_default    => 'Other:',
    form_submit_default   => 'Submit',
    form_reset_default    => 'Reset',
    
    form_confirm_text     => 'Success! Your submission has been received %s.',

    mail_confirm_subject  => '%s Submission Confirmation',
    mail_confirm_text     => <<EOT,
Your submission has been received %s,
and will be processed shortly.

If you have any questions, please contact our staff by replying
to this email.
EOT
    mail_results_subject  => '%s Submission Results',
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

=head1 DESCRIPTION

This is a stub module which can be used to create localized messages.
To do so, first open up the file and edit the %MESSAGES hash so that it
contains the proper translations for your locale.

Once it is finished, save the file as:

    CGI/FormBuilder/Messages/locale.pm

Where locale is the appropriate POSIX locale name, such as "en_US" or "da_DK".

If you want to use the same file to serve multiple locales, simple create
links pointing to this module for each locale name.

Finally, join the mailing list and submit your translated module:

    fbusers-subscribe@formbuilder.org

That way, it can be included in future versions of FormBuilder!

=head1 VERSION

$Id: _example.pm,v 1.20 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
