class CreateWiborSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :wibor_snapshots, if_not_exists: true do |t|
      t.date :effective_date, null: false
      t.datetime :fetched_at, null: false
      t.decimal :wibor_1m, precision: 6, scale: 3, null: false
      t.decimal :wibor_3m, precision: 6, scale: 3, null: false
      t.string :source_url, null: false
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :wibor_snapshots, :effective_date, unique: true, if_not_exists: true
  end
end
