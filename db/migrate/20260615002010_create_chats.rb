class CreateChats < ActiveRecord::Migration[8.1]
  def change
    create_table :chats do |t|
      t.references :llm_model, foreign_key: true

      t.timestamps
    end
  end
end
