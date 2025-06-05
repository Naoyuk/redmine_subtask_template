module SubtaskTemplatesHelper
  def link_to_add_association(name, form, association, options = {})
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render('subtask_item_fields', form: builder)
    end
    
    link_to(name, '#', 
      class: "add_fields #{options[:class]}", 
      data: { 
        id: id, 
        fields: fields.gsub("\n", ""),
        association: association 
      }
    )
  end

  def link_to_remove_association(name, form, options = {})
    confirm_message = options[:confirm] || 'Are you sure?'
    
    if form.object.persisted?
      form.hidden_field(:_destroy) + 
      link_to(name, '#', 
        class: "remove_fields #{options[:class]}", 
        data: { confirm: confirm_message }
      )
    else
      link_to(name, '#', 
        class: "remove_fields #{options[:class]}", 
        data: { confirm: confirm_message }
      )
    end
  end
end
