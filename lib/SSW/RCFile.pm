package SSW::RCFile;

use strict;
use warnings;

use Config::General qw( ParseConfig );
use File::HomeDir;
use File::Spec;
use SSW::Types qw( Dir NonEmptySimpleStr HashRef );

use Moose;
use MooseX::StrictConstructor;

has db_dir =>
    ( is      => 'ro',
      isa     => Dir,
      coerce  => 1,
      lazy    => 1,
      default => sub { $_[0]->_config()->{db_dir} },
    );

has target =>
    ( is      => 'ro',
      isa     => NonEmptySimpleStr,
      lazy    => 1,
      default => sub { $_[0]->_config()->{target} },
    );

has rcfile =>
    ( is      => 'ro',
      isa     => NonEmptySimpleStr,
      lazy    => 1,
      default => sub { $ENV{SSWRC}
                       || File::Spec->catfile( File::HomeDir->my_home(), '.sswrc' ) },
    );

has _config =>
    ( is      => 'ro',
      isa     => HashRef,
      lazy    => 1,
      default => sub { return { ParseConfig( $_[0]->rcfile() ) } },
    );

no Moose;

1;
