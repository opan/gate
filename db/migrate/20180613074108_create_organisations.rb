class CreateOrganisations < ActiveRecord::Migration
  def change
    create_table :organisations do |t|
      t.string :name
      t.string :url
      t.string :email_domain

      t.timestamps null: false
    end
  end
end
