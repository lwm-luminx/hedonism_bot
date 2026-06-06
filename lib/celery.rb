require "redis"
require "json"
require "securerandom"
require "async"


module Celery
  def self.redis
    @redis ||= ConnectionPool::Wrapper.new do
      Redis.new(host: "localhost", port: 6379, reconnect_attempts: 3)
    end
  end

  def self.enqueue(task_name, *args, **kwargs, &block)
    task_id = SecureRandom.uuid # Unique ID for tracking
    body = {
      "args" => args,
      "kwargs" => kwargs,
      "embed" => {
        "callbacks" => nil,
        "errbacks" => nil,
        "chain" => nil,
        "chord" => nil
      }
    }
    envelope = {
      "body" => Base64.strict_encode64(body.to_json),
      "args" => args,
      "kwargs" => kwargs,
      "content-encoding" => "utf-8",
      "content-type" => "application/json",
      "headers" => {
        "lang" => "py",
        "task" => task_name,
        "id" => task_id,
        "argsrepr" => args.to_s,
        "kwargsrepr" => kwargs.to_s
      },
      "properties" => {
        "body_encoding" => "base64",
        "delivery_tag" => SecureRandom.uuid,
        "delivery_mode" => 2,
        "delivery_info" => {
          "exchange" => "",
          "delivery_tag" => SecureRandom.uuid,
          "routing_key" => "celery" # Target Celery queue name
        },
        "priority" => 0,
        "correlation_id" => task_id
      }
    }

    # Push to the Celery queue in Redis
    self.redis.lpush("celery", envelope.to_json)

    if block_given?
      Async do
        result_key = "celery-task-meta-#{task_id}"

        result_data = nil
        # Loop or poll until the key exists and data is returned
        until result_data
          result_data = self.redis.get(result_key)
          if result_data
            parsed_result = JSON.parse(result_data)
            puts "Status: #{parsed_result['status']}"
          end
          sleep 1
        end
        redis.del(result_key)

        block.call parsed_result["result"]
      end
    end
  end
end
