package t::lib::Test;

# Support code for DBD::SQLcipher tests

use strict;
use Exporter   ();
use File::Spec ();
use Test::More ();

our $VERSION = '1.48';
our @ISA     = 'Exporter';
our @EXPORT  = qw/connect_ok dies dbfile @CALL_FUNCS $sqlite_call has_sqlite requires_sqlite/;
our @CALL_FUNCS;
our $sqlite_call;

my $parent;
my %dbfiles;

BEGIN {
	# Allow tests to load modules bundled in /inc
	unshift @INC, 'inc';

	$parent = $$;
}

# Always load the DBI module
use DBI ();

sub dbfile { $dbfiles{$_[0]} ||= (defined $_[0] && length $_[0] && $_[0] ne ':memory:') ? $_[0] . $$ : $_[0] }

# Delete temporary files
sub clean {
	return
		if $$ != $parent;
	for my $dbfile (values %dbfiles) {
		next if $dbfile eq ':memory:';
		unlink $dbfile if -f $dbfile;
		my $journal = $dbfile . '-journal';
		unlink $journal if -f $journal;
	}
}

# Clean up temporary test files both at the beginning and end of the
# test script.
BEGIN { clean() }
END   { clean() }

# A simplified connect function for the most common case
sub connect_ok {
	my $attr = { @_ };
	my $dbfile = dbfile(defined $attr->{dbfile} ? delete $attr->{dbfile} : ':memory:');
	my @params = ( "dbi:SQLcipher:dbname=$dbfile", '', '' );
	if ( %$attr ) {
		push @params, $attr;
	}
	my $dbh = DBI->connect( @params );
	Test::More::isa_ok( $dbh, 'DBI::db' );
	return $dbh;
}

=head2 dies

  dies(sub {...}, $regex_expected_error, $msg)

Tests that the given coderef (most probably a closure) dies with the
expected error message.

=cut

sub dies {
	my ($coderef, $regex, $msg) = @_;
        eval {$coderef->()};
        my $exception = $@;
	Test::More::ok($exception =~ $regex, 
                       $msg || "dies with exception: $exception");
}



=head2 @CALL_FUNCS

The exported array C<@CALL_FUNCS> contains a list of coderefs
for testing several ways of calling driver-private methods.
On DBI versions prior to 1.608, such methods were called
through "func". Starting from 1.608, methods should be installed
within the driver (see L<DBI::DBD>) and are called through
C<< $dbh->sqlite_method_name(...) >>. This array helps to test
both ways. Usage :

  for my $call_func (@CALL_FUNCS) {
    my $dbh = connect_ok();
    ...
    $dbh->$call_func(@args, 'method_to_call');
    ...
  }

On DBI versions prior to 1.608, the loop will run only once
and the method call will be equivalent to 
C<< $dbh->func(@args, 'method_to_call') >>.
On more recent versions, the loop will run twice;
the second execution will call
C<< $dbh->sqlite_method_to_call(@args) >>.

The number of tests to plan should be adapted accordingly.
It can be computed like this :

  plan tests => $n_normal_tests * @CALL_FUNCS + 1;

The additional C< + 1> is required when using
L<Test::NoWarnings>, because that module adds 
a final test in an END block outside of the loop.

=cut


# old_style way ("func")
push @CALL_FUNCS, sub {
  my $dbh = shift;
  return $dbh->func(@_);
};

# new_style, using $dbh->sqlite_*(...) --- starting from DBI v1.608
$DBI::VERSION >= 1.608 and push @CALL_FUNCS, sub {
  my $dbh       = shift;
  my $func_name = pop;
  my $method    = "sqlite_" . $func_name;
  return $dbh->$method(@_);
};


=head2 $sqlite_call

  $dbh->$sqlite_call(meth_name => @args);

This is another way of testing driver-private methods, in a portable
manner that works for DBI versions before or after 1.608. Unlike
C<@CALL_FUNCS>, this does not require to loop -- because after all,
it doesn't make much sense to test the old ->func() interface if
we have support for the new ->sqlite_*() interface. With C<$sqlite_call>,
the most appropriate API is chosen automatically and called only once.

=cut

$sqlite_call = sub {
  my $dbh = shift;
  my $func_to_call = shift;
  $CALL_FUNCS[-1]->($dbh, @_, $func_to_call);
};

=head2 has_sqlite

  has_sqlite('3.6.11');

returns true if DBD::SQLcipher is built with a version of SQLcipher equal to or higher than the specified version.

=cut

sub has_sqlite {
  my $version = shift;
  my @version_parts = split /\./, $version;
  my $format = '%d%03d%03d';
  my $version_number = sprintf $format, @version_parts[0..2];
  use DBD::SQLcipher;
  return ($DBD::SQLcipher::sqlite_version_number && $DBD::SQLcipher::sqlite_version_number >= $version_number) ? 1 : 0;
}

=head2 requires_sqlite

  BEGIN { requires_sqlite('3.6.11'); }

skips all the tests if DBD::SQLcipher is not built with a version of SQLcipher equal to or higher than the specified version.

=cut

sub requires_sqlite {
  my $version = shift;
  unless (has_sqlite($version)) {
    Test::More::plan skip_all => "this test requires SQLcipher $version and newer";
    exit;
  }
}

1;
