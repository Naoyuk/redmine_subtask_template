class SubtaskTemplatesController < ApplicationController
  before_action :require_admin
  before_action :find_template, only: [:show, :edit, :update, :destroy]

  def index
    @templates = SubtaskTemplate.all.order(:name)
  end

  def show
  end

  def new
    @template = SubtaskTemplate.new
  end

  def create
    @template = SubtaskTemplate.new(template_params)
    if @template.save
      flash[:notice] = 'テンプレートが作成されました。'
      redirect_to subtask_templates_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @template.update(template_params)
      flash[:notice] = 'テンプレートが更新されました。'
      redirect_to subtask_templates_path
    else
      render :edit
    end
  end

  def destroy
    @template.destroy
    flash[:notice] = 'テンプレートが削除されました。'
    redirect_to subtask_templates_path
  end

  private

  def find_template
    @template = SubtaskTemplate.find(params[:id])
  end

  def template_params
    params.require(:subtask_template).permit(:name, :description, :project_id,
      subtask_template_items_attributes: [:id, :title, :description, :assigned_to_id, :priority_id, :tracker_id, :_destroy])
  end
end
