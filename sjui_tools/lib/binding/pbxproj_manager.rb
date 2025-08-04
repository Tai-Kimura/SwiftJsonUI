# frozen_string_literal: true

module SjuiTools
  module Binding
    class PbxprojManager
      def self.add_file_reference(project_content, file_ref_uuid, filename, file_type = 'sourcecode.swift')
        # Find PBXFileReference section
        if project_content =~ /(\/\* Begin PBXFileReference section \*\/\n)(.*?)(\/\* End PBXFileReference section \*\/)/m
          section_content = $2
          
          # Check if file reference already exists
          return project_content if section_content.include?(file_ref_uuid)
          
          # Add new file reference
          new_ref = "\t\t#{file_ref_uuid} /* #{filename} */ = {isa = PBXFileReference; lastKnownFileType = #{file_type}; path = #{filename}; sourceTree = \"<group>\"; };\n"
          updated_section = section_content + new_ref
          
          project_content.sub!(
            /(\/\* Begin PBXFileReference section \*\/\n).*?(\/\* End PBXFileReference section \*\/)/m,
            "\\1#{updated_section}\\2"
          )
        end
        
        project_content
      end

      def self.add_to_group(project_content, group_uuid, file_ref_uuid, filename)
        # Find the group and add file reference to children
        if project_content =~ /(#{group_uuid}[^{]*\{[^}]*children = \(\n)(.*?)(\s*\);)/m
          children_content = $2
          
          # Check if already in group
          return project_content if children_content.include?(file_ref_uuid)
          
          # Add to children
          updated_children = children_content.rstrip + "\n\t\t\t\t#{file_ref_uuid} /* #{filename} */,\n"
          
          project_content.sub!(
            /(#{group_uuid}[^{]*\{[^}]*children = \(\n).*?(\s*\);)/m,
            "\\1#{updated_children}\\2"
          )
        end
        
        project_content
      end

      def self.add_build_file(project_content, build_file_uuid, file_ref_uuid, filename)
        # Find PBXBuildFile section
        if project_content =~ /(\/\* Begin PBXBuildFile section \*\/\n)(.*?)(\/\* End PBXBuildFile section \*\/)/m
          section_content = $2
          
          # Check if build file already exists
          return project_content if section_content.include?(build_file_uuid)
          
          # Add new build file
          new_build = "\t\t#{build_file_uuid} /* #{filename} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_uuid} /* #{filename} */; };\n"
          updated_section = section_content + new_build
          
          project_content.sub!(
            /(\/\* Begin PBXBuildFile section \*\/\n).*?(\/\* End PBXBuildFile section \*\/)/m,
            "\\1#{updated_section}\\2"
          )
        end
        
        project_content
      end

      def self.add_to_build_phase(project_content, build_phase_uuid, build_file_uuid, filename)
        # Find the build phase and add build file to files array
        if project_content =~ /(#{build_phase_uuid}[^{]*\{[^}]*files = \(\n)(.*?)(\s*\);)/m
          files_content = $2
          
          # Check if already in build phase
          return project_content if files_content.include?(build_file_uuid)
          
          # Add to files
          updated_files = files_content.rstrip + "\n\t\t\t\t#{build_file_uuid} /* #{filename} in Sources */,\n"
          
          project_content.sub!(
            /(#{build_phase_uuid}[^{]*\{[^}]*files = \(\n).*?(\s*\);)/m,
            "\\1#{updated_files}\\2"
          )
        end
        
        project_content
      end

      def self.generate_uuid
        # Generate a 24-character hex UUID for Xcode
        SecureRandom.hex(12).upcase
      end

      def self.find_target(project_content, target_name)
        # Find native target
        if project_content =~ /([A-F0-9]{24}) \/\* #{Regexp.escape(target_name)} \*\/ = \{[^}]*isa = PBXNativeTarget;/
          $1
        else
          nil
        end
      end

      def self.find_build_phase(project_content, target_uuid, phase_name = 'Sources')
        # Find build phase for target
        if project_content =~ /#{target_uuid}[^{]*\{[^}]*buildPhases = \(([^)]*)\);/m
          build_phases = $1
          
          if build_phases =~ /([A-F0-9]{24}) \/\* #{phase_name} \*\//
            $1
          else
            nil
          end
        else
          nil
        end
      end

      def self.find_group(project_content, group_name)
        # Find group by name
        if project_content =~ /([A-F0-9]{24}) \/\* #{Regexp.escape(group_name)} \*\/ = \{[^}]*isa = PBXGroup;/
          $1
        else
          nil
        end
      end
    end
  end
end