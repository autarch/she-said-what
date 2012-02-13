package SSW::Types;

use strict;
use warnings;

use base 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        SSW::Types::Custom
        MooseX::Types::Common::String
        MooseX::Types::Moose
        )
);

1;
