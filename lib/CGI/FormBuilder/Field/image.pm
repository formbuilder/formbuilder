
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Field::image;

use strict;
use warnings;
no  warnings 'uninitialized';
# image fields are rendered exactly like text fields

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';

our $REVISION = do { (my $r='$Revision: 100 $') =~ s/\D+//g; $r };
our $VERSION = '3.06';

1;

__END__

