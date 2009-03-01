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
Launch Seave on port 4567 using the thin server

      rackup config.ru -p 4567 -s thin


Major Contributors
------------------
* Matthias Luedtke

