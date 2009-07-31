package SSW::GenSite;

use strict;
use warnings;

use Cwd qw( abs_path );
use File::Basename qw( basename );
use File::Copy::Recursive qw( rcopy );
use File::Spec;
use File::Temp qw( tempdir );
use MasonX::StaticBuilder::Component;
use SSW::DB;
use SSW::RCFile;
use SSW::StaticBuilder;
use SSW::Types qw( Dir );

use Moose;
use MooseX::StrictConstructor;

with 'SSW::CLI';

has _builder =>
    ( is       => 'ro',
      isa      => 'SSW::StaticBuilder',
      lazy     => 1,
      default  => sub { SSW::StaticBuilder->new('./share/mason') },
      init_arg => undef,
    );

has _temp_dir =>
   ( is       => 'ro',
      isa      => Dir,
      coerce   => 1,
      lazy     => 1,
      default  => sub { tempdir( CLEANUP => 1 ) },
      init_arg => undef,
    );


sub run
{
    my $self = shift;

    $self->_builder()->write( $self->_temp_dir() );

    for my $dir ( qw( css images js ) )
    {
        $self->_copy_dir( File::Spec->catdir( 'share', $dir ),
                          File::Spec->catdir( $self->_temp_dir(), $dir ),
                        );
    }

    $self->_write_sayings();

    $self->_create_atom();

    $self->_deploy_site();

    print "Deployed site to ", $self->target(), "\n";
}

sub _copy_dir
{
    my $self   = shift;
    my $source = shift;
    my $target = shift;

    rcopy( $source, $target );
}

sub _write_sayings
{
    my $self = shift;

    my $component =
        MasonX::StaticBuilder::Component->new
                ( { comp_root => $self->_builder()->input_dir(),
                    comp_name =>
                    $self->_builder()->_get_comp_name
                        ( abs_path('./share/mason/sayings.html') ),
                  } );

    my @sayings = $self->_db()->sayings();

    my ( $prev, $cur, $next ) = ( undef, 'index.html', 'sayings2.html' );

    while (@sayings)
    {
        my @for_page =
              @sayings >= 10
            ? ( splice @sayings, 0, 10 )
            : ( splice @sayings, 0, scalar @sayings );

        undef $next unless @sayings;

        my $output = $component->fill_in( sayings => \@for_page,
                                          prev    => $prev,
                                          next    => $next,
                                        );

        my $outfile = File::Spec->catfile( $self->_temp_dir(), $cur );
        $self->_builder()->_write_file( $outfile, $output );

        $prev = $cur;
        $cur  = $next;
        $next =~ s/(\d+)/$1 + 1/e
            if defined $next;
    }
}

sub _create_atom
{

}

sub _deploy_site
{
    my $self = shift;

    rcopy( $self->_temp_dir(), $self->target() );
}

no Moose;

1;
