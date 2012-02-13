package SSW::GenSite;

use strict;
use warnings;

use Cwd qw( abs_path );
use File::Basename qw( basename );
use File::Copy::Recursive qw( rcopy );
use File::Slurp qw( write_file );
use File::Spec;
use File::Temp qw( tempdir );
use MasonX::StaticBuilder::Component;
use SSW::DB;
use SSW::StaticBuilder;
use SSW::Types qw( Dir );
use XML::Feed;
use XML::Feed::Entry;

use Moose;
use MooseX::StrictConstructor;

with 'SSW::CLI';

has _builder => (
    is       => 'ro',
    isa      => 'SSW::StaticBuilder',
    lazy     => 1,
    default  => sub { SSW::StaticBuilder->new('./share/mason') },
    init_arg => undef,
);

has _temp_dir => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    lazy     => 1,
    default  => sub { tempdir( CLEANUP => 1 ) },
    init_arg => undef,
);

my $Tagline = 'A logorrheic journal by proxy';

sub Tagline { $Tagline }

sub run {
    my $self = shift;

    $self->_builder()->write( $self->_temp_dir() );

    for my $dir (qw( css images js )) {
        $self->_copy_dir(
            File::Spec->catdir( 'share',            $dir ),
            File::Spec->catdir( $self->_temp_dir(), $dir ),
        );
    }

    $self->_write_sayings();

    $self->_create_atom();

    $self->_deploy_site();

    print "Deployed site to ", $self->target(), "\n";
}

sub _copy_dir {
    my $self   = shift;
    my $source = shift;
    my $target = shift;

    rcopy( $source, $target );
}

sub _write_sayings {
    my $self = shift;

    my $list_comp = MasonX::StaticBuilder::Component->new(
        {
            comp_root => $self->_builder()->input_dir(),
            comp_name =>
                $self->_builder()->_get_comp_name
                ( abs_path('./share/mason/sayings.html') ),
        }
    );

    my $saying_comp = MasonX::StaticBuilder::Component->new(
        {
            comp_root => $self->_builder()->input_dir(),
            comp_name =>
                $self->_builder()->_get_comp_name
                ( abs_path('./share/mason/one-saying.html') ),
        }
    );

    my @sayings = $self->_db()->sayings();

    for my $saying (@sayings) {
        my $output = $saying_comp->fill_in( saying => $saying );

        my $outfile
            = $self->_temp_dir()->file( $saying->uri_path() . '.html' );
        write_file( $outfile->stringify(), $output );
    }

    my ( $prev, $cur, $next ) = ( undef, 'index.html', 'sayings2.html' );

    while (@sayings) {
        my @for_page
            = @sayings >= 10
            ? ( splice @sayings, 0, 10 )
            : ( splice @sayings, 0, scalar @sayings );

        undef $next unless @sayings;

        my $output = $list_comp->fill_in(
            sayings => \@for_page,
            prev    => $prev,
            next    => $next,
        );

        my $outfile = $self->_temp_dir()->file($cur);
        write_file( $outfile->stringify(), $output );

        $prev = $cur;
        $cur  = $next;
        $next =~ s/(\d+)/$1 + 1/e
            if defined $next;
    }
}

sub _create_atom {
    my $self = shift;

    my @sayings = $self->_db()->sayings();
    @sayings = splice @sayings, 0, 10
        if @sayings > 10;

    my $feed = XML::Feed->new('Atom');

    $feed->title('She Said What?!');
    $feed->link('http://shesaidwh.at/');
    $feed->tagline($Tagline);
    $feed->author('She');
    $feed->copyright('Copyright 2009 House Absolute Consulting');
    $feed->modified( DateTime->now( time_zone => 'UTC' ) );

    for my $saying (@sayings) {
        my $entry = XML::Feed::Entry->new();
        $entry->title( $saying->quote() );

        my $uri = 'http://shesaidwh.at/' . $saying->uri_path() . '.html';
        $entry->id($uri);
        $entry->link($uri);

        if ( $saying->has_commentary() ) {
            $entry->content( $saying->commentary() );
        }

        $entry->issued( $saying->datetime() );
        $entry->modified( DateTime->now( time_zone => 'UTC' ) );
        $entry->author('She');

        $feed->add_entry($entry);
    }

    my $file = $self->_temp_dir()->file('atom.xml');
    write_file( $file->stringify(), $feed->as_xml() );
}

sub _deploy_site {
    my $self = shift;

    if ( $self->target() =~ /:/ ) {
        $self->_remote_deploy_site();
    }
    else {
        $self->_copy_dir( $self->_temp_dir(), $self->target() );
    }
}

sub _remote_deploy_site {
    my $self = shift;

    system(
        'scp',                             '-q', '-r',
        glob( $self->_temp_dir() . '/*' ), $self->target()
    ) and die;
}

no Moose;

1;
