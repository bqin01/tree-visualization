require 'sinatra'
require 'sinatra/activerecord'

set :database_file, 'config/database.yml'

class Appl < Sinatra::Base
  get '/' do
    erb :index
  end
end
