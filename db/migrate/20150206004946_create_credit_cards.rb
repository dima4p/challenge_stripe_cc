class CreateCreditCards < ActiveRecord::Migration
  def change
    create_table :credit_cards do |t|
      t.belongs_to :customer, index: true
      t.string :name
      t.string :stripe_id

      t.timestamps null: false
    end
    add_foreign_key :credit_cards, :customers
  end
end
