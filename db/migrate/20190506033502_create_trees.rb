# The migration begins here.

class CreateTrees < ActiveRecord::Migration[5.2]
  def change
    create_table :trees do |t|
      t.string :id_str, null: false
      t.integer :time_active, null: false
      t.string :name, default: "Unnamed Tree"
      t.jsonb :branches_and_roots, null: false, default: "{}"
      t.boolean :is_private, null: false, default: false
      t.timestamps
    end
    create_table :users do |u|
      t.integer :id, null: false;
      t.string :username, null: false
      t.string :password_enc, null: false;
      t.timestamps
    end
    create_table :user_trees do |ut|
      t.belongs_to :tree
      t.belongs_to :user
    end
  end
end
