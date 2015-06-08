require 'thor'
require 'open-uri'

module Dashing
  class CLI < Thor
    include Thor::Actions

    attr_reader :name

    class << self
      attr_accessor :auth_token

      def hyphenate(str)
        return str.downcase if str =~ /^[A-Z-]+$/
        str.gsub('_', '-').gsub(/\B[A-Z]/, '-\&').squeeze('-').downcase
      end
    end

    no_tasks do
      %w(widget dashboard job).each do |type|
        define_method "generate_#{type}" do |name|
          @name = Thor::Util.snake_case(name)
          directory(type.to_sym, "#{type}s")
        end
      end
    end

    desc "new PROJECT_NAME", "Sets up ALL THE THINGS needed for your dashboard project."
    def new(name)
      @name = Thor::Util.snake_case(name)
      directory(:project, @name)
    end

    desc "generate (widget/dashboard/job) NAME", "Creates a new widget, dashboard, or job."
    def generate(type, name)
      public_send("generate_#{type}".to_sym, name)
    rescue NoMethodError => e
      puts "Invalid generator. Either use widget, dashboard, or job"
    end

    desc "install GIST_ID [--skip]", "Installs a new widget from a gist (skip overwrite)."
    def install(gist_id, *args)
      gist = Downloader.get_gist(gist_id)
      public_url = "https://gist.github.com/#{gist_id}"

      install_widget_from_gist(gist, args.include?('--skip'))

      print set_color("Don't forget to edit the ", :yellow)
      print set_color("Gemfile ", :yellow, :bold)
      print set_color("and run ", :yellow)
      print set_color("bundle install ", :yellow, :bold)
      say set_color("if needed. More information for this widget can be found at #{public_url}", :yellow)
    rescue OpenURI::HTTPError => http_error
      say set_color("Could not find gist at #{public_url}"), :red
    end

    desc "start", "Starts the server in style!"
    method_option :job_path, :desc => "Specify the directory where jobs are stored"
    def start(*args)
      port_option = args.include?('-p') ? '' : ' -p 3030'
      args = args.join(' ')
      command = "bundle exec thin -R config.ru start#{port_option} #{args}"
      command.prepend "export JOB_PATH=#{options[:job_path]}; " if options[:job_path]
      run_command(command)
    end

    desc "stop", "Stops the thin server"
    def stop
      command = "bundle exec thin stop"
      run_command(command)
    end

    desc "job JOB_NAME AUTH_TOKEN(optional)", "Runs the specified job. Make sure to supply your auth token if you have one set."
    def job(name, auth_token = "")
      Dir[File.join(Dir.pwd, 'lib/**/*.rb')].each {|file| require_file(file) }
      self.class.auth_token = auth_token
      f = File.join(Dir.pwd, "jobs", "#{name}.rb")
      require_file(f)
    end

    # map some commands
    map 'g' => :generate
    map 'i' => :install
    map 's' => :start

    private

    def run_command(command)
      system(command)
    end

    def install_widget_from_gist(gist, skip_overwrite)
      gist['files'].each do |file, details|
        if file =~ /\.(html|coffee|scss)\z/
          widget_name = File.basename(file, '.*')
          new_path = File.join(Dir.pwd, 'widgets', widget_name, file)
          create_file(new_path, details['content'], :skip => skip_overwrite)
        elsif file.end_with?('.rb')
          new_path = File.join(Dir.pwd, 'jobs', file)
          create_file(new_path, details['content'], :skip => skip_overwrite)
        end
      end
    end

    def require_file(file)
      require file
    end
  end
end
