group :red_green_refactor, halt_on_fail: true do
  guard :rspec, cmd: 'bundle exec rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  end

  guard :rubocop, cmd: 'bundle exec rubocop' do
    watch(%r{^lib/(.+)\.rb$})
    watch(%r{^spec/(.+)\.rb$})
  end
end

guard :rubocop
