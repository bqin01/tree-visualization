class User < ActiveRecord::Base
  belongs_to :tree
  belongs_to :user
end
