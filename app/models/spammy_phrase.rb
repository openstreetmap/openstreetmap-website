# frozen_string_literal: true

# == Schema Information
#
# Table name: spammy_phrases
#
#  id         :bigint           not null, primary key
#  phrase     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SpammyPhrase < ApplicationRecord
end
