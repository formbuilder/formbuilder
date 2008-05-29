
# Copyright (c) 2005 Nate Wiger <nate@wiger.org>, Thilo Planz <thilo@cpan.org>.
# Use "perldoc CGI::FormBuilder::Messages" to read full documentation.

package CGI::FormBuilder::Messages::locale;

=head1 NAME

CGI::FormBuilder::Messages::ja_JP - Japanese messages for FormBuilder

=head1 SYNOPSIS

    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(messages => 'auto');

=cut

use strict;
use utf8;

our $VERSION = '3.0302';

# Simply create a hash of messages for this language
our %MESSAGES = (
    lang                  => 'ja_JP',
    charset               => 'utf-8',

	js_invalid_start      => '%s個の入力エラーがあります。',
    js_invalid_end        => 'もう一度確認して正しい内容を入力して下さい。',

    js_invalid_input      => '%sに正しい値を入力して下さい。',
    js_invalid_select     => '%sが選択されていません。',
    js_invalid_multiple   => '%sからひとつ以上を選択して下さい。',
    js_invalid_checkbox   => '%sがチェックされていません。',
    js_invalid_radio      => '%sが選択されていません。',
    js_invalid_password   => '%sに正しい値を入力して下さい。',
    js_invalid_textarea   => '%sは必須入力です。',
    js_invalid_file       => '%sは指定されたファイルを選択して下さい。',
    js_invalid_default    => '%sに正しい値を入力して下さい。',

    js_noscript           => 'JavaScriptを有効にして下さい。'
    						. 'またはJavaScript対応の最新のブラウザを使用して下さい。',
    form_required_text    => '%s太字%sの項目は必須項目です。',

    form_invalid_text     => 'あなたの入力した項目のうち、%s個のエラーがあります。'
    						. '項目の下にある%sエラーメッセージ%sに従い正しい値を入力して下さい。',

    form_invalid_input    => '正しい値を入力して下さい。',
    form_invalid_hidden   => '正しい値を入力して下さい。',
    form_invalid_select   => '一覧から選択して下さい。',
    form_invalid_checkbox => 'チェックボックスの中から選択して下さい。',
    form_invalid_radio    => 'ラジオボタンの中から選択して下さい。',
    form_invalid_password => '正しい値を入力して下さい。',
    form_invalid_textarea => '必須入力です。',
    form_invalid_file     => '正しいファイルを選択して下さい。',
    form_invalid_default  => '正しい値を入力して下さい。',

	form_grow_default     => '%sを追加する',
	form_other_default    => 'その他',
    form_select_default   => '選択して下さい',
    form_submit_default   => '送信',
    form_reset_default    => 'リセット',
    
    form_confirm_text     => '%sの入力内容を受け付けました。ありがとうございます。',

    mail_confirm_subject  => '%sの入力確認',
    mail_confirm_text     => <<EOT,
フォームの送信を受け付けました [%s]。

質問等ございます方は、このメールをそのまま返信して下さい。
EOT
    mail_results_subject  => '%sの送信内容',
);

# This method should remain unchanged
sub messages {
    return wantarray ? %MESSAGES : \%MESSAGES;
}

1;
__END__

=head1 DESCRIPTION

This module contains Japanese messages for FormBuilder.

If the C<messages> option is set to C<auto> (the recommended but NOT default
setting), these messages will automatically be displayed to Japanese clients:

    my $form = CGI::FormBuilder->new(messages => 'auto');

To force display of these messages, use the following option:

    my $form = CGI::FormBuilder->new(messages => ':ja_JP');

Thanks to Toru Yamaguchi and Thilo Planz for the Japanese translation.


=head1 REVISION

$Id: ja_JP.pm,v 1.12 2006/02/24 01:42:29 nwiger Exp $

=head1 AUTHOR

Copyright (c) 2005-2006 Nate Wiger <nate@wiger.org>, Thilo Planz <thilo@cpan.org>.
All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.


