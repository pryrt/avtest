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
            'ExtUtils::MakeMaker' => 6.00,
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

use lib './helpbuild';
use myMakeHelper;
my %helper = myMakeHelper();

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    my $POSTAMBLE =<<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# addition to realclean: also delete coverage database, if testcover was run
realclean ::
	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: skip "rm -rf cover_db"
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: skip "rm -rf MYMETA.json.lock"
	$(NOECHO) $(ECHO) "1;" > t/nppPath.inc.pl

# run a test coverage report
testcover ::
	$(NOECHO) cover -test -report html

POSTAMBLE

    if( defined $downloaded_npp_folder ) {
        $POSTAMBLE .=<<"EONPP";

test ::
	\$(NOECHO) \$(ECHO) need to cleanup after myself
	dir t
	dir "$downloaded_npp_folder"
	\$(NOECHO) ( \$(TEST_F) "$downloaded_npp_zip" && \$(RM_RF) "$downloaded_npp_zip" ) || \$(ECHO) post-test: skip "rm -rf $downloaded_npp_zip"
	\$(NOECHO) ( \$(TEST_D) "$downloaded_npp_unzip" && \$(RM_RF) "$downloaded_npp_unzip" ) || \$(ECHO) post-test: skip "rm -rf $downloaded_npp_unzip"

EONPP
    }

    return $POSTAMBLE;
}

WriteMakefile( %mm_args )
