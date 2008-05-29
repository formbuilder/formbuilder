
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Messages::locale;

use strict;
use utf8;

use CGI::FormBuilder::Util;

our $REVISION = do { (my $r='$Revision: 100 $') =~ s/\D+//g; $r };
our $VERSION = '3.0501';

# First, create a hash of messages for this language
# Then, change "locale" to the 2-letter country code, such as "en" or "de"
our %MESSAGES = (
    lang                  => 'da_DK',
    charset               => 'utf-8',

    js_invalid_start      => '%s fejl fundet i din indsendelse:',
    js_invalid_end        => 'Ret venligst disse felter og prøv igen.',

    js_invalid_input      => '- Forkert indhold i feltet "%s"',
    js_invalid_select     => '- Vælg en mulighed fra listen "%s"',
    js_invalid_multiple   => '- Vælg een eller flere muligheder fra listen "%s"',
    js_invalid_checkbox   => '- Markér een eller flere af "%s"\'s muligheder',
    js_invalid_radio      => '- Vælg een af "%s"\'s muligheder',
    js_invalid_password   => '- Forkert indhold i feltet "%s"',
    js_invalid_textarea   => '- Udfyld venligst feltet "%s"',
    js_invalid_file       => '- Forkert filnavn angivet for "%s"',
    js_invalid_default    => '- Forkert indhold i feltet "%s"',

    js_noscript           => 'Aktivér venligst JavaScript eller brug en nyere web-browser.',

    form_required_text    => 'Krævede felter er %sfremhævet%s.',

    form_invalid_text     => '%s fejl blev fundet i dine oplysninger. Ret venligst felterne %sfremhævet%s nedenfor.',

    form_invalid_input    => 'Forkert indhold',
    form_invalid_hidden   => 'Forkert indhold',
    form_invalid_select   => 'Vælg en mulighed fra listen',
    form_invalid_checkbox => 'Markér een eller flere muligheder',
    form_invalid_radio    => 'Vælg en mulighed',
    form_invalid_password => 'Forkert indhold',
    form_invalid_textarea => 'Udfyld venligst denne',
    form_invalid_file     => 'Forkert filnavn',
    form_invalid_default  => 'Forkert indhold',

    form_grow_default     => 'Yderligere %s',
    form_select_default   => '-vælg-',
    form_other_default    => 'Andet:',
    form_submit_default   => 'Indsend',
    form_reset_default    => 'Nulstil',
    
    form_confirm_text     =>  'Tillykke! Dine oplysninger er modtaget %s.',

    mail_confirm_subject  => '%s indsendelsesbekræftelse',
    mail_confirm_text     => <<EOT,
Dine oplysninger er modtaget %s
og vil blive ekspederet hurtigst muligt.

Hvis du har spørgsmål, så kontakt venligst vore medarbejdere
ved at besvare denne email.
EOT
    mail_results_subject  => '%s indsendelsesresultat',
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

