# frozen_string_literal: true

require_relative 'string_module'

module SjuiTools
  module Binding
    class BindingFileManager
      attr_reader :base_name, :binding_class_name, :binding_file_name, :binding_file_path, :super_binding
      
      def initialize(view_path, binding_path)
        @view_path = view_path
        @binding_path = binding_path
      end

      def setup_binding_file_info(file_name)
        @base_name = "#{file_name.camelize}"
        @binding_class_name = "#{@base_name}Binding"
        @binding_file_name = "#{@binding_class_name}.swift"
        puts @binding_file_name
        @binding_file_path = "#{@binding_path}/#{@binding_file_name}"
        
        if File.exists? @binding_file_path
          File.delete(@binding_file_path)
        end
        
        @super_binding = "Binding"
        if File.exists?("#{@view_path}/#{@base_name}/#{@base_name}ViewController.swift")
          @super_binding = "BaseBinding"
        end

        {
          base_name: @base_name,
          binding_class_name: @binding_class_name,
          binding_file_name: @binding_file_name,
          binding_file_path: @binding_file_path,
          super_binding: @super_binding
        }
      end
    end
  end
end