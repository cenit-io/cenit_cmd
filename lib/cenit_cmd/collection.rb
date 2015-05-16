module CenitCmd

  class Collection < Thor::Group
    include Thor::Actions

    desc "builds a cenit_hub collection"
    argument :file_name, :type => :string, :desc => 'collection path', :default => '.'
    argument :collection_name, :type => :string, :desc => 'collection name', :default => '.'

    source_root File.expand_path('../templates/collection', __FILE__)

    def generate
      @collection_name = @file_name
      #use_suffix '_collection'
      use_prefix 'cenit-collection-'

      empty_directory file_name
      
      directory 'lib', "#{file_name}/lib"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/connections"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/webhooks"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}/connection_roles"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}//events"
      empty_directory  "#{file_name}/lib/cenit/collection/#{collection_name}//flows"
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

      def use_suffix(suffix)
        unless file_name =~ /#{suffix}$/
          @file_name = Thor::Util.snake_case(file_name) + suffix
        end
      end


      def use_prefix(prefix)
        unless file_name =~ /#{prefix}$/
          @file_name = prefix + Thor::Util.snake_case(file_name)
        end
      end
    end

  end
end
