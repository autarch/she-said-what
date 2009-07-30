package SSW::DB;

use strict;
use warnings;

use SSW::Saying;
use SSW::Types qw( Dir ArrayRef );

use Moose;
use MooseX::AttributeHelpers;
use MooseX::StrictConstructor;

has dir =>
    ( is       => 'ro',
      isa      => Dir,
      required => 1,
    );

has _sayings =>
    ( metaclass => 'Collection::Array',
      is        => 'ro',
      isa       => ArrayRef[ 'SSW::Saying' ],
      lazy      => 1,
      builder   => '_build_sayings',
      provides  => { push     => '_add_saying',
                     elements => 'sayings',
                   },
      init_arg  => undef,
    );

sub _build_sayings
{
    return [ SSW::Saying->new( date => DateTime->today( time_zone => 'UTC' ),
                               quote      => 'I like furry meat.',
                               commentary => '... after biting my arm.',
                             ),
             map { SSW::Saying->new( date => DateTime->today( time_zone => 'UTC' ),
                               quote => 'I am crazy.',
                             ) } 1..43,
           ];
}

no Moose;

1;
