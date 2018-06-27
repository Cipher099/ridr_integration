Pod::Spec.new do |s|
  s.name         = "RIDRIntegration"
  s.module_name  = "RIDRIntegration"
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
  s.source       = {  :git => "https://github.com/Cipher099/ridr_integration.git",
                      :branch => "master",
                      :tag => "#{s.version}" 
                    }
  s.source_files  = 'RIDRIntegration/**/*.{h,m,swift}'
  s.swift_version = "3.2"

  s.dependency "GEOSwift", "~> 2.2.0"
  s.requires_arc      = false

end
