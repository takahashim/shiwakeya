class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name
      t.integer :role, default: 0, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :role
  end
end
