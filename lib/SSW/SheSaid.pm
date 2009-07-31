package SSW::SheSaid;

use strict;
use warnings;

use SSW::RCFile;
use SSW::Saying;
use SSW::Types qw( NonEmptySimpleStr );

use Moose;
use MooseX::StrictConstructor;

with 'SSW::CLI';

has what =>
    ( is       => 'ro',
      isa      => NonEmptySimpleStr,
      required => 1,
    );

sub run
{
    my $self = shift;

    my ( $quote, $commentary ) = split /\|/, $self->what();
    $commentary =~ s/\|/\n/g
        if defined $commentary;

    my $saying =
        SSW::Saying->new( datetime   => DateTime->now( time_zone => 'UTC' ),
                          quote      => $quote,
                          ( defined $commentary ? ( commentary => $commentary ) : () ),
                        );

    $saying->write_to_dir( $self->db_dir() );
}

no Moose;

1;

