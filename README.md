# avtest
this is just exploring appveyor.yml and travis-ci

I will use this for exploring specific syntax, or situations under which
I might want to skip parts of the flow in my test lists, or similar.

# remote-download branch

Explored a possible method of downloading and unzipping notepad++ zip into tempdir.
Requires
* File::Fetch       => CORE since v5.9.5
* File::Spec        => CORE since v5.4.5
* File::Which       => not CORE, but already required by WMNpp
* Archive::Extract  => CORE since v5.9.5

With those, I created myMakeHelper.pm (which I might want to rename to something like myGrabNpp),
and use that to modify grab Notepad++.exe and to tell My::postamble how to delete the download
after `make test` is complete.

The one note is that I have to be able to either include the tempdir/notepad++/ folder in the
path, or I have to somehow tell the test suite to try that location for notepad++ before the
search.
