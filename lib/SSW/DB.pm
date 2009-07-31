package SSW::DB;

use strict;
use warnings;

use Path::Class qw( file );
use SSW::Saying;
use SSW::Types qw( Dir ArrayRef );

use Moose;
use MooseX::AttributeHelpers;
use MooseX::StrictConstructor;

has dir =>
    ( is       => 'ro',
      isa      => 'Path::Class::Dir',
      coerce   => 1,
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
    my $self = shift;

    my $dir = $self->dir();

    my @sayings;
    for my $file ( map { file($_) } grep { -f } sort { $b cmp $a } glob "$dir/[0-9]*" )
    {
        next unless SSW::Saying->is_saying_file($file);

        push @sayings, SSW::Saying->new_from_file($file);
    }

    return \@sayings,
}

no Moose;

1;
