set :branch, :master
set :deploy_to, "/srv/www/production"

role :app, %w{deploy@theyvoteforyou.org.au.test}
role :web, %w{deploy@theyvoteforyou.org.au.test}
role :db,  %w{deploy@theyvoteforyou.org.au.test}
