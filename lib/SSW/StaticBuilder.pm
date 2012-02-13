package SSW::StaticBuilder;

use base 'MasonX::StaticBuilder';
use Carp qw( carp );
use File::Find::Rule;

sub write {
    my ( $self, $outdir, @args ) = @_;
    my $rule
        = File::Find::Rule->file()->not_name("autohandler")
        ->not_name("dhandler")->not_name(qr/\.mas$/)
        ->start( $self->input_dir() );

    while ( my $c = $rule->match() ) {
        next if $c =~ /\.hg/;
        next if $c =~ /\.mas$/;
        next if $c =~ /sayings\.html/;
        next if $c =~ /one-saying\.html/;

        my $comp_name = $self->_get_comp_name($c);
        my $component = MasonX::StaticBuilder::Component->new(
            {
                comp_root => $self->input_dir(),
                comp_name => $comp_name,
            }
        );

        my $output  = $component->fill_in(@args);
        my $outfile = $outdir . $comp_name;

        # make sub-dirs if necessary
        if ( $comp_name =~ m([^/]/[^/]) ) {
            my ( $subdir, $file ) = ( $comp_name =~ m(^(.*)/(.*?)$) );
            unless ( -d "$outdir/$subdir" ) {
                if ( mkdir("$outdir/$subdir") ) {
                    $self->_write_file( $outfile, $output );
                }
                else {
                    carp
                        "Can't create required subdirectory $outdir/$subdir: $!";
                }
            }
        }
        else {
            $self->_write_file( $outfile, $output );
        }
    }
}

sub _write_file {
    my ( $self, $outfile, $output ) = @_;
    open( OUT, ">", $outfile ) or carp "Can't open output file $outfile: $!";
    binmode OUT, ':utf8';
    print OUT $output;
    close OUT;
}

1;
