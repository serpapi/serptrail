class Chat < ApplicationRecord
  acts_as_chat model: :llm_model
end
