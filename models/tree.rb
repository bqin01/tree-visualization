class Tree < ActiveRecord::Base
  has_many :branch, foreign_key: 'user_id'
  belongs_to :user, foreign_key: 'user_id'
end
