Redmine::Plugin.register :subtask_template do
  name 'Subtask Template Plugin'
  author 'Naoyuki Ishida'
  description 'This plugin allows you to manage issue templates and automatically create subtasks in Redmine.'
  version '0.0.1'
  url 'https://github.com/Naoyuk/redmine_subtask_template'
  author_url 'https://github.com/Naoyuk'

  # プラグインのメニューを管理者メニューに追加
  menu :admin_menu, :subtask_templates, { :controller => 'subtask_templates', :action => 'index' }, :caption => '📋 Subtask Templates', :if => Proc.new { User.current.admin? }

  # 権限の定義
  project_module :subtask_template do
    permission :view_subtask_templates, :subtask_templates => [:index, :show]
    permission :manage_subtask_templates, :subtask_templates => [:new, :create, :edit, :update, :destroy]
  end

  # プロジェクトの設定タブにプラグイン設定を追加
  settings :default => {
    'default_template' => '',
    'auto_create_subtasks' => true
  }, :partial => 'settings/subtask_template_settings'
end
