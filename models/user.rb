class User < ActiveRecord::Base
  has_many :tree, foreign_key: 'user_id'
end
