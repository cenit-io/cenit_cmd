module CenitCmd
  class Package < Gem::Package

    attr_accessor :gem_io

    def open(*args, &block)
      if args.first == @gem && @gem_io
        block.call(@gem_io) if block
      else
        super
      end
    end

    def add_files(tar)
      @spec.files.each do |file|

        name =
          if vf = @spec.virtual_files[file]
            file = stat = vf
            file.name
          else
            stat = File.stat file
            next unless stat.file?
            file
          end

        tar.add_file_simple name, stat.mode, stat.size do |dst_io|
          do_open file, 'rb' do |src_io|
            dst_io.write src_io.read 16384 until src_io.eof?
          end
        end
      end
    end

    def do_open(*args, &block)
      if args[0].is_a?(VirtualFile)
        block.call(args[0].open_stream)
      else
        open(*args, &block)
      end
    end

    def build(skip_validation = false)
      @spec.files
      super
    end

    class << self
      def virtual_build(spec)
        package = new(spec.file_name)
        package.spec = spec
        package.build(true)
        gem_content = File.read(spec.file_name)
        File.delete(spec.file_name)
        gem_content
      end
    end

  end
end