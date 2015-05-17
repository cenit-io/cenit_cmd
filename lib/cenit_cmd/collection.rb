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
    end

    def final_banner
      say %Q{
        #{'*' * 80}

        Consider listing your collection in https://rubygems.org

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
        @git_config  ||=  if Pathname.new("~/.gitconfig").expand_path.exist?
                           Git.global_config
                         else
                           {}
                         end

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
