require "zeitwerk"

this_dir = File.expand_path('../', __FILE__)
loader = Zeitwerk::Loader.new
loader.push_dir("#{this_dir}/../lib")
loader.setup
