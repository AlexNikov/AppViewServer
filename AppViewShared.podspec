require_relative 'Scripts/appview_src_manifest'

Pod::Spec.new do |spec|
  spec.name         = "AppViewShared"
  spec.version      = "1.2.8"
  spec.summary      = "The shared files between the AppView mac client and AppViewServer."
  spec.description  = "Wire and model sources shared by the AppView mac app and AppViewServer."
  spec.homepage     = "https://github.com/AlexNikov/AppViewServer"
  spec.license      = "GPL-3.0"
  spec.author       = { "AlexNikov" => "" }
  spec.ios.deployment_target  = "14.0"
  spec.tvos.deployment_target  = "14.0"
  spec.macos.deployment_target = "10.14"
  spec.visionos.deployment_target = "1.0"
  spec.source       = { :git => "https://github.com/AlexNikov/AppViewServer.git", :branch => "develop" }
  spec.requires_arc = true
  spec.swift_version = "5.3"

  shared_gcc_defs = [
    "SHOULD_COMPILE_APPVIEW_SERVER=1",
    "APPVIEW_SERVER_SHARED_MODULE=1",
  ].join(" ")

  shared_swift_conditions = [
    "SHOULD_COMPILE_APPVIEW_SERVER",
  ].join(" ")

  shared_pod_headers = AppViewSrcManifest.shared_pod_header_files

  # Swift wire models + Peertalk; transitional headers limited to Peertalk + Base trace.
  spec.source_files = shared_pod_headers + AppViewSrcManifest::OBJC_EXCEPTION_CATCH_SOURCES + [
    "Sources/AppViewServerBase/AppViewIvarTrace.swift",
    "Sources/AppViewServerShared/**/*.swift",
    "Sources/AppViewServerCore/AppViewDashboardBlueprint.swift",
    "Sources/AppViewServerCore/AppViewAttributeGetter.swift",
    "Sources/AppViewServerPeertalk/**/*.swift",
    "Sources/AppViewServerCategories/CALayer+AppView.swift",
    "Sources/AppViewServerCategories/NSSet+AppView.swift",
    "Sources/AppViewServerCategories/AppViewAutoLayoutConstraint.swift",
  ]

  spec.exclude_files = [
    "Sources/AppViewServerShared/AppViewDefines.swift",
    "Sources/AppViewServerShared/AVS_ObjectRegistry.swift",
  ]

  spec.public_header_files = shared_pod_headers

  spec.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) #{shared_gcc_defs}",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) #{shared_swift_conditions}",
    "HEADER_SEARCH_PATHS" => "$(inherited) ${PODS_TARGET_SRCROOT}/Sources/AppViewServerBase",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES",
  }
end
