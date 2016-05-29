module Riemann::Experiment
  class Event
    # Provide defaults on initialization
    def initialize(client)
      @service = client&.default_service
      @host = client&.default_host
      @tags = client&.default_tags
      @ttl = client&.default_ttl
      @e = ::Event.new
      @attrs = []
    end

    def build(**fields)
      fields.each_pair {|k, v|
        self.send("#{k}=".to_sym, v)
      }
    end

    def time=(time)
      @e.time = time.to_i
    end

    def service=(service)
      @e.service = service.to_s
    end

    def host=(host)
      @e.host = host.to_s
    end

    def description=(d)
      @e.description = d.to_s
    end

    def ttl=(ttl)
      @e.ttl = ttl.to_f
    end

    def tags=(tags)
      @tags = [] if @tags.nil?
      tags.each {|t| @tags.push(t.to_s) }
    end

    def metric=(m)
      case m
      when Integer
        @e.metric_sint64 = m
      when Float
        @e.metric_d = m
      end  # BigDecimal? Anything else?
    end

    def maybe_apply_defaults
      if @e.service == ""
        @e.service = @service || "#{$0};#{$PID}"
      end
      if @e.host == ""
        @e.host = @host
      end

      if !@tags.nil?
        @e.tags = @tags.to_a
      end
      if !@ttl.nil?
        @e.ttl = @ttl
      end
    end

    def protobuf
      @e
    end

    def respond_to?(m, include_private = false)
      ms = m.to_s
      ms.end_with?("=") && ms.length >= 2
    end

    def method_missing(m, *rest, &blk)
      ms = m.to_s
      if ms.end_with?("=") && ms.length >= 2
        a = Attribute.new
        a.key = ms[0..-2]
        a.value = rest.first
        @e.attributes << a
      else
        super
      end
    end
  end
end
 
