require 'byebug'
require 'pathname'
require 'json'
require 'fileutils'
require 'active_support'
require 'jeweler'
require 'cenit_cmd/virtual_file'
require 'cenit_cmd/package'

class Jeweler::Generator
  def create_git_and_github_repo
    begin
      create_version_control
      create_and_push_repo
    rescue
      puts 'Error create repo en Gitgub'
    end
  end
end

class String
  def to_bool
    self =~ (/(true|t|yes|y|1)$/i) rescue false
  end
end

module CenitCmd
  class Collection < Thor::Group
    include Thor::Actions

    desc "builds a cenit_hub shared collection"
    argument :file_name, type: :string, desc: 'collection path', default: '.'
    argument :collection_name, type: :string, desc: 'collection name', default: '.'
    source_root File.expand_path('../templates/collection', __FILE__)

    attr_reader :dependencies

    class_option :user_name
    class_option :user_email
    class_option :github_username
    class_option :summary
    class_option :description
    class_option :homepage
    class_option :source
    class_option :git_remote
    class_option :create_repo
    class_option :create_gem

    @generated = false

    attr_reader :file_creator

    def generate
      @collection_name = @file_name
      use_prefix

      @user_name ||= options[:user_name] || git_config['user.name']
      @user_email ||= options[:user_email] || git_config['user.email']
      @github_username = options[:github_username] || git_config['github.user']
      @summary ||= options[:summary] || "Shared Collection #{@file_name} to be used with Cenit"
      @description ||= options[:description] || @summary
      @homepage ||= options[:homepage] || "https://github.com/#{@github_username}/#{@file_name}"
      @source ||= options[:source]
      @git_remote = options[:git_remote] || "https://github.com/#{@github_username}/#{@file_name}.git"
      @create_repo = options[:create_repo].to_s.to_bool
      @create_gem = options[:create_gem].to_s.to_bool

      return unless validate_argument

      empty_directory file_name, skip_path_adjust: true

      @load_data = false
      import_data if @source
      @dependencies ||= []

      directory 'lib', 'lib'
      empty_directory "lib/cenit/collection/#{collection_name}/connections"
      empty_directory "lib/cenit/collection/#{collection_name}/webhooks"
      empty_directory "lib/cenit/collection/#{collection_name}/connection_roles"
      empty_directory "lib/cenit/collection/#{collection_name}/events"
      empty_directory "lib/cenit/collection/#{collection_name}/flows"
      empty_directory "lib/cenit/collection/#{collection_name}/translators"
      empty_directory "lib/cenit/collection/#{collection_name}/algorithms"

      empty_directory "spec/support"
      empty_directory "spec/support/sample"

      template 'Gemfile', 'Gemfile'
      template 'gitignore', '.gitignore'
      template 'LICENSE', 'LICENSE'
      template 'Rakefile', 'Rakefile'
      template 'README.md', 'README.md'
      template 'rspec', '.rspec'
      template 'spec/spec_helper.rb.tt', 'spec/spec_helper.rb'

      @generated = true

      create_repo if @create_repo || @create_gem
    end

    def final_banner
      return unless @generated
      say %Q{
          #{'*' * 80}
        
        Consider the next steps:
        
        Move to the new collection folder.
        $ cd #{file_name}
        
        Create a new git and related GitHub's repository
        $ rake create_repo

        Commit and push until you are happy with your changes
        ...

        Generate a version
        $ rake version:write

        Tag and push release to git
        $ rake git:release

        Shared your collection in https://rubygems.org
        $ rake release

        Visit README.md for more details.

        #{'*' * 80}
          }
    end

    no_tasks do

      def build_gem(data)

        virtual_files = []

        %w(name summary description homepage).each { |option| instance_variable_set(:"@#{option}", data[option]) }
        @file_name = filename_scape(data['name'])
        @source = data
        @arguments_required = false
        @file_creator = ->(file_name, content) { virtual_files << CenitCmd::VirtualFile.new(file_name, content) }

        generate

        spec = Gem::Specification.new do |s|
          s.name = file_name
          s.version = data['shared_version']
          s.date = Time.now
          s.summary = @summary
          s.description = @description
          s.authors = data['authors'].collect { |author| author['name'] },
            s.email = data['authors'].collect { |author| author['email'] },
            s.virtual_files = virtual_files
          s.homepage = @homepage
        end

        [spec.file_name, Package.virtual_build(spec)]
      end

      def empty_directory(destination, config = {})
        unless @file_creator
          destination = adjust_path_args(destination) unless config[:skip_path_adjust]
          super
        end
      end

      def adjust_path_args(args)
        args = [args] unless args.is_a?(Array)
        args[0] = "#{file_name}/#{args[0]}" unless args.empty? || @file_creator
        args[0]
      end

      class CreateFile < Thor::Actions::CreateFile
        def invoke!
          if file_creator = base.file_creator
            file_creator.call(given_destination, render)
          else
            super
          end
        end
      end

      def create_file(destination, *args, &block)
        config = args.last.is_a?(Hash) ? args.pop : {}
        data = args.first
        action CreateFile.new(self, adjust_path_args(destination), block || data.to_s, config)
      end

      def class_name
        Thor::Util.camel_case @collection_name
      end

      def use_prefix(prefix = nil)
        @file_name = do_prefix(@file_name)
      end

      def do_prefix(name, prefix = nil)
        prefix ||= 'cenit-collection-'
        name =~ /^#{prefix}/ ? name : prefix + Thor::Util.snake_case(name)
      end

      def git_config
        @git_config ||= Pathname.new("~/.gitconfig").expand_path.exist? ? Git.global_config : {}
      end

      def validate_argument
        if @user_name.nil?
          $stderr.puts %Q{No user.name found in ~/.gitconfig. Please tell git about yourself (see http://help.github.com/git-email-settings/ for details). For example: git config --global user.name "mad voo"}
          return false
        elsif @user_email.nil?
          $stderr.puts %Q{No user.email found in ~/.gitconfig. Please tell git about yourself (see http://help.github.com/git-email-settings/ for details). For example: git config --global user.email mad.vooo@gmail.com}
          return false
        elsif @github_username.nil?
          $stderr.puts %Q{Please specify --github-username or set github.user in ~/.gitconfig (see http://github.com/blog/180-local-github-config for details). For example: git config --global github.user defunkt}
          return false
        end if @arguments_required
        true
      end

      def import_data
        begin
          unless @source.nil?
            if data = @source.is_a?(Hash) ? @source : open_source
              @dependencies =
                if dependencies = data['dependencies']
                  dependencies.collect do |d|
                    {
                      'name' => d['name'],
                      'gem_name' => do_prefix(d['name']),
                      'shared_version' => d['shared_version']
                    }
                  end
                else
                  []
                end
              deploy_data(data)
            end
            @load_data = true
          end
        rescue Exception => ex
          say "ERROR: #{ex.message}"
          @load_data = false
        end
      end

      def deploy_data(data, file_creator = nil)
        file_creator ||= @file_creator || ->(destination, content) { create_file(destination, content) }
        base_path = "lib/cenit/collection/#{collection_name}"
        shared_data = data.is_a?(Hash) ? data : JSON.parse(data)
        hash_data = shared_data['data']
        %w(flows connection_roles translators events connections webhooks algorithms libraries).each do |model|
          next unless hash_model = hash_data[model].to_a
          unless respond_to?(store_method = "store_#{model.singularize}")
            store_method = :store_object
          end
          ns_dirs = {'' => 'default'}
          set = Set.new
          index = []
          hash_model.each do |hash|
            hash['namespace'] = ns = hash['namespace'].to_s.strip
            unless ns_dir = ns_dirs[ns]
              ns_dir = default = filename_scape(ns)
              i = 0
              while ns_dirs.values.include?(ns_dir)
                ns_dir = "#{default}_#{i += 1}"
              end
              ns_dirs[ns] = ns_dir
            end
            next unless obj_name = default = filename_scape(hash['name'])
            i = 0
            while set.include?(obj_name)
              obj_name = "#{default}_#{i += 1}"
            end
            if obj_index = send(store_method, file_creator, base_path, model, ns_dir, obj_name, hash)
              index << obj_index
            end
          end
          file_creator.call("#{base_path}/#{model}/index.json", JSON.pretty_generate(index)) if index.present?
        end
        file_creator.call("#{base_path}/index.json", JSON.pretty_generate(shared_data.except('data')))
      end

      def store_object(file_creator, base_path, obj_dir, ns_dir, obj_name, obj_hash)
        file_creator.call("#{base_path}/#{obj_dir}/#{ns_dir}/#{obj_name}.json", JSON.pretty_generate(obj_hash))
        nil
      end

      def store_translator(file_creator, base_path, obj_dir, ns_dir, obj_name, translator_hash)
        file_creator.call("#{base_path}/#{obj_dir}/#{ns_dir}/#{obj_name}#{transformation_ext(translator_hash['style'])}", translator_hash.delete('transformation'))
        store_object(file_creator, base_path, obj_dir, ns_dir, obj_name, translator_hash)
      end

      def store_algorithm(file_creator, base_path, obj_dir, ns_dir, obj_name, algorithm_hash)
        file_creator.call("#{base_path}/#{obj_dir}/#{ns_dir}/#{obj_name}.rb", algorithm_hash.delete('code'))
        store_object(file_creator, base_path, obj_dir, ns_dir, obj_name, algorithm_hash)
      end

      def store_library(file_creator, base_path, libraries_dir, ns_dir, library_dir, library_hash)
        if (library_name = library_hash['name'].to_s.strip).present?
          host_dirs = {}
          if schemas = library_hash['schemas']
            schemas.each do |schema|
              if uri = schema['uri']
                uri = URI.parse(uri)
                host_dir = nil
                if (host = uri.host) && !(host_dir = host_dirs.keys.detect { |dir| host_dirs[dir] == host })
                  host_dir = default = filename_scape(host)
                  i = 0
                  while host_dirs[host_dir]
                    host_dir = "#{default}_#{i += 1}"
                  end
                  host_dirs[host_dir] = host
                end
                schema_file = uri.path
                schema_file = schema_file.from(1) if schema_file.start_with?('/')
                schema_file = "#{host_dir}/#{schema_file}" if host_dir
                schema =
                  begin
                    JSON.pretty_generate(JSON.parse(schema['schema']))
                  rescue
                    Nokogiri::XML(schema['schema']).to_xml rescue nil
                  end
                file_creator.call("#{base_path}/#{libraries_dir}/#{library_dir}/schemas/#{schema_file}", schema)
              end
            end
          end
          if data_types = library_hash['data_types']
            set = Set.new
            data_types.each do |data_type_hash|
              data_type_file = default = filename_scape(data_type_hash['name'])
              i = 0
              while set.include?(data_type_file)
                data_type_file = "#{default}_#{i += 1}"
              end
              file_creator.call("#{base_path}/#{libraries_dir}/#{library_dir}/data_types/#{data_type_file}", JSON.pretty_generate(data_type_hash))
            end
          end
          {name: library_name, file: library_dir, hosts: host_dirs}
        else
          nil
        end
      end

      def transformation_ext(style)
        case style
        when 'ruby'
          '.rb'
        when 'liquid'
          '.liquid'
        when 'xslt'
          '.xslt'
        else
          ''
        end
      end

      def open_source
        File.open(@source, mode: "r:utf-8").read
      rescue
        nil
      end

      def filename_scape(name)
        name.gsub(/[^\w\s_-]+/, '')
          .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
          .gsub(/\s+/, '_')
          .downcase
      end

      def create_repo
        begin
          Dir.chdir(@file_name) do
            system 'rake create_repo'
            system 'rake version:write MAJOR=0 MINOR=1 PATCH=0'
            system 'rake git:release'
            system 'rake release' if @create_gem
          end
        rescue Exception => e
          puts e.message
        end
      end
    end
  end
end