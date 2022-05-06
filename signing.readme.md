Adding some notes about my signing experiments.

Originally tried echoing the %secret_asc% secure variable, but that lost newlines, so it wasn't valid GPG key
Moved it to a `gpg --symmetric` encrypted file, where I echo the secret phrase through the pipe to decrypt the file first.  
When I used the following in my actual computer, it worked
```
echo %PW% | gpg -o encrypted.asc --batch --yes --passphrase-fd 0 --armor --symmetric secret.asc
echo %PW% | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```
but when I tried 
```yml
- echo %secret_phrase% | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```
it told me it was a bad session key.

I re-encrypted the file on the computer, but using the typed phrase instead of the echo'd (`gpg -o encrypted.asc --armor --symmetric secret.asc`), and I changed the yaml to 
```yml
- perl -e "print $ENV{$_} for qw/secret_phrase/" | gpg -o decrypted.asc --batch --yes --passphrase-fd 0 --decrypt encrypted.asc
```
... and now the file is properly decrypted.  Try again with the new file and the `echo` version: bad descriptor again.  The echo is adding newlines or something.

Okay, when I tried with the perl-echo for both decrypt and import, it worked correctly.

NEXT (after thios readme commit), I will start seeing if I can edit the trust levels like I did in my gh-action experiments, because for now, it's showing up as untrusted/unknown-trust

-----
