class Branch < ActiveRecord::Base
  belongs_to :tree, foreign_key: 'user_id', dependent: :destroy
end
