class CreateBanks < ActiveRecord::Migration[8.1]
  def change
    create_table :banks do |t|
      t.string :title, null: false
      t.text :description
      t.string :website_url

      t.timestamps
    end

    add_index :banks, :title
  end
end
