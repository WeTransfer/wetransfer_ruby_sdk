guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
end

guard :rubocop, cmd: 'bundle exec rubocop', halt_on_failure: false do
  watch(%r{^lib/(.+)\.rb$})
  watch(%r{^spec/(.+)\.rb$})
end

clearing :on
