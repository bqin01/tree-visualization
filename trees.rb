require 'sinatra'
require "sinatra/cookies"
require 'digest'
require 'sinatra/activerecord'
require './models/tree.rb'
require './models/user.rb'
require './models/branch.rb'
require 'securerandom'
require './treegrowth.rb'
require 'json'
require 'glorify'

set :database_file, 'config/database.yml'

class Line
  attr_reader :x1
  attr_reader :x2
  attr_reader :y1
  attr_reader :y2
  def initialize(ax1, ay1, ax2, ay2)
    @x1 = ax1
    @x2 = ax2
    @y1 = ay1
    @y2 = ay2
  end
end

def compStartPoint(branch_id, factor)
  theline = compBranchInfo(branch_id)
  thepoint = Array.new(2)
  thepoint[0] = (1-factor)*(theline.x1) + (factor)*(theline.x2)
  thepoint[1] = (1-factor)*(theline.y1) + (factor)*(theline.y2)
  return thepoint
end

def compBranchInfo(branch_id)
  if @branchinfo[branch_id] != nil
    return @branchinfo[branch_id]
  end
  thebranch = @the_tree.branch.find_by(branch_id: branch_id)
  if thebranch == nil
    return nil
  end
  startpoint = nil
  if thebranch.parent_id == -1
    startpoint = Array.new(2)
    startpoint[0] = 400
    startpoint[1] = 600
  else
    startpoint = compStartPoint(thebranch.parent_id, thebranch.factor)
  end
  len = thebranch.length
  delx = len * Math.sin(thebranch.sumdevx10 * Math::PI / 1800.0)
  dely = -len * Math.cos(thebranch.sumdevx10 * Math::PI / 1800.0)
  result_line = Line.new(startpoint[0],startpoint[1],startpoint[0]+delx,startpoint[1]+dely);
  @branchinfo[branch_id] = result_line
  return result_line
end

class Appl < Sinatra::Base
  register Sinatra::Glorify
  helpers Sinatra::Cookies
  get '/' do
    erb :index
  end
  get '/howto' do
    @howtomd = File.open("./README.md","rb").read
    erb :howto
  end
  get '/tree/:treestr' do
    @are_you_ok = nil
    if params[:treestr] != 'new'
      @the_tree = Tree.find_by(id_str: params[:treestr])
      if @the_tree == nil
        @tree_owner = nil
      else
        @tree_owner = @the_tree.user
      end
      erb :treeview
    end
  end
  post '/tree/new' do
    @tree_owner = User.find_by(username_hash: cookies[:activeuser])
    if params[:resubmitcheck] != 'ok' || @are_you_ok == false
      @are_you_ok = false
    else
      @are_you_ok = true
    end
    if @are_you_ok == false || @tree_owner == nil
      erb :waitwhat
    else
      params[:resubmitcheck] = 'notok'
      access = params[:access]
      access ||= 'public'
      @name = params[:newtreename]
      if @name == "" || @name == nil
        @name = 'Untitled Tree'
      end
      anytree = @tree_owner.tree.find_by(name: @name)
      if @name != 'Untitled Tree' && anytree != nil
        erb :duptree
      else
        tree_str = SecureRandom.uuid # Generate a uniquely universal identifier for the tree

        @the_tree = @tree_owner.tree.create(is_private: (access == 'private')?true:false, name: @name, id_str: tree_str, time_active: 0, priv_key: SecureRandom.hex)
        @the_tree.branch.create(branch_id: 0, age: 0, parent_id: -1, anglex10: 0, factor: 0.0, sumdevx10: 0, length: 25.0, time_since_last_split: 0)
        erb :newtree
      end
    end
  end
  post '/user/new' do
    newsalt = SecureRandom.hex
    if params['username'] == nil || params['password'] == nil
      erb :waitwhat
    else
      existuser = User.find_by(username: params['username'])
      if existuser != nil
        erb :dupuser
      else
        @newuser = User.create(username: params['username'], username_hash: Digest::SHA256.hexdigest(params['username']), salt: newsalt, password_salt_enc: Digest::SHA256.hexdigest(params['password']) + newsalt, user_id: SecureRandom.random_number(10000000))
        cookies[:activeuser] = Digest::SHA256.hexdigest(params['username'])
        params['username'] = nil
        params['password'] = nil
        erb :newuser
      end
    end
  end
  get '/logout' do
    if cookies[:activeuser] == nil
      erb :logoutfail
    else
      cookies[:activeuser] = nil
      erb :logout
    end
  end
  post '/login' do
    attemptuser = params['username']
    attemptpass = params['password']
    user = User.find_by(username_hash: Digest::SHA256.hexdigest(attemptuser))
    if user == nil
      erb :invalidcreds
    else
      if user.password_salt_enc != (Digest::SHA256.hexdigest(attemptpass) + user.salt)
        erb :invalidcreds
      else
        cookies[:activeuser] = Digest::SHA256.hexdigest(attemptuser)
        @tree_owner = user
        erb :login
      end
    end
  end
  post '/grow/:treestr' do
    curtree = Tree.find_by(id_str: params[:treestr])
    growamt = (params['numdays']).to_i
    if curtree == nil || growamt == nil || growamt < 1 || growamt > 999 || curtree.user.username_hash != cookies[:activeuser]
      erb :growfail
    else
      for i in 1..growamt do
        grow_tree(curtree)
      end
      params['numdays'] = 0
      @the_tree = curtree
      @tree_owner = curtree.user
      erb :treeview
    end
  end
  get '/delete/:treestr' do
    treedelete = Tree.find_by(id_str: params[:treestr])
    if treedelete == nil
        erb :deletefail
    else
      if treedelete.user.username_hash == cookies[:activeuser]
        Tree.where(priv_key: treedelete.priv_key).destroy_all
        @the_tree = nil
        @tree_owner = nil
        erb :treeview
      else
        erb :deletefail
      end
    end
  end
end
