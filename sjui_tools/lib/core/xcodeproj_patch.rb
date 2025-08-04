#!/usr/bin/env ruby

require 'xcodeproj'

module Xcodeproj
  class Project
    module Object
      # Monkey patch to handle PBXFileSystemSynchronizedRootGroup
      class PBXFileSystemSynchronizedRootGroup < PBXGroup
        attribute :exceptions, Array
        
        def initialize(project, uuid, attributes)
          # Convert to regular PBXGroup attributes
          modified_attributes = attributes.dup
          modified_attributes['isa'] = 'PBXGroup'
          
          # Remove exceptions attribute as it's not part of standard PBXGroup
          @exceptions_data = modified_attributes.delete('exceptions')
          
          super(project, uuid, modified_attributes)
        end
        
        def ascii_plist_annotation
          " #{display_name} "
        end
      end
      
      # Also handle PBXFileSystemSynchronizedBuildFileExceptionSet if needed
      class PBXFileSystemSynchronizedBuildFileExceptionSet < AbstractObject
        attribute :membershipExceptions, Array
        attribute :publicHeaders, Array
        attribute :target, String
        
        def initialize(project, uuid, attributes)
          super
        end
        
        def ascii_plist_annotation
          " Synchronized Build File Exception Set "
        end
      end
      
      # Override the klass_from_isa method to handle new ISA types
      class << self
        alias_method :original_klass_from_isa, :klass_from_isa
        
        def klass_from_isa(isa)
          case isa
          when 'PBXFileSystemSynchronizedRootGroup'
            PBXFileSystemSynchronizedRootGroup
          when 'PBXFileSystemSynchronizedBuildFileExceptionSet'
            PBXFileSystemSynchronizedBuildFileExceptionSet
          else
            original_klass_from_isa(isa)
          end
        end
      end
    end
  end
end