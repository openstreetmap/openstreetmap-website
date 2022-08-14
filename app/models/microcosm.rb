# == Schema Information
#
# Table name: microcosms
#
#  id          :bigint(8)        not null, primary key
#  name        :string           not null
#  key         :string           not null
#  facebook    :string
#  twitter     :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Microcosm < ApplicationRecord
end
