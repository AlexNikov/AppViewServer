require_relative 'Scripts/appview_src_manifest'

Pod::Spec.new do |spec|
  spec.name         = "AppViewServer"
  spec.version      = "1.2.8"
  spec.summary      = "The iOS framework of AppView with MCP support."
  spec.description  = "Embed this framework into your iOS project to enable the AppView mac app and appview-mcp-ios integration."
  spec.homepage     = "https://github.com/AlexNikov/AppViewServer"
  spec.license      = "GPL-3.0"
  spec.author       = { "AlexNikov" => "" }
  spec.ios.deployment_target  = "14.0"
  spec.tvos.deployment_target  = "14.0"
  spec.visionos.deployment_target = "1.0"
  spec.default_subspecs = ['Swift', 'MCP']
  spec.source       = { :git => "https://github.com/AlexNikov/AppViewServer.git", :branch => "develop" }
  spec.framework    = "UIKit"
  spec.requires_arc = true
  spec.swift_version = "5.3"

  spec.prefix_header_contents = <<-'EOS'
    #ifdef __OBJC__
    @import Foundation;
    @import Dispatch;
    @import UIKit;
    #endif
  EOS

  unified_gcc_defs = [
    "SHOULD_COMPILE_APPVIEW_SERVER=1",
    "APPVIEW_UNIFIED_MODULE=1",
  ].join(" ")

  unified_swift_conditions = [
    "SHOULD_COMPILE_APPVIEW_SERVER",
  ].join(" ")

  spec.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) #{unified_gcc_defs}",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) #{unified_swift_conditions}",
    "HEADER_SEARCH_PATHS" => "$(inherited) ${PODS_TARGET_SRCROOT}/Sources/AppViewServerBase",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES",
    "OTHER_LDFLAGS" => "$(inherited) -undefined dynamic_lookup",
  }

  # Server: Swift in Sources/*; ObjC bridge + ivar trace via appview_src_manifest.rb.
  spec.subspec "Server" do |ss|
    ss.source_files = AppViewSrcManifest.server_pod_source_files + [
      "Sources/AppViewServerShared/**/*.swift",
      "Sources/AppViewServerPeertalk/**/*.swift",
      "Sources/AppViewServerCategories/**/*.swift",
      "Sources/AppViewServerOthers/**/*.swift",
      "Sources/AppViewServerCore/**/*.swift",
      "Sources/AppViewServerConnection/**/*.swift",
      "Sources/AppViewServerConnectionBootstrap/**/*.swift",
    ]
    ss.exclude_files = [
      "Sources/AppViewServerShared/AppViewDefines.swift",
      "Sources/AppViewServerShared/AppViewAttrIdentifiers.swift",
      "Sources/AppViewServerMCP/**/*",
      "Sources/AppViewServer/**/*",
    ]
    ss.private_header_files = [
      "Sources/AppViewServerBase/**/*.h",
    ]
  end

  spec.subspec "Swift" do |ss|
    ss.dependency "AppViewServer/Server"
    ss.source_files = [
      "Sources/AppViewServer/**/*",
    ]
    ss.exclude_files = [
      "Sources/AppViewServerMCP/**/*",
    ]
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited)",
    }
  end

  spec.subspec "MCP" do |ss|
    ss.dependency "AppViewServer/Swift"
    ss.source_files = [
      "Sources/AppViewServerMCP/**/*.swift",
    ]
    ss.pod_target_xcconfig = {
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) APPVIEW_SERVER_MCP",
    }
  end

  spec.subspec "NoHook" do |ss|
    ss.dependency "AppViewServer/Server"
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
    }
  end

  spec.subspec "SwiftAndNoHook" do |ss|
    ss.dependency "AppViewServer/Server"
    ss.source_files = [
      "Sources/AppViewServer/**/*",
    ]
    ss.exclude_files = [
      "Sources/AppViewServerMCP/**/*",
    ]
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited)",
    }
  end
end
