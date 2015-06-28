#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use t::lib::Test qw/connect_ok/;
use Test::More;
use DBD::SQLcipher;

BEGIN{
    plan skip_all => 'this test is for Win32 only' unless $^O eq 'MSWin32';
    plan skip_all => 'this test requires SQLcipher 3.7.12 and above' unless $DBD::SQLcipher::sqlite_version_number > 3071100;
}

use Test::NoWarnings;
use DBD::SQLcipher::Constants qw/:extended_result_codes :result_codes/;
use File::Temp;

plan tests => 18;

my $tmpdir = File::Temp::tempdir(CLEANUP => 1);
ok -d $tmpdir;

my %expected = (
  0 => SQLITE_CANTOPEN,
  1 => SQLITE_CANTOPEN_ISDIR,
);

# opening a directory as a database causes SQLITE_CANTOPEN(_ISDIR)
for my $flag (0, 1) {
    my $dbh = connect_ok(
        RaiseError => 0,
        PrintError => 0,
        sqlite_extended_result_codes => $flag,
    );
    ok !$dbh->do(qq{attach '$tmpdir' as tmp});
    is $dbh->err => $expected{$flag};

    $dbh->{sqlite_extended_result_codes} = 1 - $flag;
    is $dbh->{sqlite_extended_result_codes} => 1 - $flag;
    ok !$dbh->do(qq{attach '$tmpdir' as tmp});
    is $dbh->err => $expected{1 - $flag};
}

for my $flag (0, 1) {
    my $dbh = DBI->connect("dbi:SQLcipher:$tmpdir", '', '', {
        RaiseError => 0,
        PrintError => 0,
        sqlite_extended_result_codes => $flag,
    });
    ok !$dbh, "Shouldn't be able to open a temporary directory as a database";
    my $err = DBI->err;
    is $err => $expected{$flag};
}
