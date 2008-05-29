
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

# Create <button> fields

package CGI::FormBuilder::Field::button;

use strict;

# hidden and password fields are rendered exactly like text fields

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

our $REVISION = do { (my $r='$Revision: 61 $') =~ s/\D+//g; $r };
our $VERSION = '3.04';

1;

__END__

