module Dashing
  class Job
    include Sinatra::Delegator

    def initialize(event, config)
      @event = event
      @config = config
    end

    def execute
      data = do_execute
      send_event(event, data) if data
    end

    protected
    attr_reader :config

    def do_execute
      raise NotImplementedError.new("You must implement #{self.class}#do_execute!")
    end

    private
    attr_reader :event
  end

  def self.load_dynamic_jobs(jobs)
    Array(jobs).each do |job_def|
      klass = const_get job_def[:class]

      job = klass.new(job_def[:event], job_def[:data])

      scheduler.every job_def[:every], :first_in => 0 do
        job.execute
      end
    end
  end

  private

  def self.scheduler
    SCHEDULER
  end
end
