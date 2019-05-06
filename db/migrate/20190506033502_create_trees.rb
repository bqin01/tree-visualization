# The migration begins here.

class CreateTrees < ActiveRecord::Migration[5.2]
  def change
    create_table :trees do |t|
      t.string :tree_str, null: false
      t.integer :time_active, null: false
      t.string :tree_name, default: "Unnamed Tree"
      t.jsonb :branches_and_roots, null: false, default: "{}"
    end
  end
end
