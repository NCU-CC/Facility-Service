ActiveRecord::Schema.define(version: 20151220071406) do
   create_table :users do |t|
      t.string :uid, null: false, index: true
      t.string :name, null: false
      t.string :unit, null: false
   end

   create_table :namespaces do |t|
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :name, null: false
      t.string :description, null: false
   end

   create_table :namespaces_users do |t|
      t.belongs_to :user, index: true
      t.belongs_to :namespace, index: true
   end

   create_table :facilities do |t|
      t.belongs_to :namespace, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :name, null: false
      t.string :description, null: false
      t.string :verify_calendar_id
      t.string :rent_calendar_id
   end

   create_table :rents do |t|
      t.belongs_to :facility, index: true
      t.belongs_to :user, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :name, null: false
      t.boolean :verified, null: false, default: false
   end

   create_table :spans do |t|
      t.string :event_id, index: true
      t.belongs_to :rent, index: true
      t.datetime :start
      t.datetime :end
   end
end
