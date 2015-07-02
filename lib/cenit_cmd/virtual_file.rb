module CenitCmd
  class VirtualFile

    attr_reader :name, :content

    def initialize(name, content)
      @name = name
      @content = content.to_s.force_encoding('ASCII-8BIT')
    end

    def open_stream
      io = StringIO.new
      io.write(content)
      io.rewind
      io
    end

    def mode
      33204
    end

    def size
      content.length
    end
  end
end

class Gem::Specification

  attr_reader :virtual_files

  def virtual_files=(files)
    @virtual_files = {}
    Array(files).each { |file| @virtual_files[file.name] = file}
  end

  def files
    @virtual_files ||= {}
    @files = [@files,
              @test_files,
              add_bindir(@executables),
              @extra_rdoc_files,
              @extensions,
              @virtual_files.keys.to_a
    ].flatten.uniq.compact.sort
  end
end