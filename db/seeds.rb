# ~~~ bundle exec rake db:seed ~~~

# A scary one-liner.
Tree.all.delete_all
User.all.delete_all
