package myMakeHelper;
use warnings;
use strict;
use 5.010;
use Exporter 5.57 qw(import);
use File::Which ();
use File::Spec ();
use File::Fetch;
use Archive::Extract;
use Config;

our %EXPORT_TAGS = (
    default => [qw/myMakeHelper/],
);
our @EXPORT = qw(myMakeHelper);
our @EXPORT_OK = (@EXPORT, map {@$_} values %EXPORT_TAGS);

sub myMakeHelper {
    my %ret = ();

    warn __PACKAGE__, "\tAUTOMATED_TESTING = ", $ENV{AUTOMATED_TESTING}//'<undef>', "\n";
    warn __PACKAGE__, "\tTEMP = ", $ENV{TEMP}//'<undef>', "\n";
    warn __PACKAGE__, "\tTMP = ", $ENV{TMP}//'<undef>', "\n";

    is_windows() or return %ret;   # TODO: eventually add AUTOMATED_TESTING check as well

    npp_already_exists() and return %ret;

    $ret{bits} = determine_bitness() or return %ret;

    my $td = File::Spec->tmpdir;

    $ret{zip} = download_zip( $ret{bits}, $td ) or return %ret;

    @ret{'npp_folder', 'npp_exe'} = unzip_npp( $ret{zip}, $td ) or return %ret;

    return %ret;
}

sub is_windows { $^O eq 'MSWin32' or $^O eq 'cygwin' or $ENV{AVTEST_FORCE_NON_WIN} }

sub PRETEND_IT_DOESNT { 1; } # set to 0

sub npp_already_exists {
    my $npp_exe;
    # priority to path, 64bit, default, then x86-specific locations
    my @try = ( File::Which::which('notepad++') );
    push @try, "$ENV{ProgramW6432}/Notepad++/notepad++.exe" if exists $ENV{ProgramW6432};
    push @try, "$ENV{ProgramFiles}/Notepad++/notepad++.exe" if exists $ENV{ProgramFiles};
    push @try, "$ENV{'ProgramFiles(x86)'}/Notepad++/notepad++.exe" if exists $ENV{'ProgramFiles(x86)'};
    @try = () if PRETEND_IT_DOESNT;

    foreach my $try ( @try )
    {
        $npp_exe = $try if -x $try;
        last if defined $npp_exe;
    }

    warn sprintf "%s\tNPP = %s\n", __PACKAGE__, $npp_exe  if defined $npp_exe;
    return $npp_exe;
}

sub determine_bitness {
    my $bit;
    warn sprintf "%s\tBITS? \$Config{%s} = %s\n", __PACKAGE__, $_, $Config{$_} for qw/myuname archname ptrsize ivsize/;
    $bit //= 64 if $Config{archname} =~ /x64/;
    $bit //= 64 if $Config{ptrsize} >= 8;
    $bit //= 64 if $Config{ivsize} >= 8;
    $bit //= 32 if $Config{archname} =~ /x86/;  # this isn't enough to downgrade, so just use this to set initial 32-bit
    $bit = 32 if $Config{ptrsize} == 4;
    $bit = 32 if $Config{ivsize} == 4;
    warn sprintf "%s\tBITS = %d\n", __PACKAGE__, $bit//'<undef>';
    return $bit;
}

sub download_zip {
    my ($bits, $folder) = @_;
    if( !-w $folder ) {
        warn sprintf "%s\tZIP? folder '%s' not writeable\n", __PACKAGE__, $folder//'<undef>';
        return;
    }
    warn sprintf "%s\tZIP? '%s' folder ok\n", __PACKAGE__, $folder;

    my %url = (
        64 => {
            https => 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.6/npp.7.8.6.bin.x64.zip',
            http  => 'http://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.6/npp.7.8.6.bin.x64.zip',
            name  => 'npp.7.8.6.bin.x64.zip',
        },
        32 => {
            https => 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.6/npp.7.8.6.bin.zip',
            http  => 'http://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.8.6/npp.7.8.6.bin.zip',
            name  => 'npp.7.8.6.bin.zip',
        },
    );

    my $zip = File::Spec->catfile( $folder, $url{$bits}{name});
    if(-f $zip) {   # already downloaded
        warn sprintf "%s\tZIP = '%s' previously downloaded\n", __PACKAGE__, $zip;
        return $zip;
    }

    undef $zip;
    for(qw/https http/) {
        warn sprintf "%s\tZIP: url = '%s'\n", __PACKAGE__, $url{$bits}{$_};
        my $ff = File::Fetch->new( uri => $url{$bits}{$_} );
        next unless $ff;

        $ff->fetch( to => $folder )
            and $zip = $ff->output_file()
            and last
            or warn sprintf "%s\tZIP? download error = '%s'\n", __PACKAGE__, $ff->error()//'<undef>';
    }
    if( defined $zip ) {
        warn sprintf "%s\tZIP? '%s' downloaded successfully\n", __PACKAGE__, $zip;
        $zip = File::Spec->catfile($folder, $zip) unless -f $zip;
        if( !-f $zip ) {
            warn sprintf "%s\tZIP? '%s' doesn't exist after download\n", __PACKAGE__, $zip;
            return;
        }
    }

    warn sprintf "%s\tZIP = %s\n", __PACKAGE__, $zip//'<undef>';
    return $zip;
}

sub unzip_npp {
    my ($zip, $folder) = @_;
    my $ae = Archive::Extract->new( archive => $zip );

    my $unzip = File::Spec->catdir( $folder, 'notepad++' );
    warn sprintf "%s\tUNZIP? to folder '%s'\n", __PACKAGE__, $unzip;

    my $ok = $ae->extract( to => $unzip );
    if(!$ok) {
        warn sprintf "%s\tUNZIP? extraction error '%s'\n", __PACKAGE__, $ae->error;
        return;
    }

    my $npp = File::Spec->catfile( $unzip, 'notepad++.exe' );
    warn sprintf "%s\tUNZIP? expect executable '%s'\n", __PACKAGE__, $npp;
    if(!-x $npp) {
        warn sprintf "%s\tNPP? no executable '%s'\n", __PACKAGE__, $npp;
        return;
    }

    warn sprintf "%s\tNPP = %s\n", __PACKAGE__, $npp//'<undef>';
    return $unzip, $npp;
}

1;
