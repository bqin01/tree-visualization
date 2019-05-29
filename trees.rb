require 'sinatra'
require "sinatra/cookies"
require 'digest'
require 'sinatra/activerecord'
require './models/tree.rb'
require './models/user.rb'
require 'securerandom'
require 'json'

set :database_file, 'config/database.yml'

def generate_random_line()
  String result = '"branch": '
  result = result + 4.times.map{Random.rand(101)}.to_s
  return result
end

class Appl < Sinatra::Base
  helpers Sinatra::Cookies
  get '/' do
    erb :index
  end
  get '/tree/:treestr' do
    if params[:treestr] != 'new'
      @the_tree = Tree.find_by(id_str: params[:treestr])
      if @the_tree == nil
        @tree_owner = nil
      else
        @tree_owner = @the_tree.user;
      end
      erb :treeview
    end
  end
  post '/tree/new' do
    @tree_owner = User.find_by(username_hash: cookies[:activeuser])
    if @tree_owner == nil
      erb :loginfail
    end
    @access = params[:access]
    @access ||= 'private'
    @name = params[:newtreename]
    @name ||= 'Untitled Tree'
    tree_str = SecureRandom.uuid # Generate a uniquely universal identifier for the tree
    new_json = '{"branches": ['
    for x in 0..50
      if x != 0
        new_json = new_json + ','
      end
      new_json = new_json + '{' + generate_random_line() + '}'
    end
    new_json = new_json + ']}'
    puts(new_json)
    @the_tree = @tree_owner.tree.create(is_private: (@access == 'private')?true:false, name: @name, branches_and_roots: JSON.parse(new_json), id_str: tree_str, time_active: 0)
    erb :treeview
  end
  post '/user/new' do
    @the_tree = nil
    newsalt = SecureRandom.hex
    @newuser = User.create(username: params['username'], username_hash: Digest::SHA256.hexdigest(params['username']), salt: newsalt, password_salt_enc: Digest::SHA256.hexdigest(params['password']) + newsalt, user_id: SecureRandom.random_number(10000000))
    cookies[:activeuser] = Digest::SHA256.hexdigest(params['username'])
    erb :treeview
  end
  get '/logout' do
    cookies[:activeuser] = nil
    erb :logout
  end
  post '/login' do
    attemptuser = params['username']
    attemptpass = params['password'] # very aware of the security vulnerability here, but I've yet to figure out how it works on Ruby.
    user = User.find_by(username_hash: Digest::SHA256.hexdigest(attemptuser));
    if user == nil
      erb :invalidcreds
    else
      if user.password_salt_enc != Digest::SHA256.hexdigest(attemptpass) + newsalt
        erb :invalidcreds
      else
        cookies[:activeuser] = Digest::SHA256.hexdigest(attemptuser)
        erb :login
      end
    end
  end
end
