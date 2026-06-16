class AddParentToolCallToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :tool_call, foreign_key: true
  end
end
