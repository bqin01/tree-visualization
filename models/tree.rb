class Tree < ActiveRecord::Base
  has_one :user_trees
  has_one :user, :through => :user_trees
end
