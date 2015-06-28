#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use t::lib::Test;
use Test::More;

my $tests = 7;
$tests += 1 if has_sqlite('3.7.7');
plan tests => $tests;

use DBI;
use DBD::SQLcipher;

my $dbfile = dbfile('foo');
unlink $dbfile if -f $dbfile;

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_READONLY,
    });
  };
  ok $@ && !$dbh && !-f $dbfile, "failed to open a nonexistent dbfile for readonly";
  unlink $dbfile if -f $dbfile;
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_READWRITE,
    });
  };
  ok $@ && !$dbh && !-f $dbfile, "failed to open a nonexistent dbfile for readwrite (without create)";
  unlink $dbfile if -f $dbfile;
}

{
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_READWRITE|DBD::SQLcipher::OPEN_CREATE,
    });
  };
  ok !$@ && $dbh && -f $dbfile, "created a dbfile for readwrite";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}

if (has_sqlite('3.7.7')) {
  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_URI,
    });
  };
  ok !$@ && $dbh && -f $dbfile, "readwrite/create flags are turned on if no readonly/readwrite/create flags are set";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_READONLY,
    });
  };
  ok !$@ && $dbh, "opened an existing dbfile for readonly";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}

{
  eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
    });
  };
  ok !$@ && -f $dbfile, "created a dbfile";

  my $dbh = eval {
    DBI->connect("dbi:SQLcipher:$dbfile", undef, undef, {
      PrintError => 0,
      RaiseError => 1,
      sqlite_open_flags => DBD::SQLcipher::OPEN_READWRITE,
    });
  };
  ok !$@ && $dbh, "opened an existing dbfile for readwrite";
  $dbh->disconnect;
  unlink $dbfile if -f $dbfile;
}
