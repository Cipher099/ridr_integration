Pod::Spec.new do |s|
  s.name         = "RIDRIntegration"
  s.version      = "0.0.1"
  s.summary      = "Integration library to the API of RIDR"
  s.license      = { :type => 'BSD' }


  s.description  = <<-DESC
Integration library to the API of RIDR
DESC
  s.homepage     = "https://www.ridr.co.za"
  s.license      = "MIT"
  s.author             = { "Cipher099" => "info@ridr.co.za" }
  s.platform     = :ios, "9.0"
  s.source       = { :git => "https://bitbucket.org/Cipher099/RIDRIntegration.git", :tag => "#{s.version}" }
  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

  # s.public_header_files = "Classes/**/*.h"

  # s.resource  = "icon.png"
  # s.resources = "Resources/*.png"

  # s.preserve_paths = "FilesToSave", "MoreFilesToSave"

  s.dependency "GEOSwift", "~> 2.2.0"

end
