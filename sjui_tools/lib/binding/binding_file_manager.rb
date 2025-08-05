# frozen_string_literal: true

require 'fileutils'
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
        @backup_file_path = nil
        
        # Create a backup of existing file instead of deleting it immediately
        if File.exist? @binding_file_path
          @backup_file_path = "#{@binding_file_path}.backup"
          FileUtils.cp(@binding_file_path, @backup_file_path)
        end
        
        @super_binding = "Binding"
        if File.exist?("#{@view_path}/#{@base_name}/#{@base_name}ViewController.swift")
          @super_binding = "BaseBinding"
        end

        {
          base_name: @base_name,
          binding_class_name: @binding_class_name,
          binding_file_name: @binding_file_name,
          binding_file_path: @binding_file_path,
          super_binding: @super_binding,
          backup_file_path: @backup_file_path
        }
      end
      
      def cleanup_backup(backup_path)
        if backup_path && File.exist?(backup_path)
          File.delete(backup_path)
        end
      end
      
      def restore_backup(backup_path, target_path)
        if backup_path && File.exist?(backup_path)
          FileUtils.mv(backup_path, target_path)
          puts "Restored backup for #{File.basename(target_path)}"
        end
      end
    end
  end
end