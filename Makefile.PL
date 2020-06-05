use ExtUtils::MakeMaker;
use 5.010;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'avtest',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION'       => '0.00',
    'ABSTRACT'      => 'Dummy module for testing appveyor.yml',
    'PREREQ_PM'     => {
        'Exporter'          => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'           => 0.77,
        'warnings'          => 0,
        'strict'            => 0,
        'Carp'              => 0,
        'Test::More'        => 0.86,
        'Win32::GuiTest'    => 1.64,
    },
);
{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.10.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.52' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            'ExtUtils::MakeMaker' => 0,
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
            'File::Fetch' => 0,
            'File::Which' => 0,
        },
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return <<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# addition to realclean: also delete coverage database, if testcover was run
realclean ::
	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: skip "rm -rf cover_db"
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: skip "rm -rf MYMETA.json.lock"

# run a test coverage report
testcover ::
	$(NOECHO) cover -test -report html

POSTAMBLE
}

if($ENV{W32MNPP_FORCE_WRONG_OS}) {
    $^O = 'WrongOS';
}

if($^O =~ /MSWin32|cygwin/ or $ENV{W32MNPP_FORCE_NONWIN_TEST} ) {
    # 1. Check automated testing (cpan testers smoke tester machine)
    print STDERR "AUTOMATED_TESTING = ", $ENV{AUTOMATED_TESTING}//'<undef>', "\n";
    print STDERR "\n";

    # 2. Look for NPP executable
    sub _search_for_npp_exe {
        my $npp_exe;
        use File::Which 'which';
        # priority to path, 64bit, default, then x86-specific locations
        my @try = ( which('notepad++') );
        push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
        push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
        push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
        foreach my $try ( @try )
        {
            $npp_exe = $try if -x $try;
            last if defined $npp_exe;
        }
        warn "could not find an instance of Notepad++; please add it to your path\n" unless defined $npp_exe;
        #print STDERR __PACKAGE__, " found '$npp_exe'\n";
        return $npp_exe;
    }
    print STDERR "search for npp exe: ", _search_for_npp_exe()//'<undef>', "\n";
    print STDERR "\n";

    # 3. bitness
    use Config;
    my $bit = undef;
    printf STDERR "\$Config{%s} = %s\n", $_, $Config{$_} for qw/myuname archname ptrsize ivsize/;
    $bit //= 64 if $Config{archname} =~ /x64/;
    $bit //= 64 if $Config{ptrsize} >= 8;
    $bit //= 64 if $Config{ivsize} >= 8;
    $bit //= 32 if $Config{archname} =~ /x86/;  # this isn't enough to downgrade, so just use this to set initial 32-bit
    $bit = 32 if $Config{ptrsize} == 4;
    $bit = 32 if $Config{ivsize} == 4;
    print STDERR "bitness: ", $bit//'<undef>', "bit\n";
    print STDERR "\n";

    # 4. fetch
    use File::Fetch;
    my %url = (
        64 => {
            https => 'https://raw.githubusercontent.com/pryrt/Win32-Mechanize-NotepadPlusPlus/master/CHANGES#64',
            http  => 'http://raw.githubusercontent.com/pryrt/Win32-Mechanize-NotepadPlusPlus/master/CHANGES#64',
        },
        32 => {
            https => 'https://raw.githubusercontent.com/pryrt/Win32-Mechanize-NotepadPlusPlus/master/CHANGES#32',
            http  => 'http://raw.githubusercontent.com/pryrt/Win32-Mechanize-NotepadPlusPlus/master/CHANGES#32',
        },
    );
    if(defined $url{$bit}) {
        for (qw/https http/) {
            printf STDERR "URL: %s\n", $url{$bit}{$_};
            my $ff = File::Fetch->new( uri => $url{$bit}{$_});
            next unless $ff;
            print STDERR "File::Fetch->new($url{$bit}{$_}) worked\n";

            # TODO: try download here
            last;
        }
    }
    print STDERR "\n";
}


if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) {
    warn sprintf "I don't know whether it will work with Notepad++.exe in OS '%s'\n", $^O;
    warn << "EOW";

########################################
# However, it might work, so I don't want to FAIL on matrix.cpantesters.org.
#   Instead, don't create the Makefile by default, so it will show up as UNKNOWN
#
# If you'd like to try to make it work, please set the environment variable
#   W32MNPP_FORCE_NONWIN_TEST to a true value,
# then re-run perl Makefile.PL, and continue the standard test suite and
# installation procedure from there.
########################################

EOW
}


WriteMakefile( %mm_args )
