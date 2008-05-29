
# Copyright (c) 2005 Nathan Wiger <nate@wiger.org>. All Rights Reserved.
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

our $VERSION = '3.03';

# First, create a hash of messages for this language

our %MESSAGES = (
    lang                  => 'es_ES',
    charset               => 'utf-8',

    js_invalid_start      => '%s error(es) fueron encontrados en su formulario:',
    js_invalid_end        => 'Por favor corrija en el/los espacio(s) e intente otra vez \n', 
    js_invalid_input      => 'Teclee un valor valido en el espacio: "%s"',
    js_invalid_select     => 'Escoja una opción de la lista: "%s"', 
    js_invalid_multiple   => '- Escoja una o más opciones de la lista: "%s"',
    js_invalid_checkbox   => '- Revise una o más de las opciones: "%s"',
    js_invalid_radio      => '- Escoja una de las opciones de la lista: "%s"',
    js_invalid_password   => '- Valor invalido en el espacio: "%s"',
    js_invalid_textarea   => '- Por favor, complete en el espacio: "%s"',
    js_invalid_file       => '- El nombre del documento es invalido en el espacio: "%s"',
    js_invalid_default    => 'Teclee un valor valido en el espacio: "%s"',

    js_noscript           => 'Por favor habilite/ Javascript en su sistema o use un navegador de edición reciente',

    form_required_text    => 'Los espacios %sresaltados%s son obligatorios ',
    form_invalid_text     => 'Se encontraron %s error(es) al momento de hacer su pedido. Por favor corrija los valores en los espacios %sresaltados%s e intente otra vez.',

    form_invalid_input    => 'Valor invalido',
    form_invalid_hidden   => 'Valor invalido',
    form_invalid_select   => 'Escoja una opción de la lista',
    form_invalid_checkbox => 'Escoja una ó más opciones ',
    form_invalid_radio    => 'Escoja una opción',
    form_invalid_password => 'Valor invalido',
    form_invalid_textarea => 'Por favor, complete en el espacio',
    form_invalid_file     => 'Nombre del documento invalido',
    form_invalid_default  => 'Valor invalido',

    form_grow_default     => 'Más %s',
    form_select_default   => '-Seleccione-',
    form_other_default    => 'Otro:',
    form_submit_default   => 'Enviar',
    form_reset_default    => 'Borrar',
    form_confirm_text     => '¡Lo logro! ¡El sistema recibió sus datos! %s.',

    mail_confirm_subject  => '%s Confirmación de su pedido.',
    mail_confirm_text     => '¡El sistema recibió sus datos! %s., Si usted tiene una pregunta, por favor responde a este correo electrónico.',
    mail_results_subject  => '%s La resulta de su pedido.'
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

=head1 VERSION

$Id: es_ES.pm,v 1.11 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nathan Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
