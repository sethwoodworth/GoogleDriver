# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'yaml'
require 'rspec/core/shared_context'
require "goo_drive"

RSpec.configure do |config|
  config.order = 'random'

  module FileFixtures
    extend RSpec::Core::SharedContext
    let (:file_doc) { "samples/April\ 13.doc" }
    let (:file_ppt) { "samples/Lecture_5.ppt" }
  end

  config.include FileFixtures

  ::PRIVATE = YAML::load_file(File.expand_path('../private.yml', File.dirname(__FILE__)))
end
