
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder;

=head1 NAME

CGI::FormBuilder - Easily generate and process stateful forms

=head1 SYNOPSIS

    use CGI::FormBuilder;

    # Assume we did a DBI query to get existing values
    my $dbval = $sth->fetchrow_hashref;

    # First create our form
    my $form = CGI::FormBuilder->new(
                    name     => 'acctinfo',
                    method   => 'post',
                    stylesheet => '/path/to/style.css',
                    values   => $dbval,   # defaults
               );

    # Now create form fields, in order
    # FormBuilder will automatically determine the type for you
    $form->field(name => 'fname', label => 'First Name');
    $form->field(name => 'lname', label => 'Last Name');

    # Setup gender field to have options
    $form->field(name => 'gender',
                 options => [qw(Male Female)] );

    # Include validation for the email field
    $form->field(name => 'email',
                 size => 60,
                 validate => 'EMAIL',
                 required => 1);

    # And the (optional) phone field
    $form->field(name => 'phone',
                 size => 10,
                 validate => '/^1?-?\d{3}-?\d{3}-?\d{4}$/',
                 comment  => '<i>optional</i>');

    # Check to see if we're submitted and valid
    if ($form->submitted && $form->validate) {
        # Get form fields as hashref
        my $field = $form->fields;

        # Do something to update your data (you would write this)
        do_data_update($field->{lname}, $field->{fname},
                       $field->{email}, $field->{phone},
                       $field->{gender});

        # Show confirmation screen
        print $form->confirm(header => 1);
    } else {
        # Print out the form
        print $form->render(header => 1);
    }

=cut

use Carp;
use strict;

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use CGI::FormBuilder::Messages;

our $VERSION = '3.0401';
our $REVISION = do { (my $r='$Revision: 66 $') =~ s/\D+//g; $r };
our $AUTOLOAD;

# Default options for FormBuilder
our %DEFAULT = (
    sticky     => 1,
    method     => 'get',
    submit     => 1,
    reset      => 0,
    header     => 0,
    body       => { },
    text       => '',
    table      => { },
    tr         => { },
    th         => { },
    td         => { },
    jsname     => 'validate',
    jsprefix   => 'fb_',              # prefix for JS tags
    sessionidname => '_sessionid',
    submittedname => '_submitted',
    pagename   => '_page',
    template   => '',                 # default template
    debug      => 0,                  # can be 1 or 2
    javascript => 'auto',             # 0, 1, or 'auto'
    cookies    => 1,
    cleanopts  => 1,
    render     => 'render',           # render sub name
    smartness  => 1,                  # can be 1 or 2
    selectname => 1,                  # include -select-?
    selectnum  => 5,
    stylesheet => 0,                  # use stylesheet stuff?
    styleclass => 'fb',               # style class to use
    # For translating tag names (experimental)
    tagnames   => { },
    # I don't see any reason why these are variables
    submitname => '_submit',
    resetname  => '_reset',
    rowname    => '_row',
    labelname  => '_label',
    fieldname  => '_field',           # equiv of <tmpl_var field-tag>
    buttonname => '_button',
    errorname  => '_error',
    othername  => '_other',
    growname   => '_grow',
    dtd        => <<'EOD',            # modified from CGI.pm
<?xml version="1.0" encoding="{charset}"?>
<!DOCTYPE html
        PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="{lang}" xml:lang="{lang}">
EOD
);

# Which options to rearrange from new() into field()
our %REARRANGE = qw(
    options     options
    optgroups   optgroups
    labels      label
    validate    validate
    required    required
    selectname  selectname
    selectnum   selectnum
    sortopts    sortopts
    nameopts    nameopts
    cleanopts   cleanopts
    sticky      sticky
    disabled    disabled
    columns     columns
);

*redo = \&new;
sub new {
    local $^W = 0;      # -w sucks
    my $self = shift;

    # A single arg is a source; others are opt => val pairs
    my %opt;
    if (@_ == 1) {
        %opt = UNIVERSAL::isa($_[0], 'HASH')
             ? %{ $_[0] }
             : ( source => shift() );
    } else {
        %opt = arghash(@_);
    }

    # Pre-check for an external source
    if (my $src = delete $opt{source}) {

        # check for engine type
        my $mod;
        my $sopt;     # opts returned from parsing
        my $ref = ref $src;
        unless ($ref) {
            # string filename; redo format (ala $self->{template})
            $src = {
                type   => 'File',
                source => $src
            };
            $ref = 'HASH';  # tricky
            debug 2, "rewrote 'source' option since found filename";
        }
        debug 1, "creating form from source ", $ref || $src;

        if ($ref eq 'HASH') {
            # grab module
            $mod = delete $src->{type} || 'File';

            # user can give 'Their::Complete::Module' or an 'IncludedTemplate'
            $mod = join '::', __PACKAGE__, 'Source', $mod unless $mod =~ /::/;
            debug 1, "loading $mod for 'source' option";

            eval "require $mod";
            puke "Bad source module $mod: $@" if $@;

            my $sob  = $mod->new(%$src);
            $sopt = $sob->parse;
        } elsif ($ref eq 'CODE') {
            # subroutine wrapper
            $sopt = &{$src->{source}}($self);
        } elsif (UNIVERSAL::can($src->{source}, 'parse')) {
            # instantiated object
            $sopt = $src->{source}->parse($self);
        } elsif ($ref) {
            puke "Unsupported operand to 'template' option - must be \\%hash, \\&sub, or \$object w/ parse()";
        }

        # per-instance variables win
        while (my($k,$v) = each %$sopt) {
            $opt{$k} = $v unless exists $opt{$k};
        }
    }

    if (ref $self) {
        # cloned/original object
        debug 1, "rewriting existing FormBuilder object";
        while (my($k,$v) = each %opt) {
            $self->{$k} = $v;
        }
    } else {
        debug 1, "constructing new FormBuilder object";
        # damn deep copy this is SO damn annoying
        while (my($k,$v) = each %DEFAULT) {
            next if exists $opt{$k};
            if (ref $v eq 'HASH') {
                $opt{$k} = { %$v };
            } elsif (ref $v eq 'ARRAY') {
                $opt{$k} = [ @$v ];
            } else {
                $opt{$k} = $v;
            }
        }
        $self = bless \%opt, $self;
    }

    # Create our CGI object if not present
    unless (ref $self->{params}) {
        require CGI;
        $CGI::USE_PARAM_SEMICOLONS = 0;     # fuck ; in urls
        $self->{params} = CGI->new($self->{params});
    }

    # XXX not mod_perl safe
    $CGI::FormBuilder::Util::DEBUG = $ENV{FORMBUILDER_DEBUG} || $self->{debug};

    # And a messages delegate if not existent
    # Handle 'auto' mode by trying to detect from request
    # Can't do this in ::Messages because it has no CGI knowledge
    if (lc($self->{messages}) eq 'auto') {
        my $lang = $self->{messages};
        # figure out the messages from our params object
        if (UNIVERSAL::isa($self->{params}, 'CGI')) {
            $lang = $self->{params}->http('Accept-Language');
        } elsif (UNIVERSAL::isa($self->{params}, 'Apache')) {
            $lang = $self->{params}->headers_in->get('Accept-Language'); 
        } elsif (UNIVERSAL::isa($self->{params}, 'Catalyst::Request')) {
            $lang = $self->{params}->headers->header('Accept-Language'); 
        } else {
            # last-ditch effort
            $lang = $ENV{HTTP_ACCEPT_LANGUAGE}
                 || $ENV{LC_MESSAGES} || $ENV{LC_ALL} || $ENV{LANG};
        }
        $lang ||= 'default';
        $self->{messages} = CGI::FormBuilder::Messages->new(":$lang");
    } else {
        # ref or filename (::Messages will decode)
        $self->{messages} = CGI::FormBuilder::Messages->new($self->{messages});
    }

    # Initialize form fields (probably a good idea)
    if ($self->{fields}) {
        debug 1, "creating fields list";

        # check to see if 'fields' is a hash or array ref
        my $ref = ref $self->{fields};
        if ($ref && $ref eq 'HASH') {
            # with a hash ref, we setup keys/values
            debug 2, "got fields list from HASH";
            while(my($k,$v) = each %{$self->{fields}}) {
                $k = lc $k;     # must lc to ignore case
                $self->{values}{$k} = [ autodata $v ];
            }
            # reset main fields to field names
            $self->{fields} = [ sort keys %{$self->{fields}} ];
        } else {
            # rewrite fields to ensure format
            debug 2, "assuming fields list from ARRAY";
            $self->{fields} = [ autodata $self->{fields} ];
        }
    }

    if (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        debug 2, "got a Data::FormValidator for validate";
        # we're being a bit naughty and peeking inside the DFV object
        $self->{required} = $self->{validate}{profiles}{fb}{required};
    } else {
        # Catch the intersection of required and validate
        if (ref $self->{required}) {
            # ok, will handle itself automatically below
        } elsif ($self->{required}) {
            # catches for required => 'ALL'|'NONE'
            if ($self->{required} eq 'NONE') {
                delete $self->{required};   # that's it
            }
            elsif ($self->{required} eq 'ALL') {
                $self->{required} = [ @{$self->{fields}} ];
            }
            elsif ($self->{required}) {
                # required => 'single_field' catch
                $self->{required} = { $self->{required} => 1 };
            }
        } elsif ($self->{validate}) {
            # construct a required list of all validated fields
            $self->{required} = [ keys %{$self->{validate}} ];
        }
    }

    # Now, new for the 3.x series, we cycle thru the fields list and
    # replace it with a list of objects, which stringify to field names
    my @ftmp  = ();
    for (@{$self->{fields}}) {
        my %fprop = %{$self->{fieldopts}{$_} || {}}; # field properties

        if (ref $_ =~ /^CGI::FormBuilder::Field/i) {
            # is an existing Field object, so update its properties
            $_->field(%fprop);
        } else {
            # init a new one
            $fprop{name} = "$_";
            $_ = $self->new_field(%fprop);
        }
        debug 2, "push \@(@ftmp), $_";
        $self->{fieldrefs}{"$_"} = $_;
        push @ftmp, $_;
    }

    # stringifiable objects (overwrite previous container)
    $self->{fields} = \@ftmp;

    # setup values
    $self->values($self->{values}) if $self->{values};

    debug 1, "field creation done, list = (@ftmp)";

    return $self;
}

*param  = \&field;
*params = \&field;
*fields = \&field;
sub field {
    local $^W = 0;      # -w sucks
    my $self = shift;
    debug 2, "called \$form->field(@_)";

    # Handle any of:
    #
    #   $form->field($name)
    #   $form->field(name => $name, arg => 'val')
    #   $form->field(\@newlist);
    #

    return $self->new(fields => $_[0])
        if ref $_[0] eq 'ARRAY' && @_ == 1;

    my $name = (@_ % 2 == 0) ? '' : shift();
    my $args = arghash(@_);
    $args->{name} ||= $name;

    # no name - return ala $cgi->param
    unless ($args->{name}) {
        # sub fields
        # return an array of the names in list context, and a
        # hashref of name/value pairs in a scalar context
        if (wantarray) {
            # pre-scan for any "order" arguments, reorder, delete
            for my $redo (grep { $_->order } @{$self->{fields}}) {
                next if $redo->order eq 'auto';   # like javascript
                # kill existing order
                for (my $i=0; $i < @{$self->{fields}}; $i++) {
                    if ($self->{fields}[$i] eq $redo) {
                        debug 2, "reorder: removed $redo from \$fields->[$i]";
                        splice(@{$self->{fields}}, $i, 1);
                    }
                }
                # put it in its new place
                debug 2, "reorder: moving $redo to $redo->{order}";
                if ($redo->order <= 1) {
                    # start
                    unshift @{$self->{fields}}, $redo;
                } elsif ($redo->order >= @{$self->{fields}}) {
                    # end
                    push @{$self->{fields}}, $redo;
                } else {
                    # middle
                    splice(@{$self->{fields}}, $redo->order - 1, 0, $redo);
                }
                # kill subsequent reorders (unnecessary)
                delete $redo->{order};
            }

            # list of all field objects
            debug 2, "return (@{$self->{fields}})";
            return @{$self->{fields}};
        } else {
            # this only returns a single scalar value for each field
            return { map { $_ => scalar($_->value) } @{$self->{fields}} };
        }
    }

    # have name, so redispatch to field member
    debug 2, "searching fields for '$args->{name}'";
    if ($args->{delete}) {
        # blow the thing away
        delete $self->{fieldrefs}{$args->{name}};
        my @tf = grep { $_->name ne $args->{name} } @{$self->{fields}};
        $self->{fields} = \@tf;
        return;
    } elsif (my $f = $self->{fieldrefs}{$args->{name}}) {
        delete $args->{name};        # segfault??
        return $f->field(%$args);    # set args, get value back
    }

    # non-existent field, and no args, so assume we're checking for it
    return unless keys %$args > 1;

    # if we're still in here, we need to init a new field
    # push it onto our mail fields array, just like initfields()
    my $f = $self->new_field(%$args);
    $self->{fieldrefs}{"$f"} = $f;
    push @{$self->{fields}}, $f;
    return $f->value;
}

sub new_field {
    my $self = shift;
    my $args = arghash(@_);
    puke "Need a name for \$form->new_field()" unless exists $args->{name};
    debug 1, "called \$form->new_field($args->{name})";

    # extract our per-field options from rearrange
    while (my($from,$to) = each %REARRANGE) {
        next unless exists  $self->{$from};
        next if     defined $args->{$to};     # manually set
        my $tval = rearrange($self->{$from}, $args->{name});
        debug 2, "rearrange: \$args->{$to} = $tval;";
        $args->{$to} = $tval;
    }

    $args->{type} = lc $self->{fieldtype}
        if $self->{fieldtype} && ! exists $args->{type};
    if ($self->{fieldattr}) {   # legacy
        while (my($k,$v) = each %{$self->{fieldattr}}) {
            next if exists $args->{$k};
            $args->{$k} = $v;
        }
    }

    my $f = CGI::FormBuilder::Field->new($self, $args);
    debug 1, "created field $f";
    return $f;   # already set args above ^^^
}

sub header {
    my $self = shift;
    $self->{header} = shift if @_;
    return unless $self->{header};
    my %head;
    if ($self->{cookies} && defined(my $sid = $self->sessionid)) {
        require CGI::Cookie;
        $head{'-cookie'} = CGI::Cookie->new(-name  => $self->{sessionidname},
                                            -value => $sid);
    }
    # Set the charset for i18n
    $head{'-charset'} = $self->charset;

    # Forcibly require - no extra time in normal case, and if 
    # using Apache::Request this needs to be loaded anyways.
    return '' if $::TESTING;
    require CGI;
    return  CGI::header(%head);    # CGI.pm MOD_PERL fanciness
}

sub charset {
    my $self = shift;
    $self->{charset} = shift if @_;
    return $self->{charset} || $self->{messages}->charset || 'iso8859-1';
}

sub lang {
    my $self = shift;
    $self->{lang} = shift if @_;
    return $self->{lang} || $self->{messages}->lang || 'en_US';
}

sub dtd {
    my $self = shift;
    $self->{dtd} = shift if @_;
    return '<html>' if $::TESTING;

    # replace special chars in dtd by exec'ing subs
    my $dtd = $self->{dtd};
    $dtd =~ s/\{(\w+)\}/$self->$1/ge;
    return $dtd;
}

sub title {
    my $self = shift;
    $self->{title} = shift if @_;
    return $self->{title} if exists $self->{title};
    return toname(basename);
}

*script_name = \&action;
sub action {
    local $^W = 0;  # -w sucks (still)
    my $self = shift;
    $self->{action} = shift if @_;
    return $self->{action} if exists $self->{action};
    return basename . $ENV{PATH_INFO};
}

sub font {
    my $self = shift;
    $self->{font} = shift if @_;
    return '' unless $self->{font};
    return '' if $self->{stylesheet};   # kill fonts for style

    # Catch for allowable hashref or string
    my $ret;
    my $ref = ref $self->{font} || '';
    if (! $ref) {
        # string "arial,helvetica"
        $ret = { face => $self->{font} };
    } elsif ($ref eq 'ARRAY') {
        # hack for array [arial,helvetica] from conf
        $ret = { face => join ',', @{$self->{font}} };
    } else {
        $ret = $self->{font};
    }
    return wantarray ? %$ret : htmltag('font', %$ret);
}

*tag = \&start;
sub start {
    my $self = shift;
    my %attr = htmlattr('form', %$self);

    $attr{action} ||= $self->action;
    $attr{method} ||= $self->method;
    $attr{method} = lc($attr{method});  # xhtml
    $self->disabled ? $attr{disabled} = 'disabled' : delete $attr{disabled};
    #$attr{class}  ||= $self->{styleclass} if $self->{stylesheet};

    # Bleech, there's no better way to do this...?
    belch "You should really call \$form->script BEFORE \$form->start"
        unless $self->{_didscript};

    # A catch for lowercase actions
    belch "Old-style 'onSubmit' action found - should be 'onsubmit'"
        if $attr{onSubmit};

    return $self->version . htmltag('form', %attr);
}

sub end {
    return '</form>';
}

# Need to wrap this or else AUTOLOAD whines (OURATTR missing)
sub disabled {
    my $self = shift;
    $self->{disabled} = shift if @_;
    return $self->{disabled} ? 'disabled' : undef;
}
 
sub body {
    my $self = shift;
    $self->{body} = shift if @_;
    $self->{body}{bgcolor} ||= 'white' unless $self->{stylesheet};
    return htmltag('body', $self->{body});
}

sub class {
    my $self = shift;
    return unless $self->{stylesheet};
    return join '', $self->{styleclass}, @_;   # remainder is optional tag 
}

sub table {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{table} = shift if @_ == 1;
    return unless $self->{table};

    # set defaults for numeric table => 1
    $self->{table} = $DEFAULT{table} if $self->{table} == 1;

    my $attr = $self->{table};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    return unless $self->{table};   # 0 or unset via table(0)
    $attr->{class} ||= $self->class;
    return htmltag('table',  $attr);
}

sub tr {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{tr} = shift if @_ == 1;

    my $attr = $self->{tr};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # reduced formatting
    if ($self->{stylesheet}) {
        # extraneous - inherits from <table>
        #$attr->{class}  ||= $self->class($self->{rowname});
    } else {
        $attr->{valign} ||= 'top';
    }

    return htmltag('tr',  $attr);
}

sub th {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{th} = shift if @_ == 1;

    my $attr = $self->{th};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # reduced formatting
    if ($self->{stylesheet}) {
        # extraneous - inherits from <table>
        #$attr->{class} ||= $self->class($self->{labelname});
    } else {
        $attr->{align} ||= $self->{lalign} || 'left';
    }

    return htmltag('th', $attr);
}

sub td {
    my $self = shift;

    # single hashref kills everything; a list is temporary
    $self->{td} = shift if @_ == 1;

    my $attr = $self->{td};
    if (@_) {
        # if still have args, create a temp hash
        my %temp = %$attr;
        while (my $k = shift) {
            $temp{$k} = shift;
        }
        $attr = \%temp;
    }

    # extraneous - inherits from <table>
    #$attr->{class} ||= $self->class($self->{fieldname});

    return htmltag('td', $attr);
}

sub submitted {
    my $self = shift;
    my $smnam = shift || $self->submittedname;  # temp smnam
    my $smtag = $self->{name} ? "${smnam}_$self->{name}" : $smnam;

    if ($self->{params}->param($smtag)) {
        # If we've been submitted, then we return the value of
        # the submit tag (which allows multiple submission buttons).
        # Must use an "|| 0E0" or else hitting "Enter" won't cause
        # $form->submitted to be true (as the button is only sent
        # across CGI when clicked).
        my $sr = $self->{params}->param($self->submitname) || '0E0';
        debug 2, "\$form->submitted() is true, returning $sr";
        return $sr;
    }
    return 0;
}

# This creates a modified self_url, just including fields (no sessionid, etc)
sub query_string {
    my $self = shift;
    my @qstr = ();
    for my $f ($self->fields, $self->keepextras) {
        # get all values, but ONLY from CGI
        push @qstr, join('=', escapeurl($f), escapeurl($_)) for $self->cgi_param($f);
    }
    return join '&', @qstr;
}

sub self_url {
    my $self = shift;
    return join '?', $self->action, $self->query_string;
}

# must forcibly return scalar undef for CGI::Session easiness
sub sessionid {
    my $self = shift;
    $self->{sessionid} = shift if @_;
    return $self->{sessionid} if $self->{sessionid};
    return undef unless $self->{sessionidname};
    my %cookies;
    if ($self->{cookies}) {
        require CGI::Cookie;
        %cookies = CGI::Cookie->fetch;
    }
    if (my $cook = $cookies{"$self->{sessionidname}"}) {
        return $cook->value;
    } else {
        return $self->{params}->param($self->{sessionidname}) || undef;
    }
}

sub statetags {
    my $self = shift;
    my @html = ();

    # get _submitted
    my $smnam = $self->submittedname;
    my $smtag = $self->{name} ? "${smnam}_$self->{name}" : $smnam;
    my $smval = $self->{params}->param($smnam) + 1;
    push @html, htmltag('input', name => $smtag, value => $smval, type => 'hidden');

    # and how about _sessionid
    if (defined(my $sid = $self->sessionid)) {
        push @html, htmltag('input', name => $self->{sessionidname},
                                     type => 'hidden', value => $sid);
    }

    # and what page (hooks for ::Multi)
    if (defined $self->{page}) {
        push @html, htmltag('input', name => $self->pagename,
                                     type => 'hidden', value => $self->{page});
    }

    return wantarray ? @html : join "\n", @html;
}

*keepextra = \&keepextras;
sub keepextras {
    local $^W = 0;      # -w sucks
    my $self  = shift;
    my @keep  = ();
    my @html  = ();

    # which ones do they want?
    $self->{keepextras} = shift if @_;
    return '' unless $self->{keepextras};

    # If we set keepextras, then this means that any extra fields that
    # we've set that are *not* in our fields() will be added to the form
    my $ref = ref $self->{keepextras} || '';
    if ($ref eq 'ARRAY') {
        @keep = @{$self->{keepextras}};
    } elsif ($ref) {
        puke "Unsupported data structure type '$ref' passed to 'keepextras' option";
    } else {
        # Set to "1", so must go thru all params, skipping 
        # leading underscore fields and form fields
        for my $p ($self->{params}->param) {
            next if $p =~ /^_/  || $self->{fieldrefs}{$p};
            push @keep, $p;
        }
    }

    # In array context, we just return names we've resolved
    return @keep if wantarray;

    # Make sure to get all values
    for my $p (@keep) {
        for my $v ($self->{params}->param($p)) {
            debug 1, "keepextras: saving hidden param $p = $v";
            push @html, htmltag('input', name => $p, type => 'hidden', value => $v);
        }
    }
    return join "\n", @html;    # wantarray above
}

sub javascript {
    my $self = shift;
    $self->{javascript} = shift if @_;

    # auto-determine javascript setting based on user agent
    if (lc($self->{javascript}) eq 'auto') {
        if (exists $ENV{HTTP_USER_AGENT}
                && $ENV{HTTP_USER_AGENT} =~ /lynx|mosaic/i)
        {
            # Turn off for old/non-graphical browsers
            return 0;
        }
        return 1;
    }
    return $self->{javascript} if exists $self->{javascript};

    # Turn on for all other browsers by default.
    # I suspect this process should be reversed, only
    # showing JavaScript on those browsers we know accept
    # it, but maintaining a full list will result in this
    # module going out of date and having to be updated.
    return 1;
}

sub jsname {
    my $self = shift;
    return $self->{name}
           ? (join '_', $self->{jsname}, tovar($self->{name}))
           : $self->{jsname};
}

sub script {
    my $self = shift;

    # get validate() function name
    my $jsname = $self->jsname   || puke "Must have 'jsname' if 'javascript' is on";
    my $jspre  = $self->jsprefix || '';

    # "counter"
    $self->{_didscript} = 1;
    return '' unless $self->javascript;

    # code for misc non-validate functions
    my $jsmisc = $self->script_growable     # code to grow growable fields, if any
               . $self->script_otherbox;    # code to enable/disable the "other" box

    # custom user jsfunc option for w/i validate()
    my $jsfunc = $self->jsfunc || '';
    my $jshead = $self->jshead || '';

    # expand per-field validation functions, but
    # only if we are not using Data::FormValidator
    unless (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        for ($self->field) {
            $jsfunc .= $_->script;
        }
    }
      
    # skip out if we have nothing useful
    return '' unless $jsfunc || $jsmisc || $jshead;

    # prefix with opening code
    if ($jsfunc) {
        $jsfunc = <<EOJ1 . $jsfunc;
function $jsname (form) {
    var alertstr = '';
    var invalid  = 0;

EOJ1

        # Finally, close our JavaScript if it was opened, wrapping in <script> tags
        # We do a regex trick to turn "%s" into "+invalid+"
        (my $alertstart = $self->{messages}->js_invalid_start) =~ s/%s/'+invalid+'/g;
        (my $alertend   = $self->{messages}->js_invalid_end)   =~ s/%s/'+invalid+'/g;

        $jsfunc .= <<EOJS;
    if (invalid > 0 || alertstr != '') {
        if (! invalid) invalid = 'The following';   // catch for programmer error
        alert('$alertstart'+'\\n\\n'
                +alertstr+'\\n'+'$alertend');
        // reset counters
        alertstr = '';
        invalid  = 0;
        return false;
    }
    return true;  // all checked ok
}
EOJS

        # Must set our onsubmit to call validate()
        # Unfortunately, this introduces the requirement that script()
        # must be generated/called before start() in our template engines.
        # Fortunately, that usually happens anyways. Still sucks.
        $self->{onsubmit} ||= "return $jsname(this);";
    }

    # set <script> now to the expanded javascript
    return '<script type="text/javascript">'
         . "<!-- hide from old browsers\n"
         . $jshead . $jsmisc . $jsfunc 
         . "//-->\n</script>";
}

sub script_growable {
    my $self = shift;
    return '' unless my @growable = grep { $_->growable } $self->field;

    my $jspre  = $self->jsprefix || '';
    my $jsmisc = '';

    my $grow = $self->growname;
    $jsmisc .= <<EOJS;
var ${jspre}counter = new Object;  // for assigning unique ids; keyed by field name
var ${jspre}limit   = new Object;  // for limiting the size of growable fields
function ${jspre}grow (baseID) {
    // inititalize the counter for this ID
    if (isNaN(${jspre}counter[baseID])) ${jspre}counter[baseID] = 1;

    // don't go past the growth limit for this field
    if (${jspre}counter[baseID] >= ${jspre}limit[baseID]) return;

    var base = document.getElementById(baseID + '_' + (${jspre}counter[baseID] - 1));

    // we are inserting after the last field
    insertPoint = base.nextSibling;

    // line break
    base.parentNode.insertBefore(document.createElement('br'), insertPoint);

    var dup = base.cloneNode(true);

    dup.setAttribute('id', baseID + '_' + ${jspre}counter[baseID]);
    base.parentNode.insertBefore(dup, insertPoint);

    // add some padding space between the field and the "add field" button
    base.parentNode.insertBefore(document.createTextNode(' '), insertPoint);

    ${jspre}counter[baseID]++;

    // disable the "add field" button if we are at the limit
    if (${jspre}counter[baseID] >= ${jspre}limit[baseID]) {
        var addButton = document.getElementById('$grow' + '_' + baseID);
        addButton.setAttribute('disabled', 'disabled');
    }    
}

EOJS

    # initialize growable counters
    for (@growable) {
        my $count = scalar(my @v = $_->values);
        $jsmisc .= "${jspre}counter['$_'] = $count;\n" if $count > 0;
        # assume that values of growable > 1 provide limits
        my $limit = $_->growable;
        if ($limit && $limit ne 1) {
            $jsmisc .= "${jspre}limit['$_'] = $limit;\n";
        }
    }
    return $jsmisc;
}

sub script_otherbox {
    my $self = shift;
    return '' unless my @otherable = grep { $_->other } $self->field;

    my $jspre  = $self->jsprefix || '';
    my $jsmisc = '';
    
    $jsmisc .= <<EOJS;
// turn on/off any "other"fields
function ${jspre}other_on (othername) {
    var box = document.getElementById(othername);
    box.removeAttribute('disabled');
}

function ${jspre}other_off (othername) {
    var box = document.getElementById(othername);
    box.setAttribute('disabled', 'disabled');
}

EOJS

    return $jsmisc;
}

sub noscript {
    my $self = shift;
    # no state is kept and no args are allowed
    puke "No args allowed for \$form->noscript" if @_;
    return '' unless $self->javascript;
    return '<noscript>' . $self->invalid_tag($self->{messages}->js_noscript) . '</noscript>';
}

sub submits {
    local $^W = 0;        # -w sucks
    my $self = shift;

    # handle the submit button(s)
    # logic is a little complicated - if set but to a false value,
    # then leave off. otherwise use as the value for the tags.
    my @submit = ();
    my $sn = $self->{submitname};
    my $sc = $self->class($self->{buttonname});
    if (ref $self->{submit} eq 'ARRAY') {
        # multiple buttons + JavaScript - dynamically set the _submit value
        my @oncl = $self->javascript
                       ? (onclick => "this.form.$sn.value = this.value;") : ();
        my $i=1;
        for my $subval (autodata $self->{submit}) {
            my $si = $i > 1 ? "_$i" : '';  # number with second one
            push @submit, { type  => 'submit',
                            id    => "$self->{name}$sn$si",
                            class => $sc,
                            name  => $sn, 
                            value => $subval, @oncl };
            $i++;
        }
    } else {
        # show the text on the button
        my $subval = $self->{submit} eq 1 ? $self->{messages}->form_submit_default
                                          : $self->{submit}; 
        push @submit, { type  => 'submit', 
                        id    => "$self->{name}$sn",
                        class => $sc,
                        name  => $sn, 
                        value => $subval };
    }
    return wantarray ? @submit : puke "Called \$form->submits in scalar context somehow";
}

sub submit {
    my $self = shift;
    $self->{submit} = shift if @_;
    return '' if ! $self->{submit} || $self->static || $self->disabled;

    # no newline on buttons regardless of setting
    return join '', map { htmltag('input', $_) } $self->submits(@_);
}

sub reset {
    local $^W = 0;        # -w sucks
    my $self = shift;
    $self->{reset} = shift if @_;
    return '' if ! $self->{reset} || $self->static || $self->disabled;
    my $sc = $self->class($self->{buttonname});

    # similar to submit(), but a little simpler ;-)
    my $reset = $self->{reset} eq 1 ? $self->{messages}->form_reset_default
                                    : $self->{reset}; 
    my $rn = $self->resetname;
    return htmltag('input', type  => 'reset',
                            id    => "$self->{name}$rn",
                            class => $sc,
                            name  => $rn,
                            value => $reset);
}

sub text {
    my $self = shift;
    $self->{text} = shift if @_;
    
    # having any required fields changes the leading text
    my $req = 0;
    my $inv = 0;
    for ($self->fields) {
        $req++ if $_->required;
        $inv++ if $_->invalid;  # failed validate()
    }

    unless ($self->static || $self->disabled) {
        # only show either invalid or required text
        return $self->{text} .'<p>'. sprintf($self->{messages}->form_invalid_text,
                                             $inv,
                                             $self->invalid_tag).'</p>' if $inv;

        return $self->{text} .'<p>'. sprintf($self->{messages}->form_required_text,
                                             $self->required_tag).'</p>' if $req;
    }
    return $self->{text};
}

sub invalid_tag {
    my $self = shift;
    my $label = shift || '';
    my @tags = $self->{stylesheet}
             ? (qq(<span class="$self->{styleclass}_invalid">), '</span>')
             : ('<font color="#cc0000"><b>', '</b></font>');
    return wantarray ? @tags : join $label, @tags;
}

sub required_tag {
    my $self = shift;
    my $label = shift || '';
    my @tags =  $self->{stylesheet}
             ? (qq(<span class="$self->{styleclass}_required">), '</span>')
             : ('<b>', '</b>');
    return wantarray ? @tags : join $label, @tags;
}

sub cgi_param {
    my $self = shift;
    $self->{params}->param(@_);
}

sub tmpl_param {
    my $self = shift;
    if (my $key  = shift) {
        return @_ ? $self->{tmplvar}{$key} = shift
                  : $self->{tmplvar}{$key};
    } else {
        # return hash or key/value pairs    
        my $hr = $self->{tmplvar} || {};
        return wantarray ? %$hr : $hr;
    }
}

sub version {
    # Hidden trailer. If you perceive this as annoying, let me know and I
    # may remove it. It's supposed to help.
    return '' if $::TESTING;
    if (ref $_[0]) {
        return "\n<!-- Generated by CGI::FormBuilder v$VERSION available from www.formbuilder.org -->\n";
    } else {
        return "CGI::FormBuilder v$VERSION by Nate Wiger. All Rights Reserved.\n";
    }
}

sub values {
    my $self = shift;

    if (@_) {
        $self->{values} = arghash(@_);
        my %val = ();
        my @val = ();

        # We currently make two passes, first getting the values
        # and storing them into a temp hash, and then going thru
        # the fields and picking up the values and attributes.
        local $" = ',';
        debug 1, "\$form->{values} = ($self->{values})";

        # Using isa() allows objects to transparently fit in here
        if (UNIVERSAL::isa($self->{values}, 'CODE')) {
            # it's a sub; lookup each value in turn
            for my $key (&{$self->{values}}) {
                # always assume an arrayref of values...
                $val{$key} = [ &{$self->{values}}($key) ];
                debug 2, "setting values from \\&code(): $key = (@{$val{$key}})";
            }
        } elsif (UNIVERSAL::isa($self->{values}, 'HASH')) {
            # must lc all the keys since we're case-insensitive, then
            # we turn our values hashref into an arrayref on the fly
            my @v = autodata $self->{values};
            while (@v) {
                my $key = lc shift @v;
                $val{$key} = [ autodata shift @v ];
                debug 2, "setting values from HASH: $key = (@{$val{$key}})";
            }
        } elsif (UNIVERSAL::isa($self->{values}, 'ARRAY')) {
            # also accept an arrayref which is walked sequentially below
            debug 2, "setting values from ARRAY: (walked below)";
            @val = autodata $self->{values};
        } else {
            puke "Unsupported operand to 'values' option - must be \\%hash, \\&sub, or \$object";
        }

        # redistribute values across all existing fields
        for ($self->fields) {
            my $v = $val{lc($_)} || shift @val;     # use array if no value
            $_->field(value => $v) if defined $v;
        }
    }

}

sub name {
    my $self = shift;
    @_ ? $self->{name} = shift : $self->{name};
}

sub nameopts {
    my $self = shift;
    if (@_) {
        $self->{nameopts} = shift;
        for ($self->fields) {
            $_->field(nameopts => $self->{nameopts});
        }
    }
    return $self->{nameopts};
}

sub sortopts {
    my $self = shift;
    if (@_) {
        $self->{sortopts} = shift;
        for ($self->fields) {
            $_->field(sortopts => $self->{sortopts});
        }
    }
    return $self->{sortopts};
}

sub selectnum {
    my $self = shift;
    if (@_) {
        $self->{selectnum} = shift;
        for ($self->fields) {
            $_->field(selectnum => $self->{selectnum});
        }
    }
    return $self->{selectnum};
}

sub options {
    my $self = shift;
    if (@_) {
        $self->{options} = arghash(@_);
        my %val = ();

        # same case-insensitization as $form->values
        my @v = autodata $self->{options};
        while (@v) {
            my $key = lc shift @v;
            $val{$key} = [ autodata shift @v ];
        }

        for ($self->fields) {
            my $v = $val{lc($_)};
            $_->field(options => $v) if defined $v;
        }
    }
    return $self->{options};
}

sub labels {
    my $self = shift;
    if (@_) {
        $self->{labels} = arghash(@_);
        my %val = ();

        # same case-insensitization as $form->values
        my @v = autodata $self->{labels};
        while (@v) {
            my $key = lc shift @v;
            $val{$key} = [ autodata shift @v ];
        }

        for ($self->fields) {
            my $v = $val{lc($_)};
            $_->field(label => $v) if defined $v;
        }
    }
    return $self->{labels};
}

# Note that validate does not work like a true accessor
sub validate {
    my $self = shift;
    
    if (@_) {
        if (ref $_[0]) {
            # this'll either be a hashref or a DFV object
            $self->{validate} = shift;
        } elsif (@_ % 2 == 0) {
            # someone passed a hash-as-list
            $self->{validate} = { @_ };
        } elsif (@_ > 1) {
            # just one argument we'll interpret as a DFV profile name;
            # an odd number > 1 is probably a typo...
            puke "Odd number of elements passed to validate";
        }
    }

    my $ok = 1;

    if (UNIVERSAL::isa($self->{validate}, 'Data::FormValidator')) {
        my $profile_name = shift || 'fb';
        debug 1, "validating fields via the '$profile_name' profile";
        # hang on to the DFV results, for things like DBIx::Class::WebForm
        $self->{dfv_results} = $self->{validate}->check($self, $profile_name);

	    # mark the invalid fields
	    my @invalid_fields = (
	        $self->{dfv_results}->invalid, 
	        $self->{dfv_results}->missing,
	    );
	    for my $field_name (@invalid_fields) {
	        $self->field(
		    name    => $field_name,
		    invalid => 1,
	        );
	    }
	    # validation failed
        $ok = 0 if @invalid_fields > 0;
    } else {    
        debug 1, "validating all fields via \$form->validate";
        for ($self->fields) {
            $ok = 0 unless $_->validate;
        }
    }
    debug 1, "validation done, ok = $ok (should be 1)";
    return $ok;
}

sub confirm {
    # This is nothing more than a special wrapper around render()
    my $self = shift;
    my $date = $::TESTING ? 'LOCALTIME' : localtime();
    $self->{text} ||= sprintf $self->{messages}->form_confirm_text, $date;
    $self->{static} = 1;
    return $self->render(@_);
}   

# Prepare a template
sub prepare {
    my $self = shift;
    debug 1, "Calling \$form->prepare(@_)";

    # Build a big hashref of data that can be used by the template
    # engine. Templates then have the ability to expand this however
    # they see fit.
    my %tmplvar = $self->tmpl_param;

    # This is based on the original Template Toolkit render()
    for my $field ($self->field) {

        # Extract value since used often
        my @value = $field->tag_value;

        # Create a struct for each field
        $tmplvar{field}{"$field"} = {
             %$field,   # gets invalid/missing/required
             field   => $field->tag,
             value   => $value[0],
             values  => \@value,
             options => [$field->options],
             label   => $field->label,
             type    => $field->type,
             comment => $field->comment,
             nameopts => $field->nameopts,
             cleanopts => $field->cleanopts,
        };
        # Force-stringify "$field" to get name() under buggy Perls
        $tmplvar{field}{"$field"}{error} = $field->error;
    }

    # Must generate JS first because it affects the others.
    # This is a bit action-at-a-distance, but I just can't
    # figure out a way around it.
    debug 2, "\$tmplvar{jshead} = \$self->script";
    $tmplvar{jshead}   = $self->script;
    debug 2, "\$tmplvar{title} = \$self->title";
    $tmplvar{title}    = $self->title;
    debug 2, "\$tmplvar{start} = \$self->start . \$self->statetags . \$self->keepextras";
    $tmplvar{start}    = $self->start . $self->statetags . $self->keepextras;
    debug 2, "\$tmplvar{submit} = \$self->submit";
    $tmplvar{submit}   = $self->submit;
    debug 2, "\$tmplvar{reset} = \$self->reset";
    $tmplvar{reset}    = $self->reset;
    debug 2, "\$tmplvar{end} = \$self->end";
    $tmplvar{end}      = $self->end;
    debug 2, "\$tmplvar{invalid} = \$self->invalid";
    $tmplvar{invalid}  = $self->invalid;
    debug 2, "\$tmplvar{required} = \$self->required";
    $tmplvar{required} = $self->required;
    debug 2, "\$tmplvar{fields} = [ map \$tmplvar{field}{\$_}, \$self->field ]";
    $tmplvar{fields}   = [ map $tmplvar{field}{$_}, $self->field ];

    return wantarray ? %tmplvar : \%tmplvar;
}

sub render {
    local $^W = 0;        # -w sucks
    my $self = shift;
    debug 1, "starting \$form->render(@_)";

    # any arguments are used to make permanent changes to the $form
    if (@_) {
        puke "Odd number of arguments passed into \$form->render()"
            unless @_ % 2 == 0;
        while (@_) {
            my $k = shift;
            $self->$k(shift);
        }
    }

    # check for engine type
    my $mod;
    my $ref = ref $self->{template};
    if (! $ref && $self->{template}) {
        # "legacy" string filename for HTML::Template; redo format
        # modifying $self object is ok because it's compatible
        $self->{template} = {
            type     => 'HTML',
            filename => $self->{template},
        };
        $ref = 'HASH';  # tricky
        debug 2, "rewrote 'template' option since found filename";
    }

    # Get ourselves ready
    $self->{prepare} = $self->prepare;

    my $opt;
    if ($ref eq 'HASH') {
        # must copy to avoid destroying
        $opt = { %{ $self->{template} } };
        $mod = delete $opt->{type} || 'HTML';
    } elsif ($ref eq 'CODE') {
        # subroutine wrapper
        return &{$self->{template}}($self);
    } elsif (UNIVERSAL::can($self->{template}, 'render')) {
        # instantiated object
        return $self->{template}->render($self);
    } elsif ($ref) {
        puke "Unsupported operand to 'template' option - must be \\%hash, \\&sub, or \$object w/ render()";
    }

    # load user-specified rendering module, or builtin rendering
    $mod ||= 'Builtin';

    # user can give 'Their::Complete::Module' or an 'IncludedAdapter'
    $mod = join '::', __PACKAGE__, 'Template', $mod unless $mod =~ /::/;
    debug 1, "loading $mod for 'template' option";

    # load module
    eval "require $mod";
    puke "Bad template engine $mod: $@" if $@;

    # create new object
    my $tmpl = $mod->new($opt);

    # Experiemental: Alter tag names as we're rendering, to support 
    # Ajaxian markup schemes that use their own tags (Backbase, Dojo, etc)
    local %CGI::FormBuilder::Util::TAGNAMES;
    while (my($k,$v) = each %{$self->{tagnames}}) {
        $CGI::FormBuilder::Util::TAGNAMES{$k} = $v;
    }

    # Call the engine's prepare too, if it exists
    # Give it the form object so it can do what it wants
    # This will have all of the prepared data in {prepare} anyways
    if ($tmpl && UNIVERSAL::can($tmpl, 'prepare')) {
        $tmpl->prepare($self);
    }

    # dispatch to engine, prepend header
    debug 1, "returning $tmpl->render($self->{prepare})";
    return $self->header . $tmpl->render($self->{prepare});
}

# These routines should be moved to ::Mail or something since they're rarely used
sub mail () {
    # This is a very generic mail handler
    my $self = shift;
    my $args = arghash(@_);

    # Where does the mailer live? Must be sendmail-compatible
    my $mailer = undef;
    unless ($mailer = $args->{mailer} && -x $mailer) {
        for my $sendmail (qw(/usr/lib/sendmail /usr/sbin/sendmail /usr/bin/sendmail)) {
            if (-x $sendmail) {
                $mailer = "$sendmail -t";
                last;
            }
        }
    }
    unless ($mailer) {
        belch "Cannot find a sendmail-compatible mailer; use mailer => '/path/to/mailer'";
        return;
    }
    unless ($args->{to}) {
        belch "Missing required 'to' argument; cannot continue without recipient";
        return;
    }
    if ($args->{from}) {
        (my $from = $args->{from}) =~ s/"/\\"/g;
        $mailer .= qq( -f "$from");
    }

    debug 1, "opening new mail to $args->{to}";

    # untaint
    my $oldpath = $ENV{PATH};
    $ENV{PATH} = '/usr/bin:/usr/sbin';

    open(MAIL, "|$mailer >/dev/null 2>&1") || next;
    print MAIL "From: $args->{from}\n";
    print MAIL "To: $args->{to}\n";
    print MAIL "Cc: $args->{cc}\n" if $args->{cc};
    print MAIL "Content-Type: text/plain; charset=\""
              . $self->charset . "\"\n" if $self->charset;
    print MAIL "Subject: $args->{subject}\n\n";
    print MAIL "$args->{text}\n";

    # retaint
    $ENV{PATH} = $oldpath;

    return close(MAIL);
}

sub mailconfirm () {

    # This prints out a very generic message. This should probably
    # be much better, but I suspect very few if any people will use
    # this method. If you do, let me know and maybe I'll work on it.

    my $self = shift;
    my $to = shift unless (@_ > 1);
    my $args = arghash(@_);

    # must have a "to"
    return unless $args->{to} ||= $to;

    # defaults
    $args->{from}    ||= 'auto-reply';
    $args->{subject} ||= sprintf $self->{messages}->mail_confirm_subject, $self->title;
    $args->{text}    ||= sprintf $self->{messages}->mail_confirm_text, scalar localtime();

    debug 1, "mailconfirm() called, subject = '$args->{subject}'";

    $self->mail($args);
}

sub mailresults () {
    # This is a wrapper around mail() that sends the form results
    my $self = shift;
    my $args = arghash(@_);

    if (exists $args->{plugin}) {
        my $lib = "CGI::FormBuilder::Mail::$args->{plugin}";
        eval "use $lib";
        puke "Cannot use mailresults() plugin '$lib': $@" if $@;
        eval {
            my $plugin = $lib->new( form => $self, %$args );
            $plugin->mailresults();
        };
        puke "Could not mailresults() with plugin '$lib': $@" if $@;
        return;
    }

    # Get the field separator to use
    my $delim = $args->{delimiter} || ': ';
    my $join  = $args->{joiner}    || $";
    my $sep   = $args->{separator} || "\n";

    # subject default
    $args->{subject} ||= sprintf $self->{messages}->mail_results_subject, $self->title;
    debug 1, "mailresults() called, subject = '$args->{subject}'";

    if ($args->{skip}) {
        if ($args->{skip} =~ m#^m?(\S)(.*)\1$#) {
            ($args->{skip} = $2) =~ s/\\\//\//g;
            $args->{skip} =~ s/\//\\\//g;
        }
    }

    my @form = ();
    for my $field ($self->fields) {
        if ($args->{skip} && $field =~ /$args->{skip}/) {
            next;
        }
        my $v = join $join, $field->value;
        $field = $field->label if $args->{labels};
        push @form, "$field$delim$v"; 
    }
    my $text = join $sep, @form;

    $self->mail(%$args, text => $text);
}

sub DESTROY { 1 }

# This is used to access all options after new(), by name
sub AUTOLOAD {
    # This allows direct addressing by name
    local $^W = 0;
    my $self = shift;
    my($name) = $AUTOLOAD =~ /.*::(.+)/;

    # If fieldsubs => 1 set, then allow grabbing fields directly
    if ($self->{fieldsubs} && $self->{fieldrefs}{$name}) {
        return $self->field(name => $name, @_);
    }

    debug 3, "-> dispatch to \$form->{$name} = @_";
    if (@_ % 2 == 1) {
        $self->{$name} = shift;

        if ($REARRANGE{$name}) {
            # needs to be splatted into every field
            for ($self->fields) {
                my $tval = rearrange($self->{$name}, "$_");
                $_->$name($tval);
            }
        }
    }

    # Try to catch  $form->$fieldname usage
    if ((! exists($self->{$name}) || @_) && ! $CGI::FormBuilder::Util::OURATTR{$name}) {
        if ($self->{fieldsubs}) {
            return $self->field(name => $name, @_);
        } else {
            belch "Possible field access via \$form->$name() - see 'fieldsubs' option"
        }
    }

    return $self->{$name};
}

1;
__END__

=head1 DESCRIPTION

If this is your first time using B<FormBuilder>, you should check out
the website for tutorials and examples:

    www.formbuilder.org

You should also consider joining the mailing list by sending an email to:

    fbusers-subscribe@formbuilder.org

There are some pretty smart people on the list that can help you out.

=head2 Overview

I hate generating and processing forms. Hate it, hate it, hate it,
hate it. My forms almost always end up looking the same, and almost
always end up doing the same thing. Unfortunately, there haven't
really been any tools out there that streamline the process. Many
modules simply substitute Perl for HTML code:

    # The manual way
    print qq(<input name="email" type="text" size="20">);

    # The module way
    print input(-name => 'email', -type => 'text', -size => '20');

The problem is, that doesn't really gain you anything - you still
have just as much code. Modules like C<CGI.pm> are great for
decoding parameters, but not for generating and processing whole forms.

The goal of CGI::FormBuilder (B<FormBuilder>) is to provide an easy way
for you to generate and process entire CGI form-based applications.
Its main features are:

=over

=item Field Abstraction

Viewing fields as entities (instead of just params), where the
HTML representation, CGI values, validation, and so on are properties
of each field.

=item DWIMmery

Lots of built-in "intelligence" (such as automatic field typing),
giving you about a 4:1 ratio of the code it generates versus what you
have to write.

=item Built-in Validation

Full-blown regex validation for fields, even including JavaScript
code generation.

=item Template Support

Pluggable support for external template engines, such as C<HTML::Template>,
C<Text::Template>, C<Template Toolkit>, and C<CGI::FastTemplate>.

=back

Plus, the native HTML generated is valid XHTML 1.0 Transitional.

=head2 Quick Reference

For the incredibly impatient, here's the quickest reference you can get:

    # Create form
    my $form = CGI::FormBuilder->new(

       # Important options
       fields     => \@array | \%hash,   # define form fields
       header     => 0 | 1,              # send Content-type?
       method     => 'post' | 'get',     # default is get
       name       => $string,            # namespace (recommended)
       reset      => 0 | 1 | $str,            # "Reset" button
       submit     => 0 | 1 | $str | \@array,  # "Submit" button(s)
       text       => $text,              # printed above form
       title      => $title,             # printed up top
       required   => \@array | 'ALL' | 'NONE',  # required fields?
       values     => \%hash | \@array,   # from DBI, session, etc
       validate   => \%hash,             # automatic field validation

       # Lesser-used options
       action     => $script,            # not needed (loops back)
       cookies    => 0 | 1,              # use cookies for sessionid?
       debug      => 0 | 1 | 2 | 3,      # gunk into error_log?
       fieldsubs  => 0 | 1,              # allow $form->$field()
       javascript => 0 | 1 | 'auto',     # generate JS validate() code?
       keepextras => 0 | 1 | \@array,    # keep non-field params?
       params     => $object,            # instead of CGI.pm
       sticky     => 0 | 1,              # keep CGI values "sticky"?
       messages   => $file | \%hash | $locale | 'auto',
       template   => $file | \%hash | $object,   # custom HTML

       # Formatting options
       body       => \%attr,             # {background => 'black'}
       disabled   => 0 | 1,              # display as grayed-out?
       font       => $font | \%attr,     # 'arial,helvetica'
       jsfunc     => $jscode,            # JS code into validate()
       jshead     => $jscode,            # JS code into <head>
       linebreaks => 0 | 1,              # put breaks in form?
       selectnum  => $threshold,         # for auto-type generation
       smartness  => 0 | 1 | 2,          # tweak "intelligence"
       static     => 0 | 1 | 2,          # show non-editable form?
       styleclass => $string,            # style class to use ("fb")
       stylesheet => 0 | 1 | $path,      # turn on style class=
       table      => 0 | 1 | \%attr,     # wrap form in <table>?
       td         => \%attr,             # <td> options
       tr         => \%attr,             # <tr> options

       # These are deprecated and you should use field() instead
       fieldtype  => 'type',
       fieldattr  => \%attr,
       labels     => \%hash,
       options    => \%hash,
       sortopts   => 'NAME' | 'NUM' | 1 | \&sub,

       # external source file (see CGI::FormBuilder::Source::File)
       source     => $file,
    );

    # Tweak fields
    $form->field(

       # Important options
       name       => $name,          # name of field (required)
       label      => $string,        # shown in front of <input>
       type       => $type,          # normally auto-determined
       multiple   => 0 | 1,          # allow multiple values?
       options    => \@options | \%options,   # radio/select/checkbox
       value      => $value | \@values,       # default value

       # Lesser-used options
       force      => 0 | 1,          # override CGI value?
       growable   => 0 | 1 | $limit, # expand text/file inputs?
       jsclick    => $jscode,        # instead of onclick
       jsmessage  => $string,        # on JS validation failure
       message    => $string,        # other validation failure
       other      => 0 | 1,          # create "Other:" input?
       required   => 0 | 1,          # must fill field in?
       validate   => '/regex/',      # validate user input

       # Formatting options
       cleanopts  => 0 | 1,          # HTML-escape options?
       columns    => 0 | $width,     # wrap field options at $width
       comment    => $string,        # printed after field
       disabled   => 0 | 1,          # display as grayed-out?
       labels     => \%hash,         # deprecated (use "options")
       linebreaks => 0 | 1,          # insert breaks in options?
       nameopts   => 0 | 1,          # auto-name options?
       sortopts   => 'NAME' | 'NUM' | 1 | \&sub,   # sort options?

       # Change size, maxlength, or any other HTML attr
       $htmlattr  => $htmlval,
    );

    # Check for submission
    if ($form->submitted && $form->validate) {

        # Get single value
        my $value = $form->field('name');

        # Get list of fields
        my @field = $form->field;

        # Get hashref of key/value pairs
        my $field = $form->field;
        my $value = $field->{name};

    }

    # Print form
    print $form->render(any_opt_from_new => $some_value);

That's it. Keep reading.

=head2 Walkthrough

Let's walk through a whole example to see how B<FormBuilder> works.
We'll start with this, which is actually a complete (albeit simple)
form application:

    use CGI::FormBuilder;

    my @fields = qw(name email password confirm_password zipcode);

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    header => 1
               );

    print $form->render;

The above code will render an entire form, and take care of maintaining
state across submissions. But it doesn't really I<do> anything useful
at this point.

So to start, let's add the C<validate> option to make sure the data
entered is valid:

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields, 
                    header   => 1,
                    validate => {
                       name  => 'NAME',
                       email => 'EMAIL'
                    }
               );

We now get a whole bunch of JavaScript validation code, and the
appropriate hooks are added so that the form is validated by the
browser C<onsubmit> as well.

Now, we also want to validate our form on the server side, since
the user may not be running JavaScript. All we do is add the
statement:

    $form->validate;

Which will go through the form, checking each field specified to
the C<validate> option to see if it's ok. If there's a problem, then
that field is highlighted, so that when you print it out the errors
will be apparent.

Of course, the above returns a truth value, which we should use to
see if the form was valid. That way, we only update our database if
everything looks good:

    if ($form->validate) {
        # print confirmation screen
        print $form->confirm;
    } else {
        # print the form for them to fill out
        print $form->render;
    }

However, we really only want to do this after our form has been
submitted, since otherwise this will result in our form showing
errors even though the user hasn't gotten a chance to fill it
out yet. As such, we want to check for whether the form has been
C<submitted()> yet:

    if ($form->submitted && $form->validate) {
        # print confirmation screen
        print $form->confirm;
    } else {
        # print the form for them to fill out
        print $form->render;
    }

Now that know that our form has been submitted and is valid, we
need to get our values. To do so, we use the C<field()> method
along with the name of the field we want:

    my $email = $form->field(name => 'email');

Note we can just specify the name of the field if it's the only
option:

    my $email = $form->field('email');   # same thing

As a very useful shortcut, we can get all our fields back as a
hashref of field/value pairs by calling C<field()> with no arguments:

    my $fields = $form->field;      # all fields as hashref

To make things easy, we'll use this form so that we can pass it
easily into a sub of our choosing:

    if ($form->submitted && $form->validate) {
        # form was good, let's update database
        my $fields = $form->field;

        # update database (you write this part)
        do_data_update($fields); 

        # print confirmation screen
        print $form->confirm;
    }

Finally, let's say we decide that we like our form fields, but we
need the HTML to be laid out very precisely. No problem! We simply
create an C<HTML::Template> compatible template and tell B<FormBuilder>
to use it. Then, in our template, we include a couple special tags
which B<FormBuilder> will automatically expand:

    <html>
    <head>
    <title><tmpl_var form-title></title>
    <tmpl_var js-head><!-- this holds the JavaScript code -->
    </head>
    <tmpl_var form-start><!-- this holds the initial form tag -->
    <h3>User Information</h3>
    Please fill out the following information:
    <!-- each of these tmpl_var's corresponds to a field -->
    <p>Your full name: <tmpl_var field-name>
    <p>Your email address: <tmpl_var field-email>
    <p>Choose a password: <tmpl_var field-password>
    <p>Please confirm it: <tmpl_var field-confirm_password>
    <p>Your home zipcode: <tmpl_var field-zipcode>
    <p>
    <tmpl_var form-submit><!-- this holds the form submit button -->
    </form><!-- can also use "tmpl_var form-end", same thing -->

Then, all we need to do add the C<template> option, and the rest of
the code stays the same:

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields, 
                    header   => 1,
                    validate => {
                       name  => 'NAME',
                       email => 'EMAIL'
                    },
                    template => 'userinfo.tmpl'
               );

So, our complete code thus far looks like this:

    use CGI::FormBuilder;

    my @fields = qw(name email password confirm_password zipcode);

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields, 
                    header   => 1,
                    validate => {
                       name  => 'NAME',
                       email => 'EMAIL'
                    },
                    template => 'userinfo.tmpl',
               );

    if ($form->submitted && $form->validate) {
        # form was good, let's update database
        my $fields = $form->field;

        # update database (you write this part)
        do_data_update($fields); 

        # print confirmation screen
        print $form->confirm;

    } else {
        # print the form for them to fill out
        print $form->render;
    }

You may be surprised to learn that for many applications, the
above is probably all you'll need. Just fill in the parts that
affect what you want to do (like the database code), and you're
on your way.

B<Note:> If you are confused at all by the backslashes you see
in front of some data pieces above, such as C<\@fields>, skip down
to the brief section entitled L</"REFERENCES"> at the bottom of this
document (it's short).

=head1 METHODS

This documentation is very extensive, but can be a bit dizzying due
to the enormous number of options that let you tweak just about anything.
As such, I recommend that you stop and visit:

    www.formbuilder.org

And click on "Tutorials" and "Examples". Then, use the following section
as a reference later on.

=head2 new()

This method creates a new C<$form> object, which you then use to generate
and process your form. In the very shortest version, you can just specify
a list of fields for your form:

    my $form = CGI::FormBuilder->new(
                    fields => [qw(first_name birthday favorite_car)]
               );

As of 3.02:

    my $form = CGI::FormBuilder->new(
                    source => 'myform.conf'   # form and field options
               );

For details on the external file format, see L<CGI::FormBuilder::Source::File>.

Any of the options below, in addition to being specified to C<new()>, can
also be manipulated directly with a method of the same name. For example,
to change the C<header> and C<stylesheet> options, either of these works:

    # Way 1
    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    header => 1,
                    stylesheet => '/path/to/style.css',
               );

    # Way 2
    my $form = CGI::FormBuilder->new(
                    fields => \@fields
               );
    $form->header(1);
    $form->stylesheet('/path/to/style.css');

The second form is useful if you want to wrap certain options in
conditionals:

    if ($have_template) {
        $form->header(0);
        $form->template('template.tmpl');
    } else {
        $form->header(1);
        $form->stylesheet('/path/to/style.css');
    }

The following is a description of each option, in alphabetical order:

=over

=item action => $script

What script to point the form to. Defaults to itself, which is
the recommended setting.

=item body => \%attr

This takes a hashref of attributes that will be stuck in the
C<< <body> >> tag verbatim (for example, bgcolor, alink, etc).
See the C<fieldattr> tag for more details, and also the
C<template> option.

=item charset

This forcibly overrides the charset. Better handled by loading
an appropriate C<messages> module, which will set this for you.
See L<CGI::FormBuilder::Messages> for more details.

=item debug => 0 | 1 | 2 | 3

If set to 1, the module spits copious debugging info to STDERR.
If set to 2, it spits out even more gunk. 3 is too much. Defaults to 0.

=item fields => \@array | \%hash

As shown above, the C<fields> option takes an arrayref of fields to use
in the form. The fields will be printed out in the same order they are
specified. This option is needed if you expect your form to have any fields,
and is I<the> central option to FormBuilder.

You can also specify a hashref of key/value pairs. The advantage is
you can then bypass the C<values> option. However, the big disadvantage
is you cannot control the order of the fields. This is ok if you're
using a template, but in real-life it turns out that passing a hashref
to C<fields> is not very useful.

=item fieldtype => 'type'

This can be used to set the default type for all fields in the form.
You can then override it on a per-field basis using the C<field()> method.

=item fieldattr => \%attr

This option allows you to specify I<any> HTML attribute and have it be
the default for all fields. This used to be good for stylesheets, but
now that there is a C<stylesheet> option, this is fairly useless.

=item fieldsubs => 0 | 1

This allows autoloading of field names so you can directly access
them as:

    $form->$fieldname(opt => 'val');

Instead of:

    $form->field(name => $fieldname, opt => 'val');

Warning: If present, it will hide any attributes of the same name.
For example, if you define "name" field, you won't be able to 
change your form's name dynamically. Also, you cannot use this
format to create new fields. Use with caution.

=item font => $font | \%attr

The font face to use for the form. This is output as a series of
C<< <font> >> tags for old browser compatibility, and will 
properly nest them in all of the table elements. If you specify
a hashref instead of just a font name, then each key/value pair
will be taken as part of the C<< <font> >> tag:

    font => {face => 'verdana', size => '-1', color => 'gray'}

The above becomes:

    <font face="verdana" size="-1" color="gray">

I used to use this all the time, but the C<stylesheet> option
is B<SO MUCH BETTER>. Trust me, take a day and learn the basics
of CSS, it's totally worth it.

=item header => 0 | 1

If set to 1, a valid C<Content-type> header will be printed out,
along with a whole bunch of HTML C<< <body> >> code, a C<< <title> >>
tag, and so on. This defaults to 0, since often people end up using
templates or embedding forms in other HTML.

=item javascript => 0 | 1

If set to 1, JavaScript is generated in addition to HTML, the
default setting.

=item jsfunc => $jscode

This is verbatim JavaScript that will go into the C<validate>
JavaScript function. It is useful for adding your own validation
code, while still getting all the automatic hooks. If something fails,
you should do two things:

    1. append to the JavaScript string "alertstr"
    2. increment the JavaScript number "invalid"

For example:

    my $jsfunc = <<'EOJS';   # note single quote (see Hint)
      if (form.password.value == 'password') {
        alertstr += "Moron, you can't use 'password' for your password!\\n";
        invalid++;
      }
    EOJS

    my $form = CGI::FormBuilder->new(... jsfunc => $jsfunc);

Then, this code will be automatically called when form validation
is invoked. I find this option can be incredibly useful. Most often,
I use it to bypass validation on certain submit modes. The submit
button that was clicked is C<form._submit.value>:

    my $jsfunc = <<'EOJS';   # note single quotes (see Hint)
      if (form._submit.value == 'Delete') {
         if (confirm("Really DELETE this entry?")) return true;
         return false;
      } else if (form._submit.value == 'Cancel') {
         // skip validation since we're cancelling
         return true;
      }
    EOJS

Hint: To prevent accidental expansion of embedding strings and escapes,
you should put your C<HERE> string in single quotes, as shown above.

=item jshead => $jscode

If using JavaScript, you can also specify some JavaScript code
that will be included verbatim in the <head> section of the
document. I'm not very fond of this one, what you probably
want is the previous option.

=item keepextras => 0 | 1 | \@array

If set to 1, then extra parameters not set in your fields declaration
will be kept as hidden fields in the form. However, you will need
to use C<cgi_param()>, B<NOT> C<field()>, to access the values.

This is useful if you want to keep some extra parameters like mode or
company available but not have them be valid form fields:

    keepextras => 1

That will preserve any extra params. You can also specify an arrayref,
in which case only params in that list will be preserved. For example:

    keepextras => [qw(mode company)]

Will only preserve the params C<mode> and C<company>. Again, to access them:

    my $mode = $form->cgi_param('mode');
    $form->cgi_param(name => 'mode', value => 'relogin');

See C<CGI.pm> for details on C<param()> usage.

=item labels => \%hash

Like C<values>, this is a list of key/value pairs where the keys
are the names of C<fields> specified above. By default, B<FormBuilder>
does some snazzy case and character conversion to create pretty labels
for you. However, if you want to explicitly name your fields, use this
option.

For example:

    my $form = CGI::FormBuilder->new(
                    fields => [qw(name email)],
                    labels => {
                        name  => 'Your Full Name',
                        email => 'Primary Email Address'
                    }
               );

Usually you'll find that if you're contemplating this option what
you really want is a template.

=item lalign => 'left' | 'right' | 'center'

A legacy shortcut for:

    th => { align => 'left' }

Even better, use the C<stylesheet> option and tweak the C<.fb_label>
class. Either way, don't use this.

=item lang

This forcibly overrides the lang. Better handled by loading
an appropriate C<messages> module, which will set this for you.
See L<CGI::FormBuilder::Messages> for more details.

=item method => 'post' | 'get'

The type of CGI method to use, either C<post> or C<get>. Defaults
to C<get> if nothing is specified. Note that for forms that cause
changes on the server, such as database inserts, you should use
the C<post> method.

=item messages => 'auto' | $file | \%hash | $locale

This option overrides the default B<FormBuilder> messages in order to
provide multilingual locale support (or just different text for the picky ones).
For details on this option, please refer to L<CGI::FormBuilder::Messages>.

=item name => $string

This names the form. It is optional, but when used, it renames several
key variables and functions according to the name of the form. In addition,
it also adds the following C<< <div> >> tags to each row of the table:

    <tr id="${form}_${field}_row">
        <td id="${form}_${field}_label">Label</td>
        <td id="${form}_${field}_input"><input tag></td>
        <td id="${form}_${field}_error">Error</td><!-- if invalid -->
    </tr>

These changes allow you to (a) use multiple forms in a sequential application
and/or (b) display multiple forms inline in one document. If you're trying
to build a complex multi-form app and are having problems, try naming
your forms.

=item options => \%hash

This is one of several I<meta-options> that allows you to specify
stuff for multiple fields at once:

    my $form = CGI::FormBuilder->new(
                    fields => [qw(part_number department in_stock)],
                    options => {
                        department => [qw(hardware software)],
                        in_stock   => [qw(yes no)],
                    }
               );

This has the same effect as using C<field()> for the C<department>
and C<in_stock> fields to set options individually.

=item params => $object

This specifies an object from which the parameters should be derived.
The object must have a C<param()> method which will return values
for each parameter by name. By default a CGI object will be 
automatically created and used.

However, you will want to specify this if you're using C<mod_perl>:

    use Apache::Request;
    use CGI::FormBuilder;

    sub handler {
        my $r = Apache::Request->new(shift);
        my $form = CGI::FormBuilder->new(... params => $r);
        print $form->render;
    }

Or, if you need to initialize a C<CGI.pm> object separately and
are using a C<post> form method:

    use CGI;
    use CGI::FormBuilder;

    my $q = new CGI;
    my $form = CGI::FormBuilder->new(... params => $q);

Usually you don't need to do this, unless you need to access other
parameters outside of B<FormBuilder>'s control.

=item required => \@array | 'ALL' | 'NONE'

This is a list of those values that are required to be filled in.
Those fields named must be included by the user. If the C<required>
option is not specified, by default any fields named in C<validate>
will be required.

In addition, the C<required> option also takes two other settings,
the strings C<ALL> and C<NONE>. If you specify C<ALL>, then all
fields are required. If you specify C<NONE>, then none of them are
I<in spite of what may be set via the "validate" option>.

This is useful if you have fields that are optional, but that you
want to be validated if filled in:

    my $form = CGI::FormBuilder->new(
                    fields => qw[/name email/],
                    validate => { email => 'EMAIL' },
                    required => 'NONE'
               );

This would make the C<email> field optional, but if filled in then
it would have to match the C<EMAIL> pattern.

In addition, it is I<very> important to note that if the C<required>
I<and> C<validate> options are specified, then they are taken as an
intersection. That is, only those fields specified as C<required>
must be filled in, and the rest are optional. For example:

    my $form = CGI::FormBuilder->new(
                    fields => qw[/name email/],
                    validate => { email => 'EMAIL' },
                    required => [qw(name)]
               );

This would make the C<name> field mandatory, but the C<email> field
optional. However, if C<email> is filled in, then it must match the
builtin C<EMAIL> pattern.

=item reset => 0 | 1 | $string

If set to 0, then the "Reset" button is not printed. If set to 
text, then that will be printed out as the reset button. Defaults
to printing out a button that says "Reset".

=item selectnum => $threshold

This detects how B<FormBuilder>'s auto-type generation works. If a
given field has options, then it will be a radio group by default.
However, if more than C<selectnum> options are present, then it will
become a select list. The default is 5 or more options. For example:

    # This will be a radio group
    my @opt = qw(Yes No);
    $form->field(name => 'answer', options => \@opt);

    # However, this will be a select list
    my @states = qw(AK CA FL NY TX);
    $form->field(name => 'state', options => \@states);

    # Single items are checkboxes (allows unselect)
    $form->field(name => 'answer', options => ['Yes']);

There is no threshold for checkboxes since, if you think about it,
they are really a multi-radio select group. As such, a radio group
becomes a checkbox group if the C<multiple> option is specified and
the field has I<less> than C<selectnum> options. Got it?

=item smartness => 0 | 1 | 2

By default CGI::FormBuilder tries to be pretty smart for you, like
figuring out the types of fields based on their names and number
of options. If you don't want this behavior at all, set C<smartness>
to C<0>. If you want it to be B<really> smart, like figuring
out what type of validation routines to use for you, set it to
C<2>. It defaults to C<1>.

=item sortopts => BUILTIN | 1 | \&sub

If specified to C<new()>, this has the same effect as the same-named
option to C<field()>, only it applies to all fields.

=item source => $filename

You can use this option to initialize B<FormBuilder> from an external
configuration file. This allows you to separate your field code from
your form layout, which is pretty cool. See L<CGI::FormBuilder::Source::File>
for details on the format of the external file.

=item static => 0 | 1 | 2

If set to 1, then the form will be output with static hidden fields.
If set to 2, then in addition fields without values will be omitted.
Defaults to 0.

=item sticky => 0 | 1

Determines whether or not form values should be sticky across
submissions. This defaults to 1, meaning values are sticky. However,
you may want to set it to 0 if you have a form which does something
like adding parts to a database. See the L</"EXAMPLES"> section for 
a good example.

=item submit => 0 | 1 | $string | \@array

If set to 0, then the "Submit" button is not printed. It defaults
to creating a button that says "Submit" verbatim. If given an
argument, then that argument becomes the text to show. For example:

    print $form->render(submit => 'Do Lookup');

Would make it so the submit button says "Do Lookup" on it. 

If you pass an arrayref of multiple values, you get a key benefit.
This will create multiple submit buttons, each with a different value.
In addition, though, when submitted only the one that was clicked
will be sent across CGI via some JavaScript tricks. So this:

    print $form->render(submit => ['Add A Gift', 'No Thank You']);

Would create two submit buttons. Clicking on either would submit the
form, but you would be able to see which one was submitted via the
C<submitted()> function:

    my $clicked = $form->submitted;

So if the user clicked "Add A Gift" then that is what would end up
in the variable C<$clicked> above. This allows nice conditionality:

    if ($form->submitted eq 'Add A Gift') {
        # show the gift selection screen
    } elsif ($form->submitted eq 'No Thank You')
        # just process the form
    }

See the L</"EXAMPLES"> section for more details.

=item styleclass => $string

The string to use as the C<style> name, if the following option
is enabled.

=item stylesheet => 0 | 1 | $path

This option turns on stylesheets in the HTML output by B<FormBuilder>.
Each element is printed with the C<class> of C<styleclass> ("fb"
by default). It is up to you to provide the actual style definitions.
If you provide a C<$path> rather than just a 1/0 toggle, then that
C<$path> will be included in a C<< <link> >> tag as well.

The following tags are created by this option:

    ${styleclass}           top-level table/form class
    ${styleclass}_required  labels for fields that are required
    ${styleclass}_invalid   any fields that failed validate()

If you're contemplating stylesheets, the best thing is to just turn
this option on, then see what's spit out.

See the section on L</"STYLESHEETS"> for more details on FormBuilder
style sheets.

=item table => 0 | 1 | \%tabletags

By default B<FormBuilder> decides how to layout the form based on
the number of fields, values, etc. You can force it into a table
by specifying C<1>, or force it out of one with C<0>.

If you specify a hashref instead, then these will be used to 
create the C<< <table> >> tag. For example, to create a table
with no cellpadding or cellspacing, use:

    table => {cellpadding => 0, cellspacing => 0}

Also, you can specify options to the C<< <td> >> and C<< <tr> >>
elements as well in the same fashion.

=item template => $filename | \%hash | \&sub | $object

This points to a filename that contains an C<HTML::Template>
compatible template to use to layout the HTML. You can also specify
the C<template> option as a reference to a hash, allowing you to
further customize the template processing options, or use other
template engines.

If C<template> points to a sub reference, that routine is called
and its return value directly returned. If it is an object, then
that object's C<render()> routine is called and its value returned.

For lots more information, please see L<CGI::FormBuilder::Template>.

=item text => $text

This is text that is included below the title but above the
actual form. Useful if you want to say something simple like
"Contact $adm for more help", but if you want lots of text
check out the C<template> option above.

=item title => $title

This takes a string to use as the title of the form. 

=item values => \%hash | \@array

The C<values> option takes a hashref of key/value pairs specifying
the default values for the fields. These values will be overridden
by the values entered by the user across the CGI. The values are
used case-insensitively, making it easier to use DBI hashref records
(which are in upper or lower case depending on your database).

This option is useful for selecting a record from a database or
hardwiring some sensible defaults, and then including them in the
form so that the user can change them if they wish. For example:

    my $rec = $sth->fetchrow_hashref;
    my $form = CGI::FormBuilder->new(fields => \@fields,
                                     values => $rec);

You can also pass an arrayref, in which case each value is used
sequentially for each field as specified to the C<fields> option.

=item validate => \%hash | $object

This option takes either a hashref of key/value pairs or a
L<Data::FormValidator> object.

In the case of the hashref, each key is the
name of a field from the C<fields> option, or the string C<ALL>
in which case it applies to all fields. Each value is one of
the following:

    - a regular expression in 'quotes' to match against
    - an arrayref of values, of which the field must be one
    - a string that corresponds to one of the builtin patterns
    - a string containing a literal code comparison to do
    - a reference to a sub to be used to validate the field
      (the sub will receive the value to check as the first arg)

In addition, each of these can also be grouped together as:

    - a hashref containing pairings of comparisons to do for
      the two different languages, "javascript" and "perl"

By default, the C<validate> option also toggles each field to make
it required. However, you can use the C<required> option to change
this, see it for more details.

Let's look at a concrete example:

    my $form = CGI::FormBuilder->new(
                    fields => [
                        qw(username password confirm_password
                           first_name last_name email)
                    ],
                    validate => {
                        username   => [qw(nate jim bob)],
                        first_name => '/^\w+$/',    # note the 
                        last_name  => '/^\w+$/',    # single quotes!
                        email      => 'EMAIL',
                        password   => \&check_password,
                        confirm_password => {
                            javascript => '== form.password.value',
                            perl       => 'eq $form->field("password")'
                        },
                    },
               );

    # simple sub example to check the password
    sub check_password ($) {
        my $v = shift;                   # first arg is value
        return unless $v =~ /^.{6,8}/;   # 6-8 chars
        return if $v eq "password";      # dummy check
        return unless passes_crack($v);  # you write "passes_crack()"
        return 1;                        # success
    }

This would create both JavaScript and Perl routines on the fly
that would ensure:

    - "username" was either "nate", "jim", or "bob"
    - "first_name" and "last_name" both match the regex's specified
    - "email" is a valid EMAIL format
    - "password" passes the checks done by check_password(), meaning
       that the sub returns true
    - "confirm_password" is equal to the "password" field

B<Any regular expressions you specify must be enclosed in single quotes
because they need to be used in both JavaScript and Perl code.> As
such, specifying a C<qr//> will NOT work.

Note that for both the C<javascript> and C<perl> hashref code options,
the form will be present as the variable named C<form>. For the Perl
code, you actually get a complete C<$form> object meaning that you
have full access to all its methods (although the C<field()> method
is probably the only one you'll need for validation).

In addition to taking any regular expression you'd like, the
C<validate> option also has many builtin defaults that can
prove helpful:

    VALUE   -  is any type of non-null value
    WORD    -  is a word (\w+)
    NAME    -  matches [a-zA-Z] only
    FNAME   -  person's first name, like "Jim" or "Joe-Bob"
    LNAME   -  person's last name, like "Smith" or "King, Jr."
    NUM     -  number, decimal or integer
    INT     -  integer
    FLOAT   -  floating-point number
    PHONE   -  phone number in form "123-456-7890" or "(123) 456-7890"
    INTPHONE-  international phone number in form "+prefix local-number"
    EMAIL   -  email addr in form "name@host.domain"
    CARD    -  credit card, including Amex, with or without -'s
    DATE    -  date in format MM/DD/YYYY
    EUDATE  -  date in format DD/MM/YYYY
    MMYY    -  date in format MM/YY or MMYY
    MMYYYY  -  date in format MM/YYYY or MMYYYY
    CCMM    -  strict checking for valid credit card 2-digit month ([0-9]|1[012])
    CCYY    -  valid credit card 2-digit year
    ZIPCODE -  US postal code in format 12345 or 12345-6789
    STATE   -  valid two-letter state in all uppercase
    IPV4    -  valid IPv4 address
    NETMASK -  valid IPv4 netmask
    FILE    -  UNIX format filename (/usr/bin)
    WINFILE -  Windows format filename (C:\windows\system)
    MACFILE -  MacOS format filename (folder:subfolder:subfolder)
    HOST    -  valid hostname (some-name)
    DOMAIN  -  valid domainname (www.i-love-bacon.com)
    ETHER   -  valid ethernet address using either : or . as separators

I know some of the above are US-centric, but then again that's where I live. :-)
So if you need different processing just create your own regular expression
and pass it in. If there's something really useful let me know and maybe
I'll add it.

You can also pass a Data::FormValidator object as the value of C<validate>.
This allows you to do things like requiring any one of several fields (but 
where you don't care which one). In this case, the C<required> option to 
C<new()> is ignored, since you should be setting the required fields through
your FormValidator profile.

By default, FormBuilder will try to use a profile named `fb' to validate
itself. You can change this by providing a different profile name when you
call C<validate()>.

Note that currently, doing validation through a FormValidator object
doesn't generate any JavaScript validation code for you.

=back

Note that any other options specified are passed to the C<< <form> >>
tag verbatim. For example, you could specify C<onsubmit> or C<enctype>
to add the respective attributes.

=head2 prepare()

This function prepares a form for rendering. It is automatically
called by C<render()>, but calling it yourself may be useful if
you are using B<Catalyst> or some other large framework. It returns
the same hash that will be used by C<render()>:

    my %expanded = $form->prepare;

You could use this to, say, tweak some custom values and then
pass it to your own rendering object.

=head2 render()

This function renders the form into HTML, and returns a string
containing the form. The most common use is simply:

    print $form->render;

You can also supply options to C<render()>, just like you had
called the accessor functions individually. These two uses are
equivalent:

    # this code:
    $form->header(1);
    $form->stylesheet('style.css');
    print $form->render;

    # is the same as:
    print $form->render(header => 1,
                        stylesheet => 'style.css');

Note that both forms make permanent changes to the underlying
object. So the next call to C<render()> will still have the 
header and stylesheet options in either case.

=head2 field()

This method is used to both get at field values:

    my $bday = $form->field('birthday');

As well as make changes to their attributes:

    $form->field(name  => 'fname',
                 label => "First Name");

A very common use is to specify a list of options and/or the field type:

    $form->field(name    => 'state',
                 type    => 'select',
                 options => \@states);      # you supply @states

In addition, when you call C<field()> without any arguments, it returns
a list of valid field names in an array context:

    my @fields = $form->field;

And a hashref of field/value pairs in scalar context:

    my $fields = $form->field;
    my $name = $fields->{name};

Note that if you call it in this manner, you only get one single
value per field. This is fine as long as you don't have multiple
values per field (the normal case). However, if you have a field
that allows multiple options:

    $form->field(name => 'color', options => \@colors,
                 multiple => 1);        # allow multi-select

Then you will only get one value for C<color> in the hashref. In
this case you'll need to access it via C<field()> to get them all:

    my @colors = $form->field('color');

The C<name> option is described first, and the remaining options
are in order:

=over

=item name => $name

The field to manipulate. The "name =>" part is optional if it's the
only argument. For example:

    my $email = $form->field(name => 'email');
    my $email = $form->field('email');   # same thing

However, if you're specifying more than one argument, then you must
include the C<name> part:

    $form->field(name => 'email', size => '40');

=item columns => 0 | $width

If set and the field is of type 'checkbox' or 'radio', then the
options will be wrapped at the given width.

=item comment => $string

This prints out the given comment I<after> the field. A good use of
this is for additional help on what the field should contain:

    $form->field(name    => 'dob',
                 label   => 'D.O.B.',
                 comment => 'in the format MM/DD/YY');

The above would yield something like this:

    D.O.B. [____________] in the format MM/DD/YY

The comment is rendered verbatim, meaning you can use HTML links
or code in it if you want.

=item cleanopts => 0 | 1

If set to 1 (the default), field options are escaped to make sure
any special chars don't screw up the HTML. Set to 0 if you want to
include verbatim HTML in your options, and know what you're doing.

=item cookies => 0 | 1

Controls whether to generate a cookie if C<sessionid> has been set.
This also requires that C<header> be set as well, since the cookie
is wrapped in the header. Defaults to 1, meaning it will automatically
work if you turn on C<header>.

=item force => 0 | 1

This is used in conjunction with the C<value> option to forcibly
override a field's value. See below under the C<value> option for
more details. For compatibility with C<CGI.pm>, you can also call
this option C<override> instead, but don't tell anyone.

=item growable => 0 | 1 | $limit

This option adds a button and the appropriate JavaScript code to 
your form to allow the additional copies of the field to be added
by the client filling out the form. Currently, this only works with
C<text> and C<file> field types.

If you set C<growable> to a positive integer greater than 1, that
will become the limit of growth for that field. You won't be able
to add more than C<$limit> extra inputs to the form, and FormBuilder 
will issue a warning if the CGI params come in with more than the
allowed number of values.

=item jsclick => $jscode

This is a cool abstraction over directly specifying the JavaScript
action. This turns out to be extremely useful, since if a field
type changes from C<select> to C<radio> or C<checkbox>, then the
action changes from C<onchange> to C<onclick>. Why?!?!

So if you said:

    $form->field(name    => 'credit_card', 
                 options => \@cards,
                 jsclick => 'recalc_total();');

This would generate the following code, depending on the number
of C<@cards>:

    <select name="credit_card" onchange="recalc_total();"> ...

    <radio name="credit_card" onclick="recalc_total();"> ...

You get the idea.

=item jsmessage => $string

You can use this to specify your own custom message for the field,
which will be printed if it fails validation. The C<jsmessage>
option affects the JavaScript popup box, and the C<message> option
affects what is printed out if the server-side validation fails.
If C<message> is specified but not C<jsmessage>, then C<message>
will be used for JavaScript as well.

    $form->field(name      => 'cc',
                 label     => 'Credit Card',
                 message   => 'Invalid credit card number',
                 jsmessage => 'The card number in "%s" is invalid');

The C<%s> will be filled in with the field's C<label>.

=item label => $string

This is the label printed out before the field. By default it is 
automatically generated from the field name. If you want to be
really lazy, get in the habit of naming your database fields as
complete words so you can pass them directly to/from your form.

=item labels => \%hash

B<This option to field() is outdated.> You can get the same effect by
passing data structures directly to the C<options> argument (see below).
If you have well-named data, check out the C<nameopts> option.

This takes a hashref of key/value pairs where each key is one of
the options, and each value is what its printed label should be:

    $form->field(name    => 'state',
                 options => [qw(AZ CA NV OR WA)],
                 labels  => {
                      AZ => 'Arizona',
                      CA => 'California',
                      NV => 'Nevada',
                      OR => 'Oregon',
                      WA => 'Washington
                 });

When rendered, this would create a select list where the option
values were "CA", "NV", etc, but where the state's full name
was displayed for the user to select. As mentioned, this has
the exact same effect:

    $form->field(name    => 'state',
                 options => [
                    [ AZ => 'Arizona' ], 
                    [ CA => 'California' ],
                    [ NV => 'Nevada' ],
                    [ OR => 'Oregon' ],
                    [ WA => 'Washington ],
                 ]);

I can think of some rare situations where you might have a set
of predefined labels, but only some of those are present in a
given field... but usually you should just use the C<options> arg.

=item linebreaks => 0 | 1

Similar to the top-level "linebreaks" option, this one will put
breaks in between options, to space things out more. This is
useful with radio and checkboxes especially.

=item message => $string

Like C<jsmessage>, this customizes the output error string if
server-side validation fails for the field. The C<message>
option will also be used for JavaScript messages if it is
specified but C<jsmessage> is not. See above under C<jsmessage>
for details.

=item multiple => 0 | 1

If set to 1, then the user is allowed to choose multiple
values from the options provided. This turns radio groups
into checkboxes and selects into multi-selects. Defaults
to automatically being figured out based on number of values.

=item nameopts => 0 | 1

If set to 1, then options for select lists will be automatically
named using the same algorithm as field labels. For example:

    $form->field(name     => 'department', 
                 options  => qw[(molecular_biology
                                 philosophy psychology
                                 particle_physics
                                 social_anthropology)],
                 nameopts => 1);

This would create a list like:

    <select name="department">
    <option value="molecular_biology">Molecular Biology</option>
    <option value="philosophy">Philosophy</option>
    <option value="psychology">Psychology</option>
    <option value="particle_physics">Particle Physics</option>
    <option value="social_anthropology">Social Anthropology</option>
    </select>

Basically, you get names for the options that are determined in 
the same way as the names for the fields. This is designed as
a simpler alternative to using custom C<options> data structures
if your data is regular enough to support it.

=item other => 0 | 1 | \%attr

If set, this automatically creates an "other" field to the right
of the main field. This is very useful if you want to present a
present list, but then also allow the user to enter their own
entry:

    $form->field(name    => 'vote_for_president',
                 options => [qw(Bush Kerry)],
                 other   => 1);

That would generate HTML somewhat like this:

    Vote For President:  [ ] Bush [ ] Kerry [ ] Other: [______]

If the "other" button is checked, then the box becomes editable
so that the user can write in their own text. This "other" box
will be subject to the same validation as the main field, to
make sure your data for that field is consistent.

=item options => \@options | \%options | \&sub

This takes an arrayref of options. It also automatically results
in the field becoming a radio (if < 5) or select list (if >= 5),
unless you explicitly set the type with the C<type> parameter:

    $form->field(name => 'opinion',
                 options => [qw(yes no maybe so)]);

From that, you will get something like this:

    <select name="opinion">
    <option value="yes">yes</option>
    <option value="no">no</option>
    <option value="maybe">maybe</option>
    <option value="so">so</option>
    </select>

Also, this can accept more complicated data structures, allowing you to 
specify different labels and values for your options. If a given item
is either an arrayref or hashref, then the first element will be
taken as the value and the second as the label. For example, this:

    push @opt, ['yes', 'You betcha!'];
    push @opt, ['no', 'No way Jose'];
    push @opt, ['maybe', 'Perchance...'];
    push @opt, ['so', 'So'];
    $form->field(name => 'opinion', options => \@opt);

Would result in something like the following:

    <select name="opinion">
    <option value="yes">You betcha!</option>
    <option value="no">No way Jose</option>
    <option value="maybe">Perchance...</option>
    <option value="so">So</option>
    </select>

And this code would have the same effect:

    push @opt, { yes => 'You betcha!' };
    push @opt, { no  => 'No way Jose' };
    push @opt, { maybe => 'Perchance...' };
    push @opt, { so  => 'So' };
    $form->field(name => 'opinion', options => \@opt);

Finally, you can specify a C<\&sub> which must return either
an C<\@arrayref> or C<\%hashref> of data, which is then expanded
using the same algorithm.

=item optgroups => 0 | 1 | \%hashref

If C<optgroups> is specified for a field (C<select> fields
only), then the above C<options> array is parsed so that the
third argument is taken as the name of the optgroup, and an 
C<< <optgroup> >> tag is generated appropriately.

An example will make this behavior immediately obvious:

  my $opts = $dbh->selectall_arrayref(
                "select id, name, category from software
                 order by category, name"
              );

  $form->field(name => 'software_title',
               options => $opts,
               optgroups => 1);

The C<optgroups> setting would then parse the third element of
C<$opts> so that you'd get an C<optgroup> every time that
"category" changed:

  <optgroup label="antivirus">
     <option value="12">Norton Anti-virus 1.2</option>
     <option value="11">McAfee 1.1</option>
  </optgroup>
  <optgroup label="office">
     <option value="3">Microsoft Word</option>
     <option value="4">Open Office</option>
     <option value="6">WordPerfect</option>
  </optgroup>

In addition, if C<optgroups> is instead a hashref, then the
name of the optgroup is gotten from that. Using the above example,
this would help if you had the category name in a separate table,
and were just storing the C<category_id> in the C<software> table.
You could provide an C<optgroups> hash like:

    my %optgroups = (
        1   =>  'antivirus',
        2   =>  'office',
        3   =>  'misc',
    );
    $form->field(..., optgroups => \%optgroups);

Note: No attempt is made by B<FormBuilder> to properly sort
your option optgroups - it is up to you to provide them in a
sensible order.

=item required => 0 | 1

If set to 1, the field must be filled in:

    $form->field(name => 'email', required => 1);

This is rarely useful - what you probably want are the C<validate>
and C<required> options to C<new()>.

=item selectname => 0 | 1 | $string

By default, this is set to C<1> and any single-select lists are
prefixed by the message C<form_select_default> ("-select-" for
English). If set to C<0>, then this string is not prefixed.
If set to a C<$string>, then that string is used explicitly.

Philosophically, the "-select-" behavior is intentional because
it allows a null item to be transmitted (the same as not checking
any checkboxes or radio buttons). Otherwise, the first item in a
select list is automatically sent when the form is submitted.
If you would like an item to be "pre-selected", consider using
the C<value> option to specify the default value.

=item sortopts => BUILTIN | 1 | \&sub

If set, and there are options, then the options will be sorted 
in the specified order. There are four possible values for the
C<BUILTIN> setting:

    NAME            Sort option values by name
    NUM             Sort option values numerically
    LABELNAME       Sort option labels by name
    LABELNUM        Sort option labels numerically

For example:

    $form->field(name => 'category',
                 options => \@cats,
                 sortopts => 'NAME');

Would sort the C<@cats> options in alphabetic (C<NAME>) order.
The option C<NUM> would sort them in numeric order. If you 
specify "1", then an alphabetic sort is done, just like the
default Perl sort.

In addition, you can specify a sub reference which takes pairs
of values to compare and returns the appropriate return value
that Perl C<sort()> expects.

=item type => $type

The type of input box to create. Default is "text", and valid values
include anything allowed by the HTML specs, including "select",
"radio", "checkbox", "textarea", "password", "hidden", and so on.

By default, the type is automatically determined by B<FormBuilder>
based on the following algorithm:

    Field options?
        No = text (done)
        Yes:
            Less than 'selectnum' setting?
                No = select (done)
                Yes:
                    Is the 'multiple' option set?
                    Yes = checkbox (done)
                    No:
                        Have just one single option?
                            Yes = checkbox (done)
                            No = radio (done)

I recommend you let B<FormBuilder> do this for you in most cases,
and only tweak those you really need to.

=item value => $value | \@values

The C<value> option can take either a single value or an arrayref
of multiple values. In the case of multiple values, this will
result in the field automatically becoming a multiple select list
or radio group, depending on the number of options specified.

B<If a CGI value is present it will always win.> To forcibly change
a value, you need to specify the C<force> option:

    # Example that hides credit card on confirm screen
    if ($form->submitted && $form->validate) {
        my $val = $form->field;

        # hide CC number
        $form->field(name => 'credit_card',
                     value => '(not shown)',
                     force => 1);

        print $form->confirm;
    }

This would print out the string "(not shown)" on the C<confirm()>
screen instead of the actual number.

=item validate => '/regex/'

Similar to the C<validate> option used in C<new()>, this affects
the validation just of that single field. As such, rather than
a hashref, you would just specify the regex to match against.

B<This regex must be specified as a single-quoted string, and
NOT as a qr// regex>. The reason for this is it needs to be
usable by the JavaScript routines as well.

=item $htmlattr => $htmlval

In addition to the above tags, the C<field()> function can take
any other valid HTML attribute, which will be placed in the tag
verbatim. For example, if you wanted to alter the class of the
field (if you're using stylesheets and a template, for example),
you could say:

    $form->field(name => 'email', class => 'FormField',
                 size => 80);

Then when you call C<$form->render> you would get a field something
like this:

    <input type="text" name="email" class="FormField" size="80">

(Of course, for this to really work you still have to create a class
called C<FormField> in your stylesheet.)

See also the C<fieldattr> option which provides global attributes
to all fields.

=back

=head2 cgi_param()

The above C<field()> method will only return fields which you have
I<explicitly> defined in your form. Excess parameters will be silently
ignored, to help ensure users can't mess with your form. 

But, you may have some times when you want extra params so that
you can maintain state, but you don't want it to appear in your
form. Branding is an easy example:

    http://hr-outsourcing.com/newuser.cgi?company=mr_propane

This could change your page's HTML so that it displayed the
appropriate company name and logo, without polluting your
form parameters.

This call simply redispatches to C<CGI.pm>'s C<param()> method,
so consult those docs for more information.

=head2 tmpl_param()

This allows you to manipulate template parameters directly.
Extending the above example:

    my $form = CGI::FormBuilder->new(template => 'some.tmpl');

    my $company = $form->cgi_param('company');
    $form->tmpl_param(company => $company);

Then, in your template:

    Hello, <tmpl_var company> employee!
    <p>
    Please fill out this form:
    <tmpl_var form-start>
    <!-- etc... -->

For really precise template control, you can actually create your
own template object and then pass it directly to B<FormBuilder>.
See L<CGI::FormBuilder::Template> for more details.

=head2 sessionid()

This gets and sets the sessionid, which is stored in the special
form field C<_sessionid>. By default no session ids are generated
or used. Rather, this is intended to provide a hook for you to 
easily integrate this with a session id module like C<CGI::Session>.

Since you can set the session id via the C<_sessionid> field, you
can pass it as an argument when first showing the form:

    http://mydomain.com/forms/update_info.cgi?_sessionid=0123-091231

This would set things up so that if you called:

    my $id = $form->sessionid;

This would get the value C<0123-091231> in your script. Conversely,
if you generate a new sessionid on your own, and wish to include it
automatically, simply set is as follows:

    $form->sessionid($id);

If the sessionid is set, and C<header> is set, then B<FormBuilder>
will also automatically generate a cookie for you.

See L</"EXAMPLES"> for C<CGI::Session> example.

=head2 submitted()

This returns the value of the "Submit" button if the form has been
submitted, undef otherwise. This allows you to either test it in
a boolean context:

    if ($form->submitted) { ... }

Or to retrieve the button that was actually clicked on in the
case of multiple submit buttons:

    if ($form->submitted eq 'Update') {
        ...
    } elsif ($form->submitted eq 'Delete') {
        ...
    }

It's best to call C<validate()> in conjunction with this to make
sure the form validation works. To make sure you're getting accurate
info, it's recommended that you name your forms with the C<name>
option described above.

If you're writing a multiple-form app, you should name your forms
with the C<name> option to ensure that you are getting an accurate
return value from this sub. See the C<name> option above, under
C<render()>.

You can also specify the name of an optional field which you want to
"watch" instead of the default C<_submitted> hidden field. This is useful
if you have a search form and also want to be able to link to it from
other documents directly, such as:

    mysearch.cgi?lookup=what+to+look+for

Normally, C<submitted()> would return false since the C<_submitted>
field is not included. However, you can override this by saying:

    $form->submitted('lookup');

Then, if the lookup field is present, you'll get a true value.
(Actually, you'll still get the value of the "Submit" button if
present.)

=head2 validate()

This validates the form based on the validation criteria passed
into C<new()> via the C<validate> option. In addition, you can
specify additional criteria to check that will be valid for just
that call of C<validate()>. This is useful is you have to deal
with different geos:

    if ($location eq 'US') {
        $form->validate(state => 'STATE', zipcode => 'ZIPCODE');
    } else {
        $form->validate(state => '/^\w{2,3}$/');
    }

You can also provide a L<Data::FormValidator> object as the first
argument. In that case, the second argument (if present) will be
interpreted as the name of the validation profile to use. A single
string argument will also be interpreted as a validation profile
name.

Note that if you pass args to your C<validate()> function like
this, you will not get JavaScript generated or required fields
placed in bold. So, this is good for conditional validation
like the above example, but for most applications you want to
pass your validation requirements in via the C<validate>
option to the C<new()> function, and just call the C<validate()>
function with no arguments.

=head2 confirm()

The purpose of this function is to print out a static confirmation
screen showing a short message along with the values that were
submitted. It is actually just a special wrapper around C<render()>,
twiddling a couple options.

If you're using templates, you probably want to specify a separate
success template, such as:

    if ($form->submitted && $form->validate) {
        print $form->confirm(template => 'success.tmpl');
    } else {
        print $form->render(template => 'fillin.tmpl');
    }

So that you don't get the same screen twice.

=head2 mailconfirm()

This sends a confirmation email to the named addresses. The C<to>
argument is required; everything else is optional. If no C<from>
is specified then it will be set to the address C<auto-reply>
since that is a common quasi-standard in the web app world.

This does not send any of the form results. Rather, it simply
prints out a message saying the submission was received.

=head2 mailresults()

This emails the form results to the specified address(es). By 
default it prints out the form results separated by a colon, such as:

    name: Nate Wiger
    email: nate@wiger.org
    colors: red green blue

And so on. You can change this by specifying the C<delimiter> and
C<joiner> options. For example this:

    $form->mailresults(to => $to, delimiter => '=', joiner => ',');

Would produce an email like this:

    name=Nate Wiger
    email=nate@wiger.org
    colors=red,green,blue

Note that now the last field ("colors") is separated by commas since
you have multiple values and you specified a comma as your C<joiner>.

=head2 mailresults() with plugin

Now you can also specify a plugin to use with mailresults, in
the namespace C<CGI::FormBuilder::Mail::*>.  These plugins may
depend on other libraries.  For example, this:

    $form->mailresults(
        plugin          => 'FormatMultiPart',
        from            => 'Mark Hedges <hedges@ucsd.edu>',
        to              => 'Nate Wiger <nwiger@gmail.com>',
        smtp            => $smtp_host_or_ip,
        format          => 'plain',
    );

will send your mail formatted nicely in text using C<Text::FormatTable>.
(And if you used format => 'html' it would use C<HTML::QuickTable>.)

This particular plugin uses C<MIME::Lite> and C<Net::SMTP> to communicate
directly with the SMTP server, and does not rely on a shell escape.
See L<CGI::FormBuilder::Mail::FormatMultiPart> for more information.

This establishes a simple mail plugin implementation standard 
for your own mailresults() plugins.  The plugin should reside 
under the C<CGI::FormBuilder::Mail::*> namespace. It should have
a constructor new() which accepts a hash-as-array of named arg
parameters, including form => $form.  It should have a mailresults()
object method that does the right thing.  It should use 
C<CGI::FormBuilder::Util> and puke() if something goes wrong.

Calling $form->mailresults( plugin => 'Foo', ... ) will load
C<CGI::FormBuilder::Mail::Foo> and will pass the FormBuilder object
as a named param 'form' with all other parameters passed intact.

If it should croak, confess, die or otherwise break if something
goes wrong, FormBuilder.pm will warn any errors and the built-in
mailresults() method will still try.

=head2 mail()

This is a more generic version of the above; it sends whatever is
given as the C<text> argument via email verbatim to the C<to> address.
In addition, if you're not running C<sendmail> you can specify the
C<mailer> parameter to give the path of your mailer. This option
is accepted by the above functions as well.

=head1 COMPATIBILITY

The following methods are provided to make B<FormBuilder> behave more
like other modules, when desired.

=head2 header()

Returns a C<CGI.pm> header, but only if C<< header => 1 >> is set.

=head2 param()

This is an alias for C<field()>, provided for compatibility. However,
while C<field()> I<does> act "compliantly" for easy use in C<CGI::Session>,
C<Apache::Request>, etc, it is I<not> 100% the same. As such, I recommend
you use C<field()> in your code, and let receiving objects figure the
C<param()> thing out when needed:

    my $sess = CGI::Session->new(...);
    $sess->save_param($form);   # will see param()

=head2 query_string()

This returns a query string similar to C<CGI.pm>, but B<ONLY> containing
form fields and any C<keepextras>, if specified. Other params are ignored.

=head2 self_url()

This returns a self url, similar to C<CGI.pm>, but again B<ONLY> with
form fields.

=head2 script_name()

An alias for C<< $form->action >>.

=head1 STYLESHEETS (CSS)

If the C<stylesheet> option is enabled (by setting it to 1 or the 
path of a CSS file), then B<FormBuilder> will automatically output
style classes for every single form element:

    fb              main form table
    fb_label        td containing field label
    fb_field        td containing field input tag
    fb_submit       td containing submit button(s)

    fb_input        input types
    fb_select       select types
    fb_checkbox     checkbox types
    fb_radio        radio types
    fb_option       labels for checkbox/radio options
    fb_button       button types
    fb_hidden       hidden types
    fb_static       static types

    fb_required     span around labels for required fields
    fb_invalid      span around labels for invalid fields
    fb_comment      span around field comment
    fb_error        span around field error message

Here's a simple example that you can put in C<fb.css> which spruces
up a couple basic form features:

    /* FormBuilder */
    .fb {
        background: #ffc;
        font-family: verdana,arial,sans-serif;
        font-size: 10pt;
    }

    .fb_label {
        text-align: right;
        padding-right: 1em;
    }

    .fb_comment {
        font-size: 8pt;
        font-style: italic;
    }

    .fb_submit {
        text-align: center;
    }

    .fb_required {
        font-weight: bold;
    }

    .fb_invalid {
        color: #c00;
        font-weight: bold;
    }

    .fb_error {
        color: #c00;
        font-style: italic;
    }

Of course, if you're familiar with CSS, you know alot more is possible.
Also, you can mess with all the id's (if you name your forms) to
manipulate fields more exactly.

=head1 EXAMPLES

I find this module incredibly useful, so here are even more examples,
pasted from sample code that I've written:

=head2 Ex1: order.cgi

This example provides an order form, complete with validation of the
important fields, and a "Cancel" button to abort the whole thing.

    #!/usr/bin/perl

    use strict;
    use CGI::FormBuilder;

    my @states = my_state_list();   # you write this

    my $form = CGI::FormBuilder->new(
                    method => 'post',
                    fields => [
                        qw(first_name last_name
                           email send_me_emails
                           address state zipcode
                           credit_card expiration)
                    ],

                    header => 1,
                    title  => 'Finalize Your Order',
                    submit => ['Place Order', 'Cancel'],
                    reset  => 0,

                    validate => {
                         email   => 'EMAIL',
                         zipcode => 'ZIPCODE',
                         credit_card => 'CARD',
                         expiration  => 'MMYY',
                    },
                    required => 'ALL',
                    jsfunc => <<EOJS,
    // skip js validation if they clicked "Cancel"
    if (this._submit.value == 'Cancel') return true;
EOJS
               );

    # Provide a list of states
    $form->field(name    => 'state',
                 options => \@states,
                 sortopts=> 'NAME');

    # Options for mailing list
    $form->field(name    => 'send_me_emails',
                 options => [[1 => 'Yes'], [0 => 'No']],
                 value   => 0);   # "No"

    # Check for valid order
    if ($form->submitted eq 'Cancel') {
        # redirect them to the homepage
        print $form->cgi->redirect('/');
        exit; 
    }
    elsif ($form->submitted && $form->validate) {
        # your code goes here to do stuff...
        print $form->confirm;
    }
    else {
        # either first printing or needs correction
        print $form->render;
    }

This will create a form called "Finalize Your Order" that will provide a
pulldown menu for the C<state>, a radio group for C<send_me_emails>, and
normal text boxes for the rest. It will then validate all the fields,
using specific patterns for those fields specified to C<validate>.

=head2 Ex2: order_form.cgi

Here's an example that adds some fields dynamically, and uses the
C<debug> option spit out gook:

    #!/usr/bin/perl

    use strict;
    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(
                    method => 'post',
                    fields => [
                        qw(first_name last_name email
                           address state zipcode)
                    ],
                    header => 1,
                    debug  => 2,    # gook
                    required => 'NONE',
               );

    # This adds on the 'details' field to our form dynamically
    $form->field(name => 'details',
                 type => 'textarea',
                 cols => '50',
                 rows => '10');

    # And this adds user_name with validation
    $form->field(name  => 'user_name',
                 value => $ENV{REMOTE_USER},
                 validate => 'NAME');

    if ($form->submitted && $form->validate) {
        # ... more code goes here to do stuff ...
        print $form->confirm;
    } else {
        print $form->render;
    }

In this case, none of the fields are required, but the C<user_name>
field will still be validated if filled in.

=head2 Ex3: ticket_search.cgi

This is a simple search script that uses a template to layout 
the search parameters very precisely. Note that we set our
options for our different fields and types.

    #!/usr/bin/perl

    use strict;
    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(
                    fields => [qw(type string status category)],
                    header => 1,
                    template => 'ticket_search.tmpl',
                    submit => 'Search',     # search button
                    reset  => 0,            # and no reset
               );

    # Need to setup some specific field options
    $form->field(name    => 'type',
                 options => [qw(ticket requestor hostname sysadmin)]);

    $form->field(name    => 'status',
                 type    => 'radio',
                 options => [qw(incomplete recently_completed all)],
                 value   => 'incomplete');

    $form->field(name    => 'category',
                 type    => 'checkbox',
                 options => [qw(server network desktop printer)]);

    # Render the form and print it out so our submit button says "Search"
    print $form->render;

Then, in our C<ticket_search.tmpl> HTML file, we would have something like this:

    <html>
    <head>
      <title>Search Engine</title>
      <tmpl_var js-head>
    </head>
    <body bgcolor="white">
    <center>
    <p>
    Please enter a term to search the ticket database.
    <p>
    <tmpl_var form-start>
    Search by <tmpl_var field-type> for <tmpl_var field-string>
    <tmpl_var form-submit>
    <p>
    Status: <tmpl_var field-status>
    <p>
    Category: <tmpl_var field-category>
    <p>
    </form>
    </body>
    </html>

That's all you need for a sticky search form with the above HTML layout.
Notice that you can change the HTML layout as much as you want without
having to touch your CGI code.

=head2 Ex4: user_info.cgi

This script grabs the user's information out of a database and lets
them update it dynamically. The DBI information is provided as an
example, your mileage may vary:

    #!/usr/bin/perl

    use strict;
    use CGI::FormBuilder;
    use DBI;
    use DBD::Oracle

    my $dbh = DBI->connect('dbi:Oracle:db', 'user', 'pass');

    # We create a new form. Note we've specified very little,
    # since we're getting all our values from our database.
    my $form = CGI::FormBuilder->new(
                    fields => [qw(username password confirm_password
                                  first_name last_name email)]
               );

    # Now get the value of the username from our app
    my $user = $form->cgi_param('user');
    my $sth = $dbh->prepare("select * from user_info where user = '$user'");
    $sth->execute;
    my $default_hashref = $sth->fetchrow_hashref;

    # Render our form with the defaults we got in our hashref
    print $form->render(values => $default_hashref,
                        title  => "User information for '$user'",
                        header => 1);

=head2 Ex5: add_part.cgi

This presents a screen for users to add parts to an inventory database.
Notice how it makes use of the C<sticky> option. If there's an error,
then the form is presented with sticky values so that the user can
correct them and resubmit. If the submission is ok, though, then the
form is presented without sticky values so that the user can enter
the next part.

    #!/usr/bin/perl

    use strict;
    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(
                    method => 'post',
                    fields => [qw(sn pn model qty comments)],
                    labels => {
                        sn => 'Serial Number',
                        pn => 'Part Number'
                    },
                    sticky => 0,
                    header => 1,
                    required => [qw(sn pn model qty)],
                    validate => {
                         sn  => '/^[PL]\d{2}-\d{4}-\d{4}$/',
                         pn  => '/^[AQM]\d{2}-\d{4}$/',
                         qty => 'INT'
                    },
                    font => 'arial,helvetica'
               );

    # shrink the qty field for prettiness, lengthen model
    $form->field(name => 'qty',   size => 4);
    $form->field(name => 'model', size => 60);

    if ($form->submitted) {
        if ($form->validate) {
            # Add part to database
        } else {
            # Invalid; show form and allow corrections
            print $form->render(sticky => 1);
            exit;
        }
    }

    # Print form for next part addition.
    print $form->render;

With the exception of the database code, that's the whole application.

=head2 Ex6: Session Management

This creates a session via C<CGI::Session>, and ties it in with B<FormBuilder>:

    #!/usr/bin/perl

    use CGI::Session;
    use CGI::FormBuilder;

    my $form = CGI::FormBuilder->new(fields => \@fields);

    # Initialize session
    my $session = CGI::Session->new('driver:File',
                                    $form->sessionid,
                                    { Directory=>'/tmp' });

    if ($form->submitted && $form->validate) {
        # Automatically save all parameters
        $session->save_param($form);
    }

    # Ensure we have the right sessionid (might be new)
    $form->sessionid($session->id);

    print $form->render;

Yes, it's pretty much that easy. See L<CGI::FormBuilder::Multi> for
how to tie this into a multi-page form.

=head1 FREQUENTLY ASKED QUESTIONS (FAQ)

There are a couple questions and subtle traps that seem to poke people
on a regular basis. Here are some hints.

=head2 I'm confused. Why doesn't this work like CGI.pm?

If you're used to C<CGI.pm>, you have to do a little bit of a brain
shift when working with this module.

B<FormBuilder> is designed to address fields as I<abstract entities>.
That is, you don't create a "checkbox" or "radio group" per se.
Instead, you create a field for the data you want to collect.
The HTML representation is just one property of this field.

So, if you want a single-option checkbox, simply say something
like this:

    $form->field(name    => 'join_mailing_list',
                 options => ['Yes']);

If you want it to be checked by default, you add the C<value> arg:

    $form->field(name    => 'join_mailing_list',
                 options => ['Yes'],
                 value   => 'Yes');

You see, you're creating a field that has one possible option: "Yes".
Then, you're saying its current value is, in fact, "Yes". This will
result in B<FormBuilder> creating a single-option field (which is
a checkbox by default) and selecting the requested value (meaning
that the box will be checked).

If you want multiple values, then all you have to do is specify
multiple options:

    $form->field(name    => 'join_mailing_list',
                 options => ['Yes', 'No'],
                 value   => 'Yes');

Now you'll get a radio group, and "Yes" will be selected for you!
By viewing fields as data entities (instead of HTML tags) you
get much more flexibility and less code maintenance. If you want
to be able to accept multiple values, simply use the C<multiple> arg:

    $form->field(name     => 'favorite_colors',
                 options  => [qw(red green blue)],
                 multiple => 1);

In all of these examples, to get the data back you just use the
C<field()> method:

    my @colors = $form->field('favorite_colors');

And the rest is taken care of for you.

=head2 How do I make a multi-screen/multi-mode form?

This is easily doable, but you have to remember a couple things. Most
importantly, that B<FormBuilder> only knows about those fields you've
told it about. So, let's assume that you're going to use a special
parameter called C<mode> to control the mode of your application so
that you can call it like this:

    myapp.cgi?mode=list&...
    myapp.cgi?mode=edit&...
    myapp.cgi?mode=remove&...

And so on. You need to do two things. First, you need the C<keepextras>
option:

    my $form = CGI::FormBuilder->new(..., keepextras => 1);

This will maintain the C<mode> field as a hidden field across requests
automatically. Second, you need to realize that since the C<mode> is
not a defined field, you have to get it via the C<cgi_param()> method:

    my $mode = $form->cgi_param('mode');

This will allow you to build a large multiscreen application easily,
even integrating it with modules like C<CGI::Application> if you want.

You can also do this by simply defining C<mode> as a field in your
C<fields> declaration. The reason this is discouraged is because
when iterating over your fields you'll get C<mode>, which you likely
don't want (since it's not "real" data).

=head2 Why won't CGI::FormBuilder work with post requests?

It will, but chances are you're probably doing something like this:

    use CGI qw(:standard);
    use CGI::FormBuilder;

    # Our "mode" parameter determines what we do
    my $mode = param('mode');

    # Change our form based on our mode
    if ($mode eq 'view') {
        my $form = CGI::FormBuilder->new(
                        method => 'post',
                        fields => [qw(...)],
                   );
    } elsif ($mode eq 'edit') {
        my $form = CGI::FormBuilder->new(
                        method => 'post',
                        fields => [qw(...)],
                   );
    }

The problem is this: Once you read a C<post> request, it's gone
forever. In the above code, what you're doing is having C<CGI.pm>
read the C<post> request (on the first call of C<param()>).

Luckily, there is an easy solution. First, you need to modify
your code to use the OO form of C<CGI.pm>. Then, simply specify
the C<CGI> object you create to the C<params> option of B<FormBuilder>:

    use CGI;
    use CGI::FormBuilder;

    my $cgi = CGI->new;

    # Our "mode" parameter determines what we do
    my $mode = $cgi->param('mode');

    # Change our form based on our mode
    # Note: since it is post, must specify the 'params' option
    if ($mode eq 'view') {
        my $form = CGI::FormBuilder->new(
                        method => 'post',
                        fields => [qw(...)],
                        params => $cgi      # get CGI params
                   );
    } elsif ($mode eq 'edit') {
        my $form = CGI::FormBuilder->new(
                        method => 'post',
                        fields => [qw(...)],
                        params => $cgi      # get CGI params
                   );
    }

Or, since B<FormBuilder> gives you a C<cgi_param()> function, you
could also modify your code so you use B<FormBuilder> exclusively,
as in the previous question.

=head2 How can I change option XXX based on a conditional?

To change an option, simply use its accessor at any time:

    my $form = CGI::FormBuilder->new(
                    method => 'post',
                    fields => [qw(name email phone)]
               );

    my $mode = $form->cgi_param('mode');

    if ($mode eq 'add') {
        $form->title('Add a new entry');
    } elsif ($mode eq 'edit') {
        $form->title('Edit existing entry');

        # do something to select existing values
        my %values = select_values();

        $form->values(\%values);
    }
    print $form->render;

Using the accessors makes permanent changes to your object, so
be aware that if you want to reset something to its original
value later, you'll have to first save it and then reset it:

    my $style = $form->stylesheet;
    $form->stylesheet(0);       # turn off
    $form->stylesheet($style);  # original setting

You can also specify options to C<render()>, although using the
accessors is the preferred way.

=head2 How do I manually override the value of a field?

You must specify the C<force> option:

    $form->field(name  => 'name_of_field',
                 value => $value,
                 force => 1);

If you don't specify C<force>, then the CGI value will always win.
This is because of the stateless nature of the CGI protocol.

=head2 How do I make it so that the values aren't shown in the form?

Turn off sticky:

    my $form = CGI::FormBuilder->new(... sticky => 0);

By turning off the C<sticky> option, you will still be able to access
the values, but they won't show up in the form.

=head2 I can't get "validate" to accept my regular expressions!

You're probably not specifying them within single quotes. See the
section on C<validate> above.

=head2 Can FormBuilder handle file uploads?

It sure can, and it's really easy too. Just change the C<enctype>
as an option to C<new()>:

    use CGI::FormBuilder;
    my $form = CGI::FormBuilder->new(
                    enctype => 'multipart/form-data',
                    method  => 'post',
                    fields  => [qw(filename)]
               );

    $form->field(name => 'filename', type => 'file');

And then get to your file the same way as C<CGI.pm>:

    if ($form->submitted) {
        my $file = $form->field('filename');

        # save contents in file, etc ...
        open F, ">$dir/$file" or die $!;
        while (<$file>) {
            print F;
        }
        close F;

        print $form->confirm(header => 1);
    } else {
        print $form->render(header => 1);
    }

In fact, that's a whole file upload program right there.

=head1 REFERENCES

This really doesn't belong here, but unfortunately many people are
confused by references in Perl. Don't be - they're not that tricky.
When you take a reference, you're basically turning something into
a scalar value. Sort of. You have to do this if you want to pass
arrays intact into functions in Perl 5.

A reference is taken by preceding the variable with a backslash (\).
In our examples above, you saw something similar to this:

    my @fields = ('name', 'email');   # same as = qw(name email)

    my $form = CGI::FormBuilder->new(fields => \@fields);

Here, C<\@fields> is a reference. Specifically, it's an array
reference, or "arrayref" for short.

Similarly, we can do the same thing with hashes:

    my %validate = (
        name  => 'NAME';
        email => 'EMAIL',
    );

    my $form = CGI::FormBuilder->new( ... validate => \%validate);

Here, C<\%validate> is a hash reference, or "hashref".

Basically, if you don't understand references and are having trouble
wrapping your brain around them, you can try this simple rule: Any time
you're passing an array or hash into a function, you must precede it
with a backslash. Usually that's true for CPAN modules.

Finally, there are two more types of references: anonymous arrayrefs
and anonymous hashrefs. These are created with C<[]> and C<{}>,
respectively. So, for our purposes there is no real difference between
this code:

    my @fields = qw(name email);
    my %validate = (name => 'NAME', email => 'EMAIL');

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    validate => \%validate
               );

And this code:

    my $form = CGI::FormBuilder->new(
                    fields   => [ qw(name email) ],
                    validate => { name => 'NAME', email => 'EMAIL' }
               );

Except that the latter doesn't require that we first create 
C<@fields> and C<%validate> variables.

=head1 ENVIRONMENT VARIABLES

=head2 FORMBUILDER_DEBUG

This toggles the debug flag, so that you can control FormBuilder
debugging globally. Helpful in mod_perl.

=head1 NOTES

Parameters beginning with a leading underscore are reserved for
future use by this module. Use at your own peril.

The C<field()> method has the alias C<param()> for compatibility
with other modules, allowing you to pass a C<$form> around just
like a C<$cgi> object.

The output of the HTML generated natively may change slightly from
release to release. If you need precise control, use a template.

Every attempt has been made to make this module taint-safe (-T).
However, due to the way tainting works, you may run into the
message "Insecure dependency" or "Insecure $ENV{PATH}". If so,
make sure you are setting C<$ENV{PATH}> at the top of your script.

=head1 ACKNOWLEDGEMENTS

This module has really taken off, thanks to very useful input, bug
reports, and encouraging feedback from a number of people, including:

    Norton Allen
    Mark Belanger
    Peter Billam
    Brad Bowman
    Jonathan Buhacoff
    Godfrey Carnegie
    Jakob Curdes
    Laurent Dami
    Bob Egert
    Peter Eichman
    Adam Foxson
    Jorge Gonzalez
    Florian Helmberger
    Mark Hedges
    Mark Houliston
    Robert James Kaes
    Dimitry Kharitonov
    Randy Kobes
    William Large
    Kevin Lubic
    Robert Mathews
    Mehryar
    Klaas Naajikens
    Koos Pol
    Shawn Poulson
    Dan Collis Puro
    David Siegal
    Stephan Springl
    Ryan Tate
    John Theus
    Remi Turboult
    Andy Wardley
    Raphael Wegmann
    Emanuele Zeppieri

Thanks!

=head1 SEE ALSO

L<CGI::FormBuilder::Template>, L<CGI::FormBuilder::Messages>, 
L<CGI::FormBuilder::Multi>, L<CGI::FormBuilder::Source::File>,
L<CGI::FormBuilder::Field>, L<CGI::FormBuilder::Util>,
L<CGI::FormBuilder::Util>, L<HTML::Template>, L<Text::Template>
L<CGI::FastTemplate>

=head1 REVISION

$Id: FormBuilder.pm 66 2006-09-07 18:14:17Z nwiger $

=head1 AUTHOR

Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
