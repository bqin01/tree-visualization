require 'sinatra'
require 'sinatra/activerecord'
require './models/tree.rb'
require './models/usertree.rb'
require './models/user.rb'

set :database_file, 'config/database.yml'

class Appl < Sinatra::Base

  get '/' do
    erb :index
  end

  get '/tree/new' do
    erb :newtree
  end
  get '/tree/:treestr' do

  end
  get '/user/new' do
    erb :newuser
  end
  get '/user/:uname' do

  end
end
