
# Copyright (c) 2005 Nathan Wiger <nate@wiger.org>, Thilo Planz <thilo@cpan.org>.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::locale;

=head1 NAME

CGI::FormBuilder::Messages::de_DE - German messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'de');

=cut

use strict;
use utf8;

our $VERSION = '3.03';

# Simply create a hash of messages for this language
our %MESSAGES = (
    lang                  => 'de_DE',
    charset               => 'utf-8',

    js_invalid_start      => 'Ihre Angaben enthalten %s Fehler:',
    js_invalid_end        => 'Bitte korrigieren Sie diese Felder und versuchen Sie es erneut.',

    js_invalid_input      => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',
    js_invalid_select     => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_multiple   => '- Sie müssen mindestens eine der Optionen für "%s" auswählen',
    js_invalid_checkbox   => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_radio      => '- Sie müssen eine Auswahl für "%s" vornehmen',
    js_invalid_password   => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',
    js_invalid_textarea   => '- Sie müssen das Feld "%s" ausfüllen',
    js_invalid_file       => '- Sie müssen einen Dateinamen für das Feld "%s" angeben',
    js_invalid_default    => '- Sie müssen einen gültigen Wert für das Feld "%s" angeben',

    js_noscript           => 'Bitte aktivieren Sie JavaScript '
                           . 'oder benutzen Sie einen neueren Webbrowser.',

    form_required_text    => 'Sie müssen Angaben für die %shervorgehobenen%s Felder machen.',

    form_invalid_text     => 'Ihre Angaben enthalten %s Fehler. '
                           . 'Bitte korrigieren Sie %sdiese%s Felder und versuchen Sie es erneut.',

    form_invalid_input    => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_hidden   => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_select   => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_checkbox => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_radio    => 'Sie müssen eine Auswahl vornehmen',
    form_invalid_password => 'Sie müssen einen gültigen Wert angeben',
    form_invalid_textarea => 'Sie müssen dieses Feld ausfüllen',
    form_invalid_file     => 'Sie müssen einen Dateinamen angeben',
    form_invalid_default  => 'Sie müssen einen gültigen Wert angeben',

    form_grow_default     => 'Weitere %s',
    form_select_default   => '-Auswahl-',
    form_other_default    => 'Andere:',
    form_submit_default   => 'Senden',
    form_reset_default    => 'Zurücksetzen',
    
    form_confirm_text     => 'Vielen Dank für Ihre Angaben %s.',

    mail_confirm_subject  => '%s Eingangsbestätigung',
    mail_confirm_text     => <<EOT,
Ihre Angaben sind bei uns %s eingegangen ,
und werden in Kürze bearbeitet.

Falls Sie Fragen haben, kontaktieren Sie uns bitte, indem Sie
auf diese Email antworten.
EOT
    mail_results_subject  => '%s Eingang',
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

=head1 DESCRIPTION

This module contains German messages for FormBuilder.

If the C<messages> option is set to C<auto> (the recommended but NOT default
setting), these messages will automatically be displayed to German clients:

    my $form = CGI::FormBuilder->new(messages => 'auto');

To force display of these messages, use the following option:

    my $form = CGI::FormBuilder->new(messages => ':de_DE');

Thanks to Thilo Planz for the German translation.

=head1 REVISION

$Id: de_DE.pm,v 1.12 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nathan Wiger <nate@wiger.org>, Thilo Planz <thilo@cpan.org>.
All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
