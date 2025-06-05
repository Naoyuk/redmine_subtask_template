document.addEventListener('DOMContentLoaded', function() {
  let itemIndex = 1000; // 新しいアイテムのインデックス
  
  // サブタスクを追加
  document.addEventListener('click', function(e) {
    if (e.target.id === 'add-subtask-item') {
      e.preventDefault();
      addSubtaskItem();
    }
    
    if (e.target.classList.contains('remove_fields')) {
      e.preventDefault();
      removeSubtaskItem(e.target);
    }
  });
  
  function addSubtaskItem() {
    const container = document.getElementById('subtask-items');
    const newItemHTML = createSubtaskItemHTML(itemIndex);
    container.insertAdjacentHTML('beforeend', newItemHTML);
    itemIndex++;
  }
  
  function removeSubtaskItem(link) {
    const confirmMessage = link.dataset.confirm || 'Are you sure you want to delete this subtask?';
    
    if (confirm(confirmMessage)) {
      const item = link.closest('.nested-fields');
      const destroyField = item.querySelector('input[name*="[_destroy]"]');
      
      if (destroyField) {
        destroyField.value = '1';
        item.style.display = 'none';
      } else {
        item.remove();
      }
    }
  }
  
  function createSubtaskItemHTML(index) {
    // 既存のselect要素からオプションを取得
    const trackerOptions = getSelectOptions('tracker_id');
    const userOptions = getSelectOptions('assigned_to_id'); 
    const priorityOptions = getSelectOptions('priority_id');
    
    return `
      <div class="nested-fields subtask-item" style="border: 1px solid #ddd; margin: 10px 0; padding: 15px; background: #f9f9f9;">
        <div style="float: right;">
          <a href="#" class="icon icon-del remove_fields" data-confirm="Are you sure you want to delete this subtask?">Delete</a>
        </div>
        
        <div class="clear-both">
          <p>
            <label for="subtask_template_subtask_template_items_attributes_${index}_title">Subtask Title</label>
            <span class="required"> *</span>
            <input type="text" 
                   name="subtask_template[subtask_template_items_attributes][${index}][title]" 
                   id="subtask_template_subtask_template_items_attributes_${index}_title"
                   size="60" 
                   required 
                   placeholder="Enter the subtask title">
          </p>
          
          <p>
            <label for="subtask_template_subtask_template_items_attributes_${index}_description">Description</label>
            <textarea name="subtask_template[subtask_template_items_attributes][${index}][description]" 
                      id="subtask_template_subtask_template_items_attributes_${index}_description"
                      rows="3" 
                      cols="60"
                      placeholder="Detailed description (optional)"></textarea>
          </p>
          
          <div style="display: flex; gap: 20px;">
            <div style="flex: 1;">
              <label for="subtask_template_subtask_template_items_attributes_${index}_tracker_id">Tracker</label>
              <select name="subtask_template[subtask_template_items_attributes][${index}][tracker_id]" 
                      id="subtask_template_subtask_template_items_attributes_${index}_tracker_id"
                      class="select2-small">
                <option value="">Default</option>
                ${trackerOptions}
              </select>
            </div>
            
            <div style="flex: 1;">
              <label for="subtask_template_subtask_template_items_attributes_${index}_assigned_to_id">Assignee</label>
              <select name="subtask_template[subtask_template_items_attributes][${index}][assigned_to_id]" 
                      id="subtask_template_subtask_template_items_attributes_${index}_assigned_to_id"
                      class="select2-small">
                <option value="">Unassigned</option>
                ${userOptions}
              </select>
            </div>
            
            <div style="flex: 1;">
              <label for="subtask_template_subtask_template_items_attributes_${index}_priority_id">Priority</label>
              <select name="subtask_template[subtask_template_items_attributes][${index}][priority_id]" 
                      id="subtask_template_subtask_template_items_attributes_${index}_priority_id"
                      class="select2-small">
                <option value="">Default</option>
                ${priorityOptions}
              </select>
            </div>
          </div>
        </div>
      </div>
    `;
  }
  
  function getSelectOptions(fieldName) {
    const existingSelect = document.querySelector(`select[name*="[${fieldName}]"]`);
    if (existingSelect) {
      return Array.from(existingSelect.options)
        .filter(option => option.value !== '')
        .map(option => `<option value="${option.value}">${option.text}</option>`)
        .join('');
    }
    return '';
  }
});
