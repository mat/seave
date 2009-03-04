Seave
=====

A [Weave](https://wiki.mozilla.org/Labs/Weave "Weave") server implementation using [Sinatra](http://www.sinatrarb.com/ "Sinatra"). Experimental. Uncomplete, but growing.

Requirements
------------

* Ruby 1.8.7 (earlier 1.8.* versions should work as well, but 1.9 has not been tested yet.)
* RubyGems
* Gems: Sinatra, ActiveRecord, JSON (mandatory)
* thin web server (recommended)

Install these gems via

        sudo gem install sinatra activerecord json thin

Launching
---------
First create a config.yml: Copy config.yml.example and edit it to your needs.
You can now let Seave fly with

      rake start

Seave is running on http://localhost:4567 now.


Major Contributors
------------------

* Matthias Luedtke

