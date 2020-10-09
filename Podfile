platform :ios, '9.0'

target 'OCLintScafford' do
  # use_frameworks!

  # Pods for OCLintScafford
  pod 'OCLint', :path => 'OCLint'
  pod 'clang', :path => 'OCLint'
#  pod 'llvm', :path => 'OCLint'
  
end

post_install do |installer|
    workDir = Dir.pwd
    xcconfigFilename = "#{workDir}/Pods/Target\ Support\ Files/OCLint/OCLint.xcconfig"
    xcconfig = File.read(xcconfigFilename)
    newXcconfig = xcconfig.gsub("HEADER_SEARCH_PATHS = $(inherited)","HEADER_SEARCH_PATHS = $(inherited) \"$(SRCROOT)/../OCLint/\"")
    File.open(xcconfigFilename, "w") { |file| file << newXcconfig }
end
