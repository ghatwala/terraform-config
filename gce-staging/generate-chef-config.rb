require 'json'

data = JSON.parse(STDIN.read)
env = data.map {|k, v| ["TRAVIS_" + k.to_s.upcase, v] }.to_h
out = {
  run_list: ["recipe[travis_go_worker]"],
  travis: { worker: { environment: env } }
}
puts JSON.pretty_generate(out)