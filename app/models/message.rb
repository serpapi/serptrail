class Message < ApplicationRecord
  acts_as_message model: :llm_model
end
