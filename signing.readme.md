# cpansign through appveyor

Some months back, I tried doing cpansign through GitHub action, with the eventual goal of trying to create my signed tarbal for CPAN submission without having to manually do it every time.  Unfortunately, under GH-A, I got [ghaction import-gpg](https://github.com/crazy-max/ghaction-import-gpg) working okay, but when I tried running the cpansign script, it wasn't seeing the key, even though my key was working in every experiment I tried.

So now, I want to see if I can make it work in AppVeyor instead.

## 2022-May

### Links

Notes on passphrase-thru-command-line:
- https://lists.gnupg.org/pipermail/gnupg-devel/2003-January/019607.html
- https://unix.stackexchange.com/questions/60213/gpg-asks-for-password-even-with-passphrase

Secure variables and files in AppVeyor:
- https://www.appveyor.com/docs/build-configuration/
- https://www.appveyor.com/docs/how-to/secure-files/
- https://ci.appveyor.com/tools/encrypt => this is where you can actually encrypt
  - discovered in debug that you cannot paste anything here that has newlines, so couldn't paste the whole gpg asc file

### GPG Debug

Originally tried echoing the %secret_asc% secure variable, but that lost newlines, so it wasn't valid GPG key

Moved it to a `gpg --symmetric` encrypted file, where I echo the secret phrase through the pipe to decrypt the file first.  

When I used the following in my actual computer, it worked
```
echo %PW% | gpg -o encrypted.asc --batch --yes --passphrase-fd 0 --armor --symmetric secret.asc
echo %PW% | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```

but when I tried:
```yml
- echo %secret_phrase% | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```

it told me it was a bad session key.

I re-encrypted the file on the computer, but using the typed phrase instead of the echo'd (`gpg -o encrypted.asc --armor --symmetric secret.asc`), and I changed the yaml to:
```yml
- perl -e "print $ENV{$_} for qw/secret_phrase/" | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```

... and now the file is properly decrypted.  Try again with the new file and the `echo` version: bad descriptor again.  The echo is adding newlines or something.

Okay, when I tried with the perl-echo for both decrypt and import, it worked correctly.

Next, I will start seeing if I can edit the trust levels like I did in my gh-action experiments, because for now, it's showing up as untrusted/unknown-trust.  Go grab my ghaction script excerpt that set the trust.

```
gpg --no-tty --command-fd 0 --edit-key 0x85FA5F2CF71E1CD6 << EOTRUST
trust
5
y
quit
EOTRUST
```

Convert that to appveyor.  Oh, right, that's HEREDOC notation, which works in ghaction+bash, but isn't going to work in appveyor+cmd.  Use perl to write those lines to a `gpgscript`, then `gpg ... < gpgscript` to get it to read those commands.  => **success**: it shows ultimate trust now.

### cpansign Debug

Installed Module::Signature correctly, and tried to run it when I have the variable set correctly.  However, it gets stuck on `cpansign -s`, just like it did on GH-A.  **Annoying.**

My next idea is to get my own copy of Module::Signature, and start adding debug hooks, to figure out where things are going wrong. :-(

So, after much debugging with my own fork+branch, [this version](https://github.com/pryrt/module-signature/blob/27c006e376d37d73e586792e0282e9af0e8750ba/lib/Module/Signature.pm) of Module::Signature will look for ENV{secret_passphrase}, and if it exists, it will pipe the phrase to gpg, and let gpg grab the source from a temporary file.  So, in theory, I should be able to make a distribution tarball in an appveyor action and save it as an artifact.
