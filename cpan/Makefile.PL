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

use 5.010;
use strict;
use warnings;
use Fatal qw(open close mkdir chdir);
use File::Spec 0.82;
use IPC::Cmd;
use English qw( -no_match_vars );

use Config;
use ExtUtils::MakeMaker;

use lib File::Spec->catdir('inc');
use Marpa::R3::Build_Me;
use Marpa::R3::Config;

my @packages_for_perl_autoconf = qw( Config::AutoConf );
my @always_required            = qw(
    Carp
    Cwd
    Data::Dumper
    DynaLoader
    English
    Exporter
    ExtUtils::CBuilder
    ExtUtils::MakeMaker
    ExtUtils::Manifest
    ExtUtils::Mkbootstrap
    Fatal
    File::Copy
    File::Spec
    IPC::Cmd
    List::Util
    PPI
    Scalar::Util
    Test::More
    Time::Piece
    XSLoader
);

my %configure_requires =
    map { ( $_, $Marpa::R3::VERSION_FOR_CONFIG{$_} ) }
    qw( CPAN::Meta::Converter ),
    @always_required,
    @packages_for_perl_autoconf;
my %requires =
    map { ( $_, $Marpa::R3::VERSION_FOR_CONFIG{$_} ) }
    qw( HTML::Entities HTML::Parser ),
    @always_required;

# my %recommends =
    # map { ( $_, $Marpa::R3::VERSION_FOR_CONFIG{$_} ) }
    # ( @packages_for_perl_autoconf, qw( PPI ) );

my %pod_files = ();
{
    local $RS = undef;
    open my $manifest_fh, q{<}, 'MANIFEST';
    my @pod_files = split /\n/xms, $manifest_fh->getline();
    close $manifest_fh;
    LINE: for my $pod_file (@pod_files) {
        $pod_file =~ s/ \s* [#] .* \z //xms;
        next LINE if not $pod_file =~ / [.] pod \z /xms;
        next LINE if $pod_file =~ m{ libmarpa [/] dev [/] old_pod [/] }xms;
        if ( ( my $destfile = $pod_file )
            =~ s{ \A pod [/] }{lib/Marpa/R3/}xms )
        {
            $pod_files{$pod_file} = $destfile;
            next LINE;
        } ## end if ( ( my $destfile = $pod_file ) =~ ...)
        if ( ( my $destfile = $pod_file )
            =~ s{ \A html [/] pod [/] }{lib/Marpa/R3/}xms )
        {
            $pod_files{$pod_file} = $destfile;
            next LINE;
        } ## end if ( ( my $destfile = $pod_file ) =~ ...)
        die "Failed to rename POD file: $pod_file";
    } ## end LINE: for my $pod_file (@pod_files)
}
$pod_files{'pod/Marpa_R3.pod'}  = 'lib/Marpa/R3.pod';
$pod_files{'html/pod/HTML.pod'} = 'lib/Marpa/R3/HTML.pod';

my %pm_files = ();
File::Find::find(
    sub {
        return if not m/[.]pm \z/xms;
        $pm_files{$File::Find::name} = $File::Find::name;
    },
    'lib'
);
File::Find::find(
    sub {
        return if not m/[.]pm \z/xms;
        my ( $vol, $dirs, $file ) = File::Spec->splitpath($File::Find::name);
        my @dirs      = File::Spec->splitdir($dirs);
        my $dest_dirs = File::Spec->catdir( @dirs[ 1 .. $#dirs ] );
        my $dest_name = File::Spec->catpath( $vol, $dest_dirs, $file );
        $pm_files{$File::Find::name} = $dest_name;
    },
    'html/lib'
);
for my $pm_file (qw(Version.pm Installed.pm)) {
    my $pm_fullname = 'lib/Marpa/R3/' . $pm_file;
    $pm_files{$pm_fullname} = $pm_fullname;
}

my @no_index_namespace_inclusive = qw(
    Marpa::R3::HTML
    Marpa::R3::Value
    Marpa::R3::Perl
    Marpa::R3::Test
    Marpa::R3::Display
    Marpa::R3::Inner
    Marpa::R3::Internal
    Marpa::R3::MetaAST
    Marpa::R3::MetaG
    Marpa::R3::Stuifzand
);

my @files_to_cleanup = (
    'lib/Marpa/R3/Version.pm',   'pperl/Marpa/R3/Perl/Version.pm',
    'lib/Marpa/R3/Installed.pm', 'pperl/Marpa/R3/Perl/Installed.pm',
    'lib/Marpa/R3.o',            'libmarpa_build'
);

WriteMakefile(
    clean        => { FILES => (join q{ }, @files_to_cleanup) },
        NAME     => 'Marpa::R3',
        AUTHOR   => 'Jeffrey Kegler',
        ABSTRACT => 'Release 3 of Marpa',

        # recommends         => \%recommends,
        PREREQ_PM          => \%requires,
        CONFIGURE_REQUIRES => \%configure_requires,
        PM                 => \%pm_files,
        EXE_FILES           => [
        'html/script/marpa_r3_html_fmt',
        'html/script/marpa_r3_html_score',
        ],
        XS       => { 'xs/R3.xs' => 'lib/Marpa/R3.xs' },
        META_ADD => {
            no_index => {
                directory => [
                    qw( pperl tool libmarpa author.t
                        html/etc html/sandbox html/script html/t
                        )
                ],
                namespace => [
                    'Marpa::R3::Recognizer', 'Marpa::R3::Grammar',
                    @no_index_namespace_inclusive
                ],
                package => [
                    @no_index_namespace_inclusive, 'Marpa::R3::Thin::Trace'
                ],
            }
            },
        META_MERGE => { resources =>
            { repository => 'git://github.com/jeffreykegler/Marpa--R3.git', },
        },
        MAN1PODS => \%pod_files,
        LICENSE  => 'lgpl3',

    test => { TESTS => "t/*.t html/t/*.t" }
    # getoptions => { Dev => {}, 'Marpa-debug' => {} },
);

# vim: expandtab shiftwidth=4:
