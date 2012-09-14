# Heroku SSL Doctor

A Heroku client plugin for the `heroku certs:*` namespace.

Heroku SSL Doctor makes it easy to manage your SSL Endpoints by figuring out all the certificate stuff automagically.

- The certificate trust chain will be ordered and completed.
- Can deal with both concatenated or separate files.
- Pass certificate and key files in any order.
- Pass any number of keys and intermediate certificates.
- If multiple keys are passed, the correct one will be used.
- Garbage input will be discarded.

That means you don't have to fret about which file contains what, and in which order; the following would work just fine:

    $ heroku certs:add *.{pem,crt,key}
    $ heroku certs:add all-my-ssl-things/*

To see the chain and key that would be uploaded by add/update, use:

    $ heroku certs:chain *.{pem,crt}
    $ heroku certs:key *.{pem,crt,key}

Something's broken? Bypass all the magic:

    $ heroku certs:add path-to-crt path-to-key
