package SSW::Types::Custom;

use strict;
use warnings;

use MooseX::Types
    -declare => [ qw( Dir
                    )
                ];
use MooseX::Types::Moose qw( Str );

subtype Dir,
    as      Str,
    where   { -d },
    message { "$_ is not a directory" };

1;
