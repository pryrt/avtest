#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use File::Spec::Functions qw/tmpdir catfile catdir/;

BEGIN {
    # do this _before_ use Win32::GuiTest
    if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) { plan skip_all => sprintf qq|Not testing with notepad.exe in OS '%s'\n|, $^O; }
}

use Win32::GuiTest qw(WaitWindowLike GetWindowText SetForegroundWindow SendKeys MenuSelect);

BEGIN {
    $ENV{PATH} = catdir(tmpdir, 'notepad++') . ';' . $ENV{PATH};
    diag "\t", 'path => ', $ENV{PATH};
}
#my $exe = catfile( tmpdir, 'notepad++', 'notepad++.exe');
my $exe = 'notepad++.exe'; #unless -x $exe;
ok $exe, 'executable name';
diag "\t", "exe => ", $exe||'<undef>', "\n";

done_testing(); exit;
__END__
system 1, $exe;

my $pad = WaitWindowLike(0, undef, '^Notepad\+\+$', undef, undef, 5);
ok $pad, 'notepad++ launched';
note "\t", "pad => '$pad'\n";
sleep 1;

SetForegroundWindow($pad);

my $t = GetWindowText($pad);
like $t, qr/\QNotepad++\E/, 'notepad++ title';
diag "\t", "t => '$t'\n";

# close it
#SendKeys( '%{F4}', 1000 );
MenuSelect("&File|E&xit");

# give it 5s to finish closing
my $t0 = time;
while( time() - $t0 < 5.0 ) {
    $pad = WaitWindowLike(0, undef, '^Notepad\+\+$', undef, undef, 1);
    last unless $pad;
}
cmp_ok $pad, '==', 0, 'notepad++ closed';
note "\t", sprintf "pad => '%s': closed in %dsec at %s\n", $pad//'<undef>', time()-$t0, scalar localtime;


done_testing();
