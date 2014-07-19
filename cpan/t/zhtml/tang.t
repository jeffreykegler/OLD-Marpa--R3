#!/usr/bin/perl
# Copyright 2014 Jeffrey Kegler
# This file is part of Marpa::R3.  Marpa::R3 is free software: you can
# redistribute it and/or modify it under the terms of the GNU Lesser
# General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Marpa::R3 is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser
# General Public License along with Marpa::R3.  If not, see
# http://www.gnu.org/licenses/.

# Call one of the HTML tests.
# It's possible that I may want to separate out the HTML
# parser someday, so its tests are in another directory
# hierarchy and are called indirectly.

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use File::Spec;

my $test_dir = File::Spec->catdir(qw(html t ));
my $test_file = File::Spec->catfile( $test_dir, 'tang.t' );

exec $EXECUTABLE_NAME, '-Iinc', $test_file;
die "Could not exec $test_file: $ERRNO";

# vim: expandtab shiftwidth=4:
