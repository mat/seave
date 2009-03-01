# To use with thin 
#  thin start -R config.ru -p 4567

require File.join(File.dirname(__FILE__), 'lib', 'seave.rb')

disable :run
set :environment, :development

run Sinatra::Application

