#!/usr/bin/env ruby
require "fileutils"
require "xcodeproj"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "FutureEcho.xcodeproj")
FileUtils.rm_rf(PROJECT_PATH)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2660"
project.root_object.attributes["LastUpgradeCheck"] = "2660"

app = project.new_target(:application, "FutureEcho", :ios, "14.0")
unit = project.new_target(:unit_test_bundle, "FutureEchoTests", :ios, "14.0")
ui = project.new_target(:ui_test_bundle, "FutureEchoUITests", :ios, "14.0")
unit.add_dependency(app)
ui.add_dependency(app)

def configure(target, bundle_id)
  target.build_configurations.each do |config|
    config.build_settings["SWIFT_VERSION"] = "5.0"
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "14.0"
    config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = bundle_id
    config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
    config.build_settings["SUPPORTS_MACCATALYST"] = "NO"
    config.build_settings["CLANG_ENABLE_MODULES"] = "YES"
  end
end

configure(app, "com.wangrenzhu.futureecho")
configure(unit, "com.wangrenzhu.futureecho.tests")
configure(ui, "com.wangrenzhu.futureecho.uitests")

app.build_configurations.each do |config|
  config.build_settings["INFOPLIST_FILE"] = "FutureEcho/Info.plist"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
  config.build_settings["PRODUCT_NAME"] = "Future Echo"
  config.build_settings["MARKETING_VERSION"] = "1.0"
  config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
end

unit.build_configurations.each do |config|
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Future Echo.app/Future Echo"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end
ui.build_configurations.each do |config|
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["TEST_TARGET_NAME"] = "FutureEcho"
end

main = project.main_group
app_group = main.new_group("FutureEcho", "FutureEcho")
core_group = main.new_group("FutureEchoCore", "Sources/FutureEchoCore")
unit_group = main.new_group("FutureEchoTests", "FutureEchoTests")
ui_group = main.new_group("FutureEchoUITests", "FutureEchoUITests")

def add_sources(group, target, directory)
  Dir.glob(File.join(directory, "**", "*.swift")).sort.each do |path|
    ref = group.new_file(path.sub(%r{^#{Regexp.escape(directory)}/?}, ""))
    target.source_build_phase.add_file_reference(ref)
  end
end

add_sources(app_group, app, File.join(ROOT, "FutureEcho"))
add_sources(core_group, app, File.join(ROOT, "Sources/FutureEchoCore"))
add_sources(unit_group, unit, File.join(ROOT, "FutureEchoTests"))
add_sources(ui_group, ui, File.join(ROOT, "FutureEchoUITests"))

["Assets.xcassets", "PrivacyInfo.xcprivacy", "Resources/en.lproj/Localizable.strings", "StoreKit/FutureEcho.storekit"].each do |relative|
  ref = app_group.new_file(relative)
  app.resources_build_phase.add_file_reference(ref)
end

project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app)
scheme.set_launch_target(app)
scheme.add_test_target(unit)
scheme.add_test_target(ui)
scheme.save_as(PROJECT_PATH, "FutureEcho", true)

scheme_path = File.join(PROJECT_PATH, "xcshareddata", "xcschemes", "FutureEcho.xcscheme")
scheme_xml = File.read(scheme_path)
storekit_reference = <<~XML.chomp
      <StoreKitConfigurationFileReference
         identifier = "../FutureEcho/StoreKit/FutureEcho.storekit">
      </StoreKitConfigurationFileReference>
XML
scheme_xml.sub!("   </TestAction>", "#{storekit_reference}\n   </TestAction>")
scheme_xml.sub!("   </LaunchAction>", "#{storekit_reference}\n   </LaunchAction>")
File.write(scheme_path, scheme_xml)
puts PROJECT_PATH
