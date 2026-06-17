# frozen_string_literal: true

# Junction that connects a person to a locale.  Used when a DJ or other persona is common to a few
# locales but not the globe
class PersonLocale < ApplicationRecord
  belongs_to :locale
  belongs_to :person
end
