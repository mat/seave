Seave
=====

A [Weave](https://wiki.mozilla.org/Labs/Weave "Weave") server implementation using [Sinatra](http://www.sinatrarb.com/ "Sinatra"). Experimental. Incomplete, but growing.

Requirements
------------

* Ruby 1.8.7 (earlier 1.8.* versions should work as well, but 1.9 has not been tested yet.)
* RubyGems
* Gems: Sinatra, ActiveRecord, JSON (mandatory)
* thin web server (recommended)
* highline (for rake admin:create_user and friends)

Install these gems via

        sudo gem install sinatra activerecord json thin highline

Launching
---------
First create a config.yml: Copy config.yml.example and edit it to your needs.
You can now let Seave fly with

      rake start

Seave is running on http://localhost:4567 now.

Admin functions
---------------
Seave provides the following admin functions. They are issued as HTTP requests so Seave needs to be running, run `rake start` first.


      rake admin:create_user

      rake admin:delete_user


Major Contributors
------------------

* Matthias Luedtke

