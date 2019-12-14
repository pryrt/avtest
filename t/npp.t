#!/usr/bin/env perl
use warnings;
use strict;
use Win32::GuiTest qw(WaitWindowLike GetWindowText SetForegroundWindow SendKeys);
use Test::More;

system 1, 'notepad++.exe';

my $pad = WaitWindowLike(0, undef, '^Notepad\+\+$', undef, undef, 5);
ok $pad, 'notepad++ launched';
note "\t", "pad => '$pad'\n";

SetForegroundWindow($pad);

my $t = GetWindowText($pad);
ok $t, 'notepad++ title';
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