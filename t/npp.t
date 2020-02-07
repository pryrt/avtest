#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;

BEGIN {
    # do this _before_ use Win32::GuiTest
    if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) { plan skip_all => sprintf qq|Not testing with notepad.exe in OS '%s'\n|, $^O; }
}

use Win32::GuiTest qw(WaitWindowLike GetWindowText SetForegroundWindow SendKeys);

system 1, 'notepad++.exe';

my $pad = WaitWindowLike(0, undef, '^Notepad\+\+$', undef, undef, 5);
ok $pad, 'notepad++ launched';
note "\t", "pad => '$pad'\n";

SetForegroundWindow($pad);

my $t = GetWindowText($pad);
like $t, qr/\QNotepad++\E/, 'notepad++ title';
diag "\t", "t => '$t'\n";

# close it
SendKeys( '%F', 100 );
SendKeys( 'x', 100 );

# give it 5s to finish closing
my $t0 = time;
while( time() - $t0 < 5.0 ) {
    $pad = WaitWindowLike(0, undef, '^Notepad\+\+$', undef, undef, 1);
    last unless $pad;
}
cmp_ok $pad, '==', 0, 'notepad++ closed';
note "\t", sprintf "pad => '%s': closed in %dsec at %s\n", $pad//'<undef>', time()-$t0, scalar localtime;


done_testing();