package SSW::Types::Custom;

use strict;
use warnings;

use MooseX::Types
    -declare => [ qw( Dir
                    )
                ];
use MooseX::Types::Moose qw( Str );
use MooseX::Types::Path::Class ();

subtype Dir,
    as      'Path::Class::Dir',
    where   { -d $_ },
    message { "$_ is not a directory" };

coerce Dir,
    from Str,
    via  { Path::Class::Dir->new($_) };

1;
