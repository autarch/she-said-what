package SSW::Saying;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use File::Basename qw( basename );
use File::Slurp qw( read_file );
use SSW::Types qw( NonEmptySimpleStr NonEmptyStr );

use Moose;
use MooseX::StrictConstructor;


has datetime =>
    ( is       => 'ro',
      isa      => 'DateTime',
      required => 1,
      handles  => [ 'date' ],
    );

has quote =>
    ( is       => 'ro',
      isa      => NonEmptySimpleStr,
      required => 1,
    );

has commentary =>
    ( is        => 'ro',
      isa       => NonEmptyStr,
      predicate => 'has_commentary',
    );

sub from_file
{
    my $class = shift;
    my $file  = shift;

    my $dt = DateTime::Format::ISO8601->parse_datetime( basename($file) )
        or die "$file name is not a datetime";

    my $content = read_file($file);
    my ( $quote, $commentary ) = split /\n/, $content, 2;

    die "$file contains no quote"
        unless defined $quote && length $quote;

    my %p = ( datetime => $dt,
              quote    => $quote,
            );

    $p{commentary} = $commentary
        if defined $commentary && length $commentary;

    return $class->new(%p);
}

no Moose;

1;

