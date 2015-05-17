require 'byebug'
require 'pathname'
require 'git'

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
    
    @generated = false
    def generate
      @collection_name = @file_name
      
      @user_name = options[:user_name] || git_config['user.name']
      @user_email = options[:user_email] || git_config['user.email']
      @github_username = options[:github_username] || git_config['github.user']
      
      return unless validate_argument
       
      use_prefix 'cenit-collection-'

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

      template 'Gemfile', "#{file_name}/Gemfile"
      template 'gitignore', "#{file_name}/.gitignore"
      template 'LICENSE', "#{file_name}/LICENSE"
      template 'Rakefile', "#{file_name}/Rakefile"
      template 'README.md', "#{file_name}/README.md"
      template 'rspec', "#{file_name}/.rspec"
      template 'spec/spec_helper.rb.tt', "#{file_name}/spec/spec_helper.rb"
      @generated = true
    end

    def final_banner
      return unless @generated
      say %Q{
        #{'*' * 80}
        
        Consider the next steps:
        
        Move to the new collection folder.
        > cd #{file_name}
        
        Create a new git and related GitHub's repository
        > rake create_repo
        
        Commit and push until you are happy with your changes
        ...
        
        Generate a version
        > rake version:write
        
        Tag and push release to git
        > rake git:release
        
        Shared your collection in https://rubygems.org
        > rake release
        
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
      
    end
  end
end
