class SubtaskTemplateItem < ActiveRecord::Base
  belongs_to :subtask_template
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :priority, class_name: 'IssuePriority', optional: true
  belongs_to :tracker, optional: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 65535 }
  
  scope :ordered, -> { order(:id) }
end
