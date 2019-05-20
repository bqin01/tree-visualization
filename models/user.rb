class User < ActiveRecord::Base
  has_many :user_trees
  has_many :trees, :through => :user_trees
end
