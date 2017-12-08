require 'kubeclient'

class MiqWorker
  module ContainerCommon
    extend ActiveSupport::Concern

    def configure_worker_deployment(definition, replicas = 0)
      definition[:spec][:replicas] = replicas
      definition[:spec][:template][:spec][:terminationGracePeriodSeconds] = self.class.worker_settings[:stopping_timeout].seconds

      container = definition[:spec][:template][:spec][:containers].first
      container[:image] = "#{container_image_name}:#{container_image_tag}"
      container[:env] << {:name => "WORKER_CLASS_NAME", :value => self.class.name}
    end

    def scale_deployment
      ContainerOrchestrator.new.scale(worker_deployment_name, self.class.workers_configured_count)
      delete_container_objects if self.class.workers_configured_count.zero?
    end

    def container_image_name
      "docker.io/carbonin/manageiq-base-worker"
    end

    def container_image_tag
      "latest"
    end

    def worker_deployment_name
      @worker_deployment_name ||= "#{self.class.name}-#{queue_name}".underscore.dasherize.gsub("/", "-")
    end
  end
end
