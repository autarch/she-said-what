package SSW::Saying;

use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use File::Basename qw( basename );
use File::Slurp qw( read_file write_file );
use SSW::Types qw( NonEmptySimpleStr NonEmptyStr );

use Moose;
use MooseX::StrictConstructor;

has _datetime =>
    ( is       => 'ro',
      isa      => 'DateTime',
      required => 1,
      init_arg => 'datetime',
    );

has date =>
    ( is       => 'ro',
      isa      => NonEmptySimpleStr,
      lazy     => 1,
      builder  => '_build_date',
      init_arg => undef,
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

sub new_from_file
{
    my $class = shift;
    my $file  = shift;

    my $dt = DateTime::Format::ISO8601->parse_datetime( $file->basename() )
        or die "$file name is not a datetime";

    $dt->set_time_zone('UTC');

    my $content = read_file( $file->stringify() );
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

sub is_saying_file
{
    my $class = shift;
    my $file  = shift;

    return $file->basename() =~ /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d/;
}

sub write_to_dir
{
    my $self = shift;
    my $dir  = shift;

    my $file = join q{/}, $dir, $self->_datetime()->iso8601();

    my $content = $self->quote();

    if ( $self->has_commentary() )
    {
        $content .= "\n";
        $content .= $self->commentary();
    }

    write_file( $file, $content );
}

sub _build_date
{
    my $self = shift;

    return $self->_datetime()->clone()->set_time_zone('America/Chicago')->strftime( '%b %{day}, %Y' );
}

no Moose;

1;

