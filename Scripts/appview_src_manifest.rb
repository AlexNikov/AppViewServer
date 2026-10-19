# frozen_string_literal: true

# Ivar trace + ObjC exception catch for CocoaPods (unified AppViewServer pod).
# Required from AppViewServer*.podspec via:
#   require_relative 'Scripts/appview_src_manifest'
module AppViewSrcManifest
  BASE_SOURCES = ["Sources/AppViewServerBase/**/*"].freeze

  OBJC_EXCEPTION_CATCH_SOURCES = [
    "Sources/AppViewServerOthers/AppViewObjCExceptionCatch.m",
  ].freeze

  SHARED_HEADER_GLOBS = [
    "Sources/AppViewServerBase/**/*.h",
  ].freeze

  def self.server_pod_source_files
    BASE_SOURCES + OBJC_EXCEPTION_CATCH_SOURCES
  end

  def self.shared_pod_header_files
    SHARED_HEADER_GLOBS
  end
end
