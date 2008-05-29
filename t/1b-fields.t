#!/usr/bin/perl -Ilib -I../lib

# Copyright (c) 2000-2006 Nathan Wiger <nate@wiger.org>.
# All Rights Reserved. If you're reading this, you're bored.
# 1b-fields.t - test Field generation/handling

use strict;
use vars qw($TESTING $DEBUG);
$TESTING = 1;
$DEBUG = $ENV{DEBUG} || 0;

use Test;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
my @pm;
BEGIN { 
    # try to load all the .pm's except templates from MANIFEST
    open(M, "<MANIFEST") || warn "Can't open MANIFEST ($!) - skipping imports";
    chomp(@pm = grep !/Template/, grep /\.pm$/, <M>);

    my $numtests = 25 + @pm;

    plan tests => $numtests;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}

my $n = 0;
for (@pm) {
    close(STDERR);
    eval "package blah$n; require '$_'; package main;";
    ok(!$@);
    $n++;
}

# Fake a submission request
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING}   = 'ticket=111&user=pete&replacement=TRUE&action=Unsubscribe&name=Pete+Peteson&email=pete%40peteson.com&extra=junk&_submitted=1&blank=&two=&two=&other_test=_other_other_test&_other_other_test=42&other_test_2=_other_other_test_2&_other_other_test_2=nope';

use CGI::FormBuilder 3.04;
use CGI::FormBuilder::Test;

# jump to a test if specified for debugging (goto eek!)
my $t = shift;
if ($t) {
    eval sprintf("goto T%2.2d", $t);
    die;
}

# Now manually try a whole bunch of things
#1
T01: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/]);
    if ($form->submitted) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#2
T02: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields   => [qw/user name email/],
                                     validate => { email => 'EMAIL' } );
    if ($form->submitted && $form->validate) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#3
T03: ok(do {
    # this should fail since we are saying our email should be a netmask
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     validate => { email => 'NETMASK' } );
    if ($form->submitted && $form->validate) {
        0;  # failure
    } else {
        1;
    }
}, 1);
exit if $t;

#4
T04: ok(do {
    # this should also fail since the submission key will be _submitted_magic,
    # and our query_string only has _submitted in it
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     name   => 'magic');
    if ($form->submitted) {
        0;  # failure
    } else {
        1;
    }
}, 1);
exit if $t;

#5
T05: ok(do {
    # CGI should override default values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email/],
                                     values => { user => 'jim' } );
    if ($form->submitted && $form->field('user') eq 'pete') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#6
T06: ok(do {
    # test a similar thing, by with mixed-case values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/user name email Addr/],
                                     values => { User => 'jim', ADDR => 'Hello' } );
    if ($form->submitted && $form->field('Addr') eq 'Hello') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#7
T07: ok(do {
    # test a similar thing, by with mixed-case values
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => { User => 'jim', ADDR => 'Hello' } );
    if ($form->submitted && ! $form->field('Addr') && $form->field('ADDR') eq 'Hello') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#8
T08: ok(do {
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => []);   # no fields!
    if ($form->submitted) {
        if ($form->field('name') || $form->field('extra')) {
            # if we get here, this means that the restrictive field
            # masking is not working, and all CGI params are available
            -1;
        } elsif ($form->cgi_param('name')) {
            1;
        } else {
            0;
        }
    } else {
            0;
    }
}, 1);
exit if $t;

#9
T09: ok(do {
    # test if required does what v1.97 thinks it should (should fail)
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => { user => 'nwiger', pass => '' },
                                     validate => { user => 'USER' },
                                     required => [qw/pass/]);
    if ($form->submitted && $form->validate) {
        0;
    } else {
        1;
    }
}, 1);
exit if $t;

#10
T10: ok(do {
    # YARC (yet another 'required' check)
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email phone/],
                    validate => {email => 'EMAIL', phone => 'PHONE'},
                    required => [qw/name email/],
               );
    if ($form->submitted && $form->validate) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#11
T11: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email action/],
                    validate => {email => 'EMAIL'},
                    required => [qw/name email/],
               );
    $form->field(name => 'action', options => [qw/Subscribe Unsubscribe/],
                 value => 'Subscribe');
    if ($form->submitted && $form->validate && $form->field('action') eq 'Unsubscribe') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#12
T12: ok(do {
    # see if our checkboxes work how we want them to
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name color/],
                    labels => {color => 'Favorite Color'},
                    validate => {email => 'EMAIL'},
                    required => [qw/name/],
                    sticky => 0, columns => 1,
                    action => 'TEST', title => 'TEST',
               );
    $form->field(name => 'color', options => [qw(red> green& blue")],
                 multiple => 1, cleanopts => 0);
    $form->field(name => 'name', options => [qw(lower UPPER)], nameopts => 1);

    # Just return the form rendering
    # This should really go in 00generate.t, but the framework is too tight
    $form->render;
}, outfile(12));
exit if $t;

#13
T13: ok(do {
    # check individual fields as static
    my $form = CGI::FormBuilder->new(debug => $DEBUG, 
                                    fields => [qw/name email color/],
                                    action => 'TEST',
                                    columns => 1);
    $form->field(name => 'name', static => 1);
    $form->field(name => 'email', type => 'static');

    # Just return the form rendering
    # This should really go in 00generate.t, but the framework is too tight
    $form->render;
}, outfile(13));
exit if $t;

#14
T14: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email blank notpresent/],
                    values => {blank => 'DEF', name => 'DEF'}
               );
    if (defined($form->field('blank'))
        && ! $form->field('blank') 
        && $form->field('name') eq 'Pete Peteson'
        && ! defined($form->field('notpresent'))
    ) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#15
T15: ok(do {
    # test of proper CGI precendence when manually setting values
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/name email blank/],
                    keepextras => 0,    # should still get value
                    action => 'TEST',
               );
    if (! $form->field('extra') && 
        $form->cgi_param('extra') eq 'junk') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#16
T16: ok(do{
    my $form = CGI::FormBuilder->new(debug  => $DEBUG, 
                                     fields => [qw/name color hid1 hid2/],
                                     action => 'TEST',
                                     columns => 1);
    $form->field(name => 'name', static => 1, type => 'text');
    $form->field(name => 'hid1', type => 'hidden', value => 'Val1a');
    $form->field(name => 'hid1', type => 'hidden', value => 'Val1b');   # should replace Val1a
    $form->field(name => 'hid2', type => 'hidden', value => 'Val2');
    $form->field(name => 'color', value => 'blew', options => [qw(read blew yell)]);
    $form->field(name => 'Tummy', value => [qw(lg xxl)], options => [qw(sm med lg xl xxl xxxl)]);

    # Just return the form rendering
    # This should really go in 00generate.t, but the framework is too tight
    $form->confirm;
}, outfile(16));
exit if $t;

#17
T17: ok(do{
    my $form = CGI::FormBuilder->new(debug => $DEBUG, fields => [qw/name color dress_size taco:punch/]);
    $form->field(name => 'blank', value => 175, force => 1);
    $form->field(name => 'user', value => 'bob');

    if ($form->field('blank') eq 175 && $form->field('user') eq 'pete') {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#18
T18: ok(do{
    my $form = CGI::FormBuilder->new(
                        debug => $DEBUG,
                        smartness  => 0,
                        javascript => 0,
                   );

    $form->field(name => 'blank', value => 'aoe', type => 'text'); 
    $form->field(name => 'extra', value => '24', type => 'hidden', override => 1);
    $form->field(name => 'two', value => 'one');

    my @v = $form->field('two');
    if ($form->submitted && $form->validate && defined($form->field('blank')) && ! $form->field('blank')
        && $form->field('extra') eq 24 && @v == 2) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#19
T19: ok(do{
    my $form = CGI::FormBuilder->new(debug => $DEBUG);
    $form->fields([qw/one two three/]);
    my @v;
    if (@v = $form->field('two') and @v == 2) {
        1;
    } else {
        0;
    }
}, 1);
exit if $t;

#20
T20: ok(do{
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/one two three/],
                    fieldtype => 'TextAREA',
               );
    $form->field(name => 'added_later', label => 'Yo');
    my $ok = 1;
    for ($form->fields) {
        $ok = 0 unless $_->render =~ /textarea/i;
    }
    $ok;
}, 1);
exit if $t;

#21
T21: ok(do{
    my $form = CGI::FormBuilder->new(
                    debug => $DEBUG,
                    fields => [qw/a b c/],
                    fieldattr => {type => 'TOMATO'},
                    values => {a => 'Ay', b => 'Bee', c => 'Sea'},
               );
    $form->values(a => 'a', b => 'b', c => 'c');
    my $ok = 1;
    for ($form->fields) {
        $ok = 0 unless $_->value eq $_;
    }
    $ok;
}, 1);
exit if $t;

#22
T22: ok(do{
    my $form = CGI::FormBuilder->new(
                    fields  => [qw/name user/],
                    required => 'ALL',
                    sticky  => 0,
               );
    my $ok = 1;
    my $name = $form->field('name');
    $ok = 0 unless $name eq 'Pete Peteson';
    my $user = $form->field('user');
    $ok = 0 unless $user eq 'pete';
    for ($form->fields) {
        $ok = 0 unless $_->tag eq qq(<input id="$_" name="$_" type="text" />);
    }
    $ok;
}, 1);
exit if $t;

#23 - other field values
T23: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(name => 'other_test', other => 1, type => 'select');
    $form->field(name => 'other_test_2', other => 0, value => 'nope');
    my $ok = 1;
    $ok = 0 unless $form->field('other_test') eq '42';
    $ok = 0 unless $form->field('other_test_2') eq '_other_other_test_2';
    $ok;
}, 1);
exit if $t;

#24 - inflate coderef
T24: ok(do{
    my $form = CGI::FormBuilder->new;
    $form->field(
        name    => 'inflate_test', 
        value   => '2003-04-05 06:07:08', 
        inflate => sub { return [ split /\D+/, shift ] },
    );
    my $ok = 1;
    my $val = $form->field('inflate_test');
    $ok = 0 unless ref $val eq 'ARRAY';
    my $i = 0;
    $ok = 0 if grep { ($val->[$i++] != $_) } 2003, 4, 5, 6, 7, 8;
    $ok;
}, 1);

#25 - don't tell anyone this works
T25: ok(do{
    my $form = CGI::FormBuilder->new;
    my $val  = $form->field(
        name    => 'forty-two', 
        value   => 42
    );
    $val == 42;
}, 1);

