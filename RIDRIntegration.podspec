Pod::Spec.new do |s|
  s.name         = "RIDRIntegration"
  s.version      = "0.0.1"
  s.summary      = "Integration library to the API of RIDR"
  s.license      = { :type => 'BSD' }


  s.description  = <<-DESC
Integration library to the API of RIDR, which will allow for location based information to more users more of the time
DESC
  s.homepage     = "https://www.ridr.co.za"
  s.license      = "MIT"
  s.author       = { "Cipher099" => "info@ridr.co.za" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://github.com/Cipher099/ridr_integration.git",
    :branch => "master",
    :tag => "#{s.version}" }
  s.source_files  = "./*.swift"
  s.exclude_files = "RIDRIntegrationTests/**"
  s.swift_version = "3.2"

  # s.public_header_files = "Classes/**/*.h"

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  s.dependency "GEOSwift", "~> 2.2.0"

end
