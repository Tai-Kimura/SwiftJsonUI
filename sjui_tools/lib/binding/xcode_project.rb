# frozen_string_literal: true

# Wrapper class that includes all Xcode project related functionality
require_relative "xcode_project_manager"

module SjuiTools
  module Binding
    # For backward compatibility
    XcodeProject = XcodeProjectManager
  end
end