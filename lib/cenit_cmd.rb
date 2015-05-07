require 'thor'
require 'thor/group'

case ARGV.first
  when 'version', '-v', '--version'
    puts Gem.loaded_specs['cenit_cmd'].version
  when 'collection'
    ARGV.shift
    require 'cenit_cmd/collection'
    CenitCmd::Collection.start
  end
end
