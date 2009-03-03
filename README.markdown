Seave
=====

A [Weave](https://wiki.mozilla.org/Labs/Weave "Weave") server implementation using [Sinatra](http://www.sinatrarb.com/ "Sinatra"). Experimental.

Requirements
------------

* Ruby 1.8.7 (earlier 1.8.* versions should work as well, but 1.9 is not yet tested.)
* RubyGems
* Gems: Sinatra, ActiveRecord, JSON
* thin web server (recommended)

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

