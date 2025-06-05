class SubtaskTemplate < ActiveRecord::Base
  belongs_to :project, optional: true
  has_many :subtask_template_items, dependent: :destroy
  
  accepts_nested_attributes_for :subtask_template_items, allow_destroy: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :project_id }

  scope :global, -> { where(project_id: nil) }
  scope :for_project, ->(project) { where(project_id: project.id) }

  def display_name
    project_id ? "#{name} (#{project.name})" : "#{name} (グローバル)"
  end

  def create_subtasks_for_issue(parent_issue)
    subtask_template_items.each do |item|
      subtask = Issue.new(
        project: parent_issue.project,
        tracker_id: item.tracker_id || parent_issue.tracker_id,
        subject: item.title,
        description: item.description,
        assigned_to_id: item.assigned_to_id,
        priority_id: item.priority_id,
        parent_issue_id: parent_issue.id,
        author: parent_issue.author
      )
      
      if subtask.save
        Rails.logger.info "サブタスクが作成されました: #{subtask.subject}"
      else
        Rails.logger.error "サブタスクの作成に失敗しました: #{subtask.errors.full_messages.join(', ')}"
      end
    end
  end
end
