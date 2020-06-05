# avtest
this is just exploring appveyor.yml and travis-ci

I will use this for exploring specific syntax, or situations under which
I might want to skip parts of the flow in my test lists, or similar.

# remote-download branch

It appears File∷Fetch has been core since v5.9.5, though at least in v5.10, it didn’t support https, so I should probably make sure I can grab the downloads with http URLs

In Makefile.PL, pseudocode:

    If(OS is win32 or cygwin) {
        Possibly: last unless automated/smoke testing
        last if myfind(notepad++.exe); # where myfind() uses File∷Which, as well as reasonable default paths
        bitness = look at %Config myuname, archname, ptrsize, ivsize, and downgrade from 64 to 32 if its obvious 32-bit
        ff = File∷Fetch→new(https) or File∷Fetcj→new(http)
        tmpdir = path-tiny-tmpfile || writeable(t) or last
        ff→fetch( to ⇒ tmpdir )
        if tmpdir/zipfile exists, unzip it (maybe use IO∷Uncompress∷Unzip or Archive∷Extract, both of which entered CORE
<v5.10)

        can I add it to path?  Maybe create a t\ file to do{} or require which will add it to path (in BEGIN block)
        create the cleanup.pl script, hopefully in the t\ environment, which will remove the download and unzip folder when done

        add cleanup.pl call to end of `make test` target
    }

I think that’s a reasonable algorithm, though testing/implementing it will be … interesting.

### Notes

* I had been leaning toward unzipping in the Makefile.PL directory... but when studying the
    travis details (reminding myself of why the linux one wasn't showing bitness, etc --
    because it skips that part!!!), I saw that they did a `make distdir`...
    Even without linux, if the smoke testers are building and testing from a "distdir" equivalent,
    it might not create it in the right spot.
* but I still need a way to create a _known_ name that my test files can refer to for determining
    whether to add the downloaded npp path or not.  Hmph.
    Maybe '<tmpdir>/avtest.inc'.