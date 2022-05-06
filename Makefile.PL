use ExtUtils::MakeMaker;
use 5.010;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'my::Distro',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION'       => '0.004001',
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
    'realclean'     => {
        FILES => 'cover_db MYMETA.json.lock',
    }
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
            'Exporter'          => 5.57,    # needed for `use Exporter qw(import);` notation
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
            'File::Fetch' => 0,
            'File::Spec' => 0,
            'File::Which' => 0,
            'Archive::Extract' => 0,
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
    my $POSTAMBLE =<<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# run a test coverage report
testcover ::
	$(NOECHO) cover -test -report html

test ::
	$(NOECHO) $(ECHO) need to clean up after myself

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'
	$(NOECHO) $(ECHO) ----- START SIGNATURE
	cat $(DISTVNAME)/SIGNATURE
	$(NOECHO) $(ECHO) ----- END SIGNATURE

POSTAMBLE

    $POSTAMBLE .= "\n";
    return $POSTAMBLE;
}

WriteMakefile( %mm_args )
