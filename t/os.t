#!/usr/bin/env perl
use warnings;
use strict;
use Win32::GuiTest qw(WaitWindowLike GetWindowText SetForegroundWindow SendKeys);
use Test::More;

if($^O !~ /MSWin32|cygwin/ and !$ENV{W32MNPP_FORCE_NONWIN_TEST} ) { plan skip_all => sprintf qq|I don't know how to test with Notepad++.exe in OS '%s'\n\n########################################\n# However, it might work, so I don't want to FAIL.\n#\n# If you'd like to try to make it work, please set the environment variable W32MNPP_FORCE_NOWIN_TEST to a true value,\n# then re-run the test.\n#\n# If it works, feel free to create an issue explaining how to make it work:\n#\thttps://github.com/pryrt/Win32-Mechanize-NotepadPlusPlus/issues\n########################################\n\n|, $^O; }

# use a long version for one test (00-load.t), and a shorthand skip_all => sprintf "Not testing in OS '%s'", $^O;

ok $^O, 'OS = ' . $^O;

done_testing;
