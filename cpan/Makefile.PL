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
use File::Find 1.12;
use IPC::Cmd;
use English qw( -no_match_vars );
use Time::Piece 1.12;

use Config;
use ExtUtils::MakeMaker;

use vars qw($VERSION $STRING_VERSION);
$VERSION        = '3.003_000';
$STRING_VERSION = $VERSION;
## no critic (BuiltinFunctions::ProhibitStringyEval)
$VERSION = eval $VERSION;
## use critic

my %perl_autoconf_os =
    map { $_ => 1 } qw( MSWin32 openbsd solaris sunos midnightbsd );
my $use_perl_autoconf = $ENV{MARPA_USE_PERL_AUTOCONF}
    || ( $perl_autoconf_os{$^O} // 0 );

# This comment reminds me of how to use Module::CoreList.
# It's here for convenience in working on this file.
# perl -MModule::CoreList -E 'print $Module::CoreList::version{5.010001}{Carp};'

my %version_for_confiG = (
    # Carp is 1.11 to allow objects to be thrown as exceptions.
    'Carp'                  => '1.11',
    'Config::AutoConf'      => '0.22',
    'CPAN::Meta::Converter' => '2.120921',
    'Cwd'                   => '3.2501',
    'Data::Dumper'          => '2.125',
    'DynaLoader'            => '1.08',
    'English'               => '1.04',
    'Exporter'              => '5.62',
    'ExtUtils::CBuilder'    => '0.27',
    'ExtUtils::MakeMaker'   => '6.42',
    'ExtUtils::Manifest'    => '1.51_01',
    'ExtUtils::Mkbootstrap' => '6.42',
    'Fatal'                 => '1.05',
    'File::Copy'            => '2.11',
    'File::Spec'            => '3.2501',
    'File::Find'            => '1.12',
    'HTML::Entities'        => '3.68',
    'HTML::Parser'          => '3.69',
    'IPC::Cmd'              => '0.40_1',
    'List::Util'            => '1.21',
    'Module::Build'         => '0.4003',
    'PPI'                   => '1.206',
    'Scalar::Util'          => '1.21',
    'Test::More'            => '0.94',
    'Time::Piece'           => '1.12',
    'XSLoader'              => '0.08',
);

my $preamble = <<'END_OF_STRING';
# This file is written by Build.PL
# It is not intended to be modified directly

END_OF_STRING

sub installed_contents {
    my ( $package ) = @_;
    my $marpa_version = $STRING_VERSION;
    my $text             = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($VERSION $STRING_VERSION)} . qq{;\n};
    $text .= q{$VERSION = '} . $marpa_version . qq{';\n};
    $text .= q{$STRING_VERSION = $VERSION} . qq{;\n};
    $text .= q{$VERSION = eval $VERSION} . qq{;\n};
##use critic

    $text .= "1;\n";
    return $text;
} ## end sub installed_contents

sub xs_version_contents {
    my ( $package ) = @_;
    my @use_packages =
        qw( Scalar::Util List::Util Carp Data::Dumper );
    my $text = $preamble;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version = $version_for_confiG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    }
    $text .= "1;\n";
    return $text;
} ## end sub xs_version_contents

sub perl_version_contents {
    my ( $package, ) = @_;
    my @use_packages     = qw( Scalar::Util Carp Data::Dumper PPI Marpa::R3 );
    my $text             = $preamble;
    my $marpa_version = $STRING_VERSION;
    $text .= "package $package;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    for my $package (@use_packages) {
        my $version =
              $package eq 'Marpa::R3'
            ? $marpa_version
            : $version_for_confiG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= "use $package $version ();\n";
    } ## end for my $package (@use_packages)
    $text .= "1;\n";
    return $text;
} ## end sub perl_version_contents

sub file_write {
    my ( $contents, @name_components ) = @_;
    my $file_name = pop @name_components;
    my $dir_name  = File::Spec->catdir( @name_components );
    -d $dir_name or mkdir $dir_name;
    my $path_name = File::Spec->catfile( $dir_name, $file_name );
    open my $fh, q{>}, $path_name;
    print {$fh} $contents or die "print failed: $ERRNO";
    close $fh;
    return 1;
} ## end sub file_write

sub write_installed_pm {
    my ( @components ) = @_;
    my $filename           = 'Installed';
    my @package_components = @components[ 1 .. $#components ];
    my $contents = installed_contents( join q{::}, @package_components,
        $filename );
    $filename .= q{.pm};
    return file_write( $contents, @components, $filename );
} ## end sub write_installed_pm

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
    map { ( $_, $version_for_confiG{$_} ) }
    qw( CPAN::Meta::Converter ),
    @always_required,
    @packages_for_perl_autoconf;
my %requires =
    map { ( $_, $version_for_confiG{$_} ) }
    qw( HTML::Entities HTML::Parser ),
    @always_required;

# my %recommends =
    # map { ( $_, $version_for_confiG{$_} ) }
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
    'lib/Marpa/R3/Version.pm',
    'pperl/Marpa/R3/Perl/Version.pm',
    'html/lib/Marpa/R3/Test/Version.pm',
    'lib/Marpa/R3/Installed.pm', 'pperl/Marpa/R3/Perl/Installed.pm',
    'lib/Marpa/R3.o',            'libmarpa_build'
);

WriteMakefile(
    clean        => { FILES => (join q{ }, @files_to_cleanup) },
        NAME     => 'Marpa::R3',
        AUTHOR   => 'Jeffrey Kegler',
        ABSTRACT => 'Release 3 of Marpa',

        # INC => '-Iinc',

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
        NO_META => 1,
        MAN1PODS => \%pod_files,
        LICENSE  => 'lgpl3',

    test => { TESTS => "t/*.t html/t/*.t" }
    # getoptions => { Dev => {}, 'Marpa-debug' => {} },
);

{
    my @r3_perl_components = qw(pperl Marpa R3 Perl);
    my @r3_components      = qw(lib Marpa R3);
    my $config_pm_filename = File::Spec->catfile(qw(inc Marpa R3 Config.pm ));
    my @derived_files      = (
        File::Spec->catfile( @r3_components,      'Version.pm' ),
        File::Spec->catfile( @r3_components,      'Installed.pm' ),
        File::Spec->catfile( @r3_perl_components, 'Version.pm' ),
        File::Spec->catfile( @r3_perl_components, 'Installed.pm' ),
    );
        say {*STDERR} 'Writing version files' or die "say failed: $ERRNO";
        write_installed_pm( qw(lib Marpa R3 ) );
        write_installed_pm( qw(pperl Marpa R3 Perl ) );
        my $perl_version_pm =
            perl_version_contents( 'Marpa::R3::Perl' );
        my $version_pm = xs_version_contents( 'Marpa::R3' );
        file_write( $version_pm, qw(lib Marpa R3 Version.pm) );
        file_write( $perl_version_pm,
            qw(pperl Marpa R3 Perl Version.pm) );

    if (0) {

        # This code is from Build_Me -- it needs to be converted
        my $self;
        # If it's a shared library, we don't build it here.
        if ( not defined $self->args('libmarpa-external') ) {

            # If the mode file exists, any switch to the internal Libmarpa
            # must be made explicitly
            if ( not defined $self->args('libmarpa-internal') ) {
                my $libmarpa_mode_file =
                    File::Spec->catdir( $self->base_dir(), 'core', 'cf',
                    'LIBMARPA_MODE' );
                die
                    "Libmarpa is external, but you did not explicity specify that -- you need to\n",
                    '  If you want to go back to the built-in Libmarpa, ',
                    qq{use Build's "--libmarpa-internal=on" flag\n}
                    if -e $libmarpa_mode_file;
            } ## end if ( not defined $self->args('libmarpa-internal') )
            $self->do_libmarpa();
        } ## end if ( not defined $self->args('libmarpa-external') )
    } ## end if (0)

}

{
    my @use_packages = qw( HTML::Entities HTML::Parser);
    my $text         = $preamble;
    $text .= "package Marpa::R3::HTML::Test;\n";

##no critic(ValuesAndExpressions::RequireInterpolationOfMetachars)
    $text .= q{use vars qw($TIMESTAMP %VERSION_FOR_CONFIG)} . qq{;\n};
    $text .= q{$TIMESTAMP='} . localtime()->datetime . qq{';\n};
##use critic

    $text .= '%VERSION_FOR_CONFIG = (' . "\n";
    for my $package (@use_packages) {
        my $version = $version_for_confiG{$package};
        die "No version defined for $package" if not defined $version;
        $text .= q{    '} . $package . q{' => '} . $version . qq{',\n};
    }
    $text .= ');' . "\n\n";
    $text .= "1;\n";

    file_write( $text, qw(html tool lib Marpa R3 HTML Test Version.pm ) );

}

# vim: expandtab shiftwidth=4:
