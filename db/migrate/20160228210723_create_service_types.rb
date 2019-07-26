# typed: true
class CreateServiceTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :service_types do |t|
      t.string :name

      t.timestamps
    end

    ServiceType.seed_for_all_districts
  end
end
