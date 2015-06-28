#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin";
use SQLcipherUtil;

my $version = SQLcipherUtil::Version->new(shift || (versions())[-1]);
mirror($version);
copy_files($version);
