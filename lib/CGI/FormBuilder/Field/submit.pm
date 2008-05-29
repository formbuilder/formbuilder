
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

# Create <submit> fields

package CGI::FormBuilder::Field::submit;

use strict;
use warnings;
no  warnings 'uninitialized';

# rendered just like a text field (ala button)

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

our $REVISION = do { (my $r='$Revision: 80 $') =~ s/\D+//g; $r };
our $VERSION = '3.0501';

sub script { '' }

1;

__END__

