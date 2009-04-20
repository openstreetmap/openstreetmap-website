class Tariff < ActiveRecord::Base
	set_primary_keys [:tariff_id, :start_date]
	has_many :product_tariffs, :foreign_key => [:tariff_id, :tariff_start_date]
	has_one :product_tariff, :foreign_key => [:tariff_id, :tariff_start_date]
	has_many :products, :through => :product_tariffs, :foreign_key => [:tariff_id, :tariff_start_date]
end
