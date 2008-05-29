
# Copyright (c) 2005 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::locale;

=head1 NAME

CGI::FormBuilder::Messages::es_ES - es_ES messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'auto');

=cut

use strict;
use utf8;

our $VERSION = '3.0302';

# First, create a hash of messages for this language

our %MESSAGES = (
    lang                  => 'es_ES',
    charset               => 'utf-8',

    js_invalid_start      => '%s error(es) fueron encontrados en su formulario:',
    js_invalid_end        => 'Por favor corrija en el/los campo(s) e intente de nuevo\n', 
    js_invalid_input      => 'Introduzca un valor válido para el campo: "%s"',
    js_invalid_select     => 'Escoja una opción de la lista: "%s"', 
    js_invalid_multiple   => '- Escoja una o más opciones de la lista: "%s"',
    js_invalid_checkbox   => '- Revise una o más de las opciones: "%s"',
    js_invalid_radio      => '- Escoja una de las opciones de la lista: "%s"',
    js_invalid_password   => '- Valor incorrecto para el campo: "%s"',
    js_invalid_textarea   => '- Por favor, rellene el campo: "%s"',
    js_invalid_file       => '- El nombre del documento es inválido para el campo: "%s"',
    js_invalid_default    => 'Introduzca un valor válido para el campo: "%s"',

    js_noscript           => 'Por favor habilite Javascript en su navegador o use una versión más reciente',

    form_required_text    => 'Los campos %sresaltados%s son obligatorios',
    form_invalid_text     => 'Se encontraron %s error(es) al realizar su pedido. Por favor corrija los valores en los campos %sresaltados%s y vuelva a intentarlo.',

    form_invalid_input    => 'Valor inválido',
    form_invalid_hidden   => 'Valor inválido',
    form_invalid_select   => 'Escoja una opción de la lista',
    form_invalid_checkbox => 'Escoja una o más opciones',
    form_invalid_radio    => 'Escoja una opción',
    form_invalid_password => 'Valor incorrecto',
    form_invalid_textarea => 'Por favor, rellene el campo',
    form_invalid_file     => 'Nombre del documento inválido',
    form_invalid_default  => 'Valor inválido',

    form_grow_default     => 'Más %s',
    form_select_default   => '-Seleccione-',
    form_other_default    => 'Otro:',
    form_submit_default   => 'Enviar',
    form_reset_default    => 'Borrar',
    form_confirm_text     => '¡Lo logró! ¡El sistema ha recibido sus datos! %s.',

    mail_confirm_subject  => '%s Confirmación de su pedido.',
    mail_confirm_text     => '¡El sistema ha recibido sus datos! %s., Si desea hacer alguna pregunta, por favor responda a éste correo electrónico.',
    mail_results_subject  => '%s Resultado de su pedido.'
    );

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

=head1 DESCRIPTION

This module contains Spanish messages for FormBuilder.

If the C<messages> option is set to "auto" (the recommended
but NOT default setting), these messages will automatically
be displayed to Spanish clients:

     my $form = CGI::FormBuilder->new(messages => 'auto');

To force display of these messages, use the following
option:

     my $form = CGI::FormBuilder->new(messages => ':es_ES');

Thanks to Florian Merges for the Spanish translation.

=head1 VERSION

$Id: es_ES.pm,v 1.11 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
