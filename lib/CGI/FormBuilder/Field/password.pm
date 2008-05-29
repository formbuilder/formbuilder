
###########################################################################
# Copyright (c) 2000-2006 Nate Wiger <nate@wiger.org>. All Rights Reserved.
# Please visit www.formbuilder.org for tutorials, support, and examples.
###########################################################################

# password fields look like text fields

package CGI::FormBuilder::Field::password;

use strict;

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

our $REVISION = do { (my $r='$Revision: 66 $') =~ s/\D+//g; $r };
our $VERSION = '3.0401';

1;

__END__

