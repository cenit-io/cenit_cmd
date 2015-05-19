require 'byebug'
require 'pathname'
require 'json'
require 'fileutils'
require 'active_support'
# require 'git'
# require 'github_api'
# require 'highline/import'
# require 'erb'

require 'jeweler'

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
    return true if self =~ (/(true|t|yes|y|1)$/i)
    return false if self =~ (/(false|f|no|n|0)$/i)
  return false
  rescue
    return false
  end
end

module CenitCmd
  class Collection < Thor::Group
    include Thor::Actions

    desc "builds a cenit_hub shared collection"
    argument :file_name, type: :string, desc: 'collection path', default: '.'
    argument :collection_name, type: :string, desc: 'collection name', default: '.'
    source_root File.expand_path('../templates/collection', __FILE__)

    class_option :user_name
    class_option :user_email
    class_option :github_username
    class_option :summary
    class_option :description
    class_option :homepage
    class_option :source
    class_option :git_remote
    class_option :create
    
    @generated = false
    def generate
      @collection_name = @file_name
      
      use_prefix 'cenit-collection-'
      
      @user_name = options[:user_name] || git_config['user.name']
      @user_email = options[:user_email] || git_config['user.email']
      @github_username = options[:github_username] || git_config['github.user']
      @summary = options[:summary] || "Shared Collection #{@file_name} to be use in Cenit"
      @description = options[:description] || @summary
      @homepage = options[:homepage] || "https://github.com/#{@github_username}/#{@file_name}"
      @source = options[:source]
      @git_remote = options[:git_remote] || "https://github.com/#{@github_username}/#{@file_name}.git"
      @create = options[:create].to_bool
      
      return unless validate_argument

      empty_directory file_name
      
      directory 'lib', "#{file_name}/lib"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/connections"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/webhooks"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/connection_roles"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/events"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/flows"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/translators"

      empty_directory "#{file_name}/spec/support"
      empty_directory "#{file_name}/spec/support/sample"

      template 'collection.gemspec', "#{file_name}/#{file_name}.gemspec"
      template 'Gemfile', "#{file_name}/Gemfile"
      template 'gitignore', "#{file_name}/.gitignore"
      template 'LICENSE', "#{file_name}/LICENSE"
      template 'Rakefile', "#{file_name}/Rakefile"
      template 'README.md', "#{file_name}/README.md"
      template 'rspec', "#{file_name}/.rspec"
      template 'spec/spec_helper.rb.tt', "#{file_name}/spec/spec_helper.rb"
      @load_data = false
      import_from_file if @source
      create_repo if @create
      
      # puts "cd #{file_name}"
      # Dir.chdir("#{file_name}")
      # puts "bundle exec rake create_repo"
      # `bundle exec rake create_repo`
      # puts "bundle exec rake version:write"
      # `bundle exec rake version:write`
      # puts "bundle exec rake git:release"
      # `bundle exec rake git:release`

      @generated = true
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
      def class_name
        Thor::Util.camel_case @collection_name
      end

      def use_prefix(prefix)
        unless file_name =~ /^#{prefix}/
          @file_name = prefix + Thor::Util.snake_case(file_name)
        end
      end
      
      # Expose git config here, so we can stub it out for test environments
      def git_config
        @git_config  ||=  Pathname.new("~/.gitconfig").expand_path.exist? ? Git.global_config : {}
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
        end
        true
      end

      def import_from_file
        begin
          unless @source.nil?
            data = open_source
            import_data(data) if data != {}
            @load_data = true
          end
        rescue
          @load_data = false
        end
      end

      def import_data(data)
        shared_data = JSON.parse(data)
        hash_data = shared_data['data']
        hash_model = []
        models = ["flows","connection_roles","translators","events","connections","webhooks"]
        models.collect do |model|
          if hash_model = hash_data[model].to_a
            hash_model.collect do |hash|
              if file = filename_scape(hash['name'])
                File.open(@file_name + '/lib/cenit/collection/' + @collection_name + '/' + model + '/' + file + '.json', mode: "w:utf-8") do |f|
                  f.write(JSON.pretty_generate(hash))
                end
              end
            end
          end
        end
        libraries = hash_data['libraries']
        library_index = []
        libraries.collect do |library|
          if library_name = library['name']
            library_file = filename_scape (library_name)
            FileUtils.mkpath(@file_name + '/lib/cenit/collection/' + @collection_name + '/libraries/' + library_file) unless File.directory?(@file_name + '/lib/cenit/collection/' + @collection_name + '/libraries/' + library_file)
            library['schemas'].collect do |schema|
              if schema_file = schema['uri']
                File.open(@file_name + '/lib/cenit/collection/' + @collection_name + '/' + '/libraries/' + library_file + '/' + schema_file, mode: "w:utf-8") do |f|
                  f.write(JSON.pretty_generate(JSON.parse(schema['schema'])))
                end
              end
            end
            library_index << {'name' => library_name, 'file' => library_file}
          end
        end
        File.open(@file_name + '/lib/cenit/collection/' + @collection_name + '/libraries/index.json', mode: "w:utf-8") do |f|
          f.write(JSON.pretty_generate(library_index))
        end
        File.open(@file_name + '/lib/cenit/collection/' + @collection_name + '/index.json', mode: "w:utf-8") do |f|
          f.write(JSON.pretty_generate(shared_data.except('data')))
        end
      end

      def open_source
        File.open(@source, mode: "r:utf-8").read
      rescue {}
      end

      def filename_scape(name)
        name.gsub(/[^\w\s_-]+/, '')
        .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
        .gsub(/\s+/, '_')
        .downcase
      end

      def create_repo
        begin
            options = {
                project_name: @file_name,
                target_dir: @file_name,
                user_name: @user_name,
                user_email: @user_email,
                github_username: @github_username,
                summary: @summary,
                description: @description,
                homepage: @homepage,
                testing_framework: :rspec,
                documentation_framework: :rdoc
            }
            g = Jeweler::Generator.new(options)
            g.create_git_and_github_repo
        rescue
          puts "Not create repo into Github"
        end

      end

      # def create_repo
      #       options = {
      #           project_name: @file_name,
      #           target_dir: @file_name,
      #           user_name: @user_name,
      #           user_email: @user_email,
      #           github_username: @github_username,
      #           summary: @summary,
      #           description: @description,
      #           homepage: @homepage,
      #           testing_framework: :rspec,
      #           documentation_framework: :rdoc,
      #           git_remote: @git_remote
      #
      #       }
      #   create_version_control(options)
      #   create_and_push_repo(options)
      # end

      # def create_version_control (options)
      #   Dir.chdir(options[:target_dir]) do
      #     begin
      #       @repo = Git.init()
      #     rescue Git::GitExecuteError => e
      #       raise GitInitFailed, "Encountered an error during gitification. Maybe the repo already exists, or has already been pushed to?"
      #     end
      #
      #     begin
      #       @repo.add('.')
      #     rescue Git::GitExecuteError => e
      #       raise
      #     end
      #
      #     begin
      #       @repo.commit "Initial commit to #{options[:project_name]}."
      #     rescue Git::GitExecuteError => e
      #       raise
      #     end
      #
      #     begin
      #       @repo.add_remote('origin', options[:git_remote])
      #     rescue Git::GitExecuteError => e
      #       puts "Encountered an error while adding origin remote. Maybe you have some weird settings in ~/.gitconfig?"
      #       raise
      #     end
      #   end
      # end

      # def create_and_push_repo (options)
      #   puts "Please provide your Github user and password to create the Github repository"
      #   begin
      #     puts options[:github_username]
      #     password = ask("Password: ") { |q| q.echo = false }
      #     login = options[:github_username]
      #     github = Github.new(:login => login.strip, :password => password.strip)
      #     github.repos.create(:name => options[:pronject_name], :description => options[:summary], :testing_framework => :rspec, :documentation_framework => :rdoc)
      #   rescue Github::Error::Unauthorized
      #     puts "Wrong login/password! Please try again"
      #     retry
      #   rescue Github::Error::UnprocessableEntity
      #     raise GitRepoCreationFailed, "Can't create that repo. Does it already exist?"
      #   end
      #   @repo.push('origin')
      # end

    end
  end
end