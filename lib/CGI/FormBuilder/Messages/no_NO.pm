
# Copyright (c) 2005 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::locale;

=head1 NAME

CGI::FormBuilder::Messages::no_NO - Norwegian messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'auto');

=cut

use strict;
use utf8;

our $VERSION = '3.0302';

# First, create a hash of messages for this language
our %MESSAGES = (
    lang                  => 'no_NO',
    charset               => 'utf-8',

    js_invalid_start      => '%s feil ble funnet i skjemaet:',
    js_invalid_end        => 'Vær vennlig å rette opp disse feltene og prøv igjen.',

    js_invalid_input      => '- Ulovlig innhold i "%s" feltet',
    js_invalid_select     => '- Gjør ett valg fra "%s" listen',
    js_invalid_multiple   => '- Gjør ett eller flere valg fra "%s" listen',
    js_invalid_checkbox   => '- Avmerk ett eller fler av "%s" valgene',
    js_invalid_radio      => '- Velg ett av "%s" valgene',
    js_invalid_password   => '- Ulovlig verdi i "%s" feltet',
    js_invalid_textarea   => '- Vennligst skriv noe i "%s" feltet',
    js_invalid_file       => '- Ulovlig filnavn i "%s" feltet',
    js_invalid_default    => '- Ulovlig innhold i "%s" feltet',

    js_noscript           => 'Vennligst tillat bruk av Javascript eller bruk en nyere webleser.',

    form_required_text    => 'Felt som er %smarkert%s er påkrevet.',

    form_invalid_text     => '%s feil ble funnet i skjemaet. '
                           . 'Vennligst rett opp feil i felter som er %smarkert%s under.',

    form_invalid_input    => 'Ulovlig innhold',
    form_invalid_hidden   => 'Ulovlig innhold',
    form_invalid_select   => 'Gjør ett valg fra listen',
    form_invalid_checkbox => 'Avmerk ett eller flere valg',
    form_invalid_radio    => 'Avmerk ett valg',
    form_invalid_password => 'Ulovlig verdi',
    form_invalid_textarea => 'Dette feltet må være utfylt',
    form_invalid_file     => 'Ulovlig filnavn',
    form_invalid_default  => 'Ulovlig innhold',

    form_grow_default     => 'Tillegg %s',
    form_select_default   => '-velg-',
    form_other_default    => 'Andre:',
    form_submit_default   => 'Send',
    form_reset_default    => 'Tømm',

    form_confirm_text     => 'Vellykket! Ditt skjema er mottatt %s.',

    mail_results_subject  => '%s Sendingsresultat',
    mail_confirm_subject  => '%s Sendingsbekreftelse',
    mail_confirm_text     => <<EOT,
Ditt skjema er mottatt %s,
og vil bli behandlet så snart som mulig..

Om du har spørsmål, ta kontakt med oss ved å svare på denne e-post.
EOT
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;

=head1 DESCRIPTION

This module contains Norwegian messages for FormBuilder.

If the C<messages> option is set to C<auto> (the recommended
but NOT default setting), these messages will automatically
be displayed to Norwegian clients:

    my $form = CGI::FormBuilder->new(messages => 'auto');

To force display of these messages, use the following option:

    my $form = CGI::FormBuilder->new(messages => ':no_NO');

Thanks to Steinar Fremme for the Norwegian translation.

=head1 VERSION

$Id: no_NO.pm,v 1.16 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>, Steinar Fremme
<steinar@fremme.no>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

