
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::locale;

use strict;

our $REVISION = do { (my $r='$Revision: 100 $') =~ s/\D+//g; $r };
our $VERSION = '3.0501';

# Simply create a hash of messages for this language
our %MESSAGES = (
    lang                  => 'en_US',
    charset               => 'iso-8859-1',

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

