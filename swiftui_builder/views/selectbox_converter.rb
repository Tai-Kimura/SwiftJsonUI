#!/usr/bin/env ruby

require_relative 'base_view_converter'

class SelectBoxConverter < BaseViewConverter
  def convert
    id = @component['id'] || 'selectBox'
    selectItemType = @component['selectItemType'] || 'picker'
    
    case selectItemType
    when 'datePicker'
      generate_date_picker(id)
    when 'timePicker'
      generate_time_picker(id)
    when 'dateTimePicker'
      generate_datetime_picker(id)
    else
      generate_picker(id)
    end
    
    # 共通のモディファイアを適用
    apply_modifiers
    
    generated_code
  end
  
  private
  
  def generate_picker(id)
    items = @component['items'] || []
    
    # @Stateプロパティ
    add_line "@State private var selected#{id.split('_').map(&:capitalize).join} = \"\""
    
    # Picker
    add_line "Picker(\"#{@component['hint'] || 'Select'}\", selection: $selected#{id.split('_').map(&:capitalize).join}) {"
    indent do
      items.each do |item|
        add_line "Text(\"#{item}\").tag(\"#{item}\")"
      end
    end
    add_line "}"
    
    if @component['pickerStyle'] == 'menu'
      add_modifier_line ".pickerStyle(.menu)"
    end
  end
  
  def generate_date_picker(id)
    # @Stateプロパティ
    add_line "@State private var selected#{id.split('_').map(&:capitalize).join}Date = Date()"
    
    # DatePicker
    add_line "DatePicker(\"#{@component['hint'] || 'Select Date'}\", selection: $selected#{id.split('_').map(&:capitalize).join}Date, displayedComponents: .date)"
    
    if @component['datePickerStyle'] == 'compact'
      add_modifier_line ".datePickerStyle(.compact)"
    elsif @component['datePickerStyle'] == 'wheel'
      add_modifier_line ".datePickerStyle(.wheel)"
    end
  end
  
  def generate_time_picker(id)
    # @Stateプロパティ
    add_line "@State private var selected#{id.split('_').map(&:capitalize).join}Time = Date()"
    
    # DatePicker（時間のみ）
    add_line "DatePicker(\"#{@component['hint'] || 'Select Time'}\", selection: $selected#{id.split('_').map(&:capitalize).join}Time, displayedComponents: .hourAndMinute)"
    
    if @component['datePickerStyle']
      add_modifier_line ".datePickerStyle(.#{@component['datePickerStyle']})"
    end
  end
  
  def generate_datetime_picker(id)
    # @Stateプロパティ
    add_line "@State private var selected#{id.split('_').map(&:capitalize).join}DateTime = Date()"
    
    # DatePicker（日付と時間）
    add_line "DatePicker(\"#{@component['hint'] || 'Select Date & Time'}\", selection: $selected#{id.split('_').map(&:capitalize).join}DateTime)"
    
    if @component['datePickerStyle']
      add_modifier_line ".datePickerStyle(.#{@component['datePickerStyle']})"
    end
  end
end