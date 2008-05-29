
# Copyright (c) 2005 Nathan Wiger <nate@wiger.org>. All Rights Reserved.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::locale;

=head1 NAME

CGI::FormBuilder::Messages::fr_FR - French messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'fr');

=cut

use strict;
use utf8;

our $VERSION = '3.03';

# Simply create a hash of messages for this language
our %MESSAGES = (
    lang                  => 'fr_FR',
    charset               => 'utf-8',

    js_invalid_start      => '%s erreur(s) rencontrée(s) dans votre formulaire:',
    js_invalid_end        => 'Veuillez corriger ces champs et recommencer.',

    js_invalid_input      => '- Valeur incorrecte dans le champ "%s"',
    js_invalid_select     => '- Choisissez une option dans la liste "%s"',
    js_invalid_multiple   => '- Choisissez une ou plusieurs options dans la liste "%s"',
    js_invalid_checkbox   => '- Cochez une ou plusieurs des options "%s"',
    js_invalid_radio      => '- Choisissez l\'une des options "%s" ',
    js_invalid_password   => '- Valeur incorrecte dans le champ "%s"',
    js_invalid_textarea   => '- Veuillez remplir le champ "%s"',
    js_invalid_file       => '- Nom de fichier incorrect dans le champ "%s"',
    js_invalid_default    => '- Valeur incorrecte dans le champ "%s"',

    js_noscript           => 'Veuillez activer JavaScript ou '
                           . 'utiliser un navigateur plus récent.',

    form_required_text    => 'Les champs %ssoulignés%s sont obligatoires.',

    form_invalid_text     => '%s erreur(s) rencontrée(s) dans votre formulaire. '
                           . 'Veuillez corriger les champs %ssoulignés%s '
                           . 'ci-dessous.',

    form_invalid_input    => 'Valeur incorrecte',
    form_invalid_hidden   => 'Valeur incorrecte',
    form_invalid_select   => 'Choisissez l\'une des option de cette liste',
    form_invalid_checkbox => 'Cochez une ou plusieurs options',
    form_invalid_radio    => 'Choisissez une option',
    form_invalid_password => 'Valeur incorrecte',
    form_invalid_textarea => 'Veuillez saisir une valeur',
    form_invalid_file     => 'Nom de fichier incorrect',
    form_invalid_default  => 'Valeur incorrecte',

    form_grow_default     => '%s supplémentaire',
    form_select_default   => '-sélectionnez-',
    form_other_default    => 'Autres:',
    form_submit_default   => 'Envoyer',
    form_reset_default    => 'Formulaire vierge',

    form_confirm_text     => 'Réussi! Votre formulaire %s a été reçu.',

    mail_confirm_subject  => 'Confirmation du formulaire %s',
    mail_confirm_text     => <<EOT,
Votre formulaire %s a été bien reçu, et sera traité sous peu. 

Pour toute question, veuillez contacter nos services 
en répondant à cet email.'
EOT
    mail_results_subject  => 'Résultats du formulaire %s',
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

=head1 DESCRIPTION

This module contains French messages for FormBuilder.

If the C<messages> option is set to "auto" (the recommended
but NOT default setting), these messages will automatically
be displayed to French clients: 

     my $form = CGI::FormBuilder->new(messages => 'auto');

To force display of these messages, use the following
option:

     my $form = CGI::FormBuilder->new(messages => ':fr_FR');

Thanks to Laurent Dami for the French translation.

=head1 REVISION

$Id: fr_FR.pm,v 1.8 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nathan Wiger <nate@wiger.org>,
Laurent Dami <dami@cpan.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

