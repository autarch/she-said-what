package SSW::CLI;

use strict;
use warnings;

use SSW::RCFile;
use SSW::Types qw( Dir NonEmptySimpleStr );

use Moose::Role;

with 'MooseX::Getopt::Dashes';

has db_dir =>
    ( is      => 'ro',
      isa     => Dir,
      coerce  => 1,
      lazy    => 1,
      default => sub { $_[0]->_rcfile()->db_dir() },
    );

has target =>
    ( is      => 'ro',
      isa     => NonEmptySimpleStr,
      lazy    => 1,
      default => sub { $_[0]->_rcfile()->target() },
    );

has _rcfile =>
    ( is      => 'ro',
      isa     => 'SSW::RCFile',
      lazy    => 1,
      default => sub { SSW::RCFile->new() },
    );

has _db =>
    ( is       => 'ro',
      isa      => 'SSW::DB',
      lazy     => 1,
      default  => sub { SSW::DB->new( dir => $_[0]->db_dir() ) },
      init_arg => undef,
    );

no Moose::Role;

1;
