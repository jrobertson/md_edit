Gem::Specification.new do |s|
  s.name = 'md_edit'
  s.version = '0.2.5'
  s.summary = 'Find a section of a markdown document to edit using the ' + 
      'name of the heading'
  s.authors = ['James Robertson']
  s.files = Dir['lib/md_edit.rb']
  s.add_runtime_dependency('line-tree', '~> 0.6', '>=0.6.1')
  s.add_runtime_dependency('phrase_lookup', '~> 0.1', '>=0.1.7')
  s.signing_key = '../privatekeys/md_edit.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/md_edit'
end
