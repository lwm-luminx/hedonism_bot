# Photo prices become integer cents in a named currency (the AudienceKit Money shape). The float column is
# dropped after the backfill; this is a pre-release break, so there is no transition period.
class ReplacePhotoPriceWithCentsAndCurrency < ActiveRecord::Migration[8.1]
  def up
    add_column :photos, :price_cents, :integer, null: false, default: 0
    add_column :photos, :currency, :string, null: false, default: "USD", limit: 3
    execute <<~SQL
      UPDATE photos SET price_cents = ROUND(price * 100) WHERE price IS NOT NULL
    SQL
    remove_column :photos, :price
  end

  def down
    add_column :photos, :price, :float
    execute <<~SQL
      UPDATE photos SET price = price_cents / 100.0
    SQL
    remove_column :photos, :currency
    remove_column :photos, :price_cents
  end
end
