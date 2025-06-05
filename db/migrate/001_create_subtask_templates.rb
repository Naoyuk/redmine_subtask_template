class CreateSubtaskTemplates < ActiveRecord::Migration[6.1]
  def change
    create_table :subtask_templates do |t|
      t.string :name, null: false, limit: 255
      t.text :description
      t.integer :project_id, null: true
      t.timestamps null: false
    end

    add_index :subtask_templates, [:project_id, :name], unique: true
    add_foreign_key :subtask_templates, :projects, on_delete: :cascade

    create_table :subtask_template_items do |t|
      t.integer :subtask_template_id, null: false
      t.string :title, null: false, limit: 255
      t.text :description
      t.integer :assigned_to_id, null: true
      t.integer :priority_id, null: true
      t.integer :tracker_id, null: true
      t.integer :position, default: 0
      t.timestamps null: false
    end

    add_index :subtask_template_items, :subtask_template_id
    add_index :subtask_template_items, :assigned_to_id
    add_foreign_key :subtask_template_items, :subtask_templates, on_delete: :cascade
    add_foreign_key :subtask_template_items, :users, column: :assigned_to_id, on_delete: :nullify
    add_foreign_key :subtask_template_items, :trackers, on_delete: :nullify
  end
end
