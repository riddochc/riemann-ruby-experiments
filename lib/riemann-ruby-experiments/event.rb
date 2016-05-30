module Riemann::Experiment
  class Event
    attr_accessor :attribute_names
    attr_accessor :protobuf

    # Provide defaults on initialization
    def initialize()
      @attrs = []
      @cached_attrs = {}
    end

    def setup(client)
      @service = client&.default_service
      @host = client&.default_host
      @tags = client&.default_tags
      @ttl = client&.default_ttl
      @protobuf = ::Event.new
    end

    def build(**fields)
      fields.each_pair {|k, v|
        self.send("#{k}=".to_sym, v)
      }
    end

    def self.load(pb)
      e = self.new()
      if !pb.is_a?(::Event)
        raise ArgumentError, "Not an Event protocol buffer object"
      end
      e.protobuf = pb
      pb.attributes.each {|a|
        e.attribute_set(a.key, a.value)
      }
      e
    end

    def attribute_set(name, value)
      if attribute_get_value(name)
        a = protobuf.attributes&.detect {|a| a.key == name }
        a.value = value
      else
        a = Attribute.new
        a.key = name
        a.value = value
        protobuf.attributes << a
      end
      @cached_attrs[name] = value
    end

    def attribute_get_value(name)
      @cached_attrs.fetch(name) {
        a = protobuf.attributes&.detect {|a| a.key == name }
        if !a.nil?
          @cached_attrs[name] = a.value
          retval = a.value
        else
          retval = yield(name) if block_given?
        end
        retval
      }
    end

    def each_attribute
      return enum_for(:each_attribute) unless block_given?
      protobuf.attributes.each {|a|
        yield(a.key, a.value)
      }
    end

    def time=(time)
      case time
      when ::Time
        protobuf.time = time.to_i
      when ::DateTime
        protobuf.time = time.to_time.to_i
      else
        protobuf.time = time
      end
    end

    def time
      Time.at(protobuf.time)
    end

    def service=(service)
      protobuf.service = service.to_s
    end

    def service
      s = protobuf.service
      (s != "") ? s : nil
    end

    def state=(s)
      protobuf.state = s
    end

    def state
      s = protobuf.state
      (s != "") ? s : nil
    end

    def host=(host)
      protobuf.host = host.to_s
    end

    def host
      h = protobuf.host
      h != "" ? h : nil
    end

    def description=(d)
      protobuf.description = d.to_s
    end

    def description
      d = protobuf.description
      d != "" ? d : nil
    end

    def ttl=(ttl)
      protobuf.ttl = ttl.to_f
    end

    def ttl
      t = protobuf.ttl
      t != "" ? t : nil
    end

    def add_tags(*tags)
      @tags = [] if @tags.nil?
      tags.each {|t| @tags.push(t.to_s) }
    end

    def tags
      protobuf.tags
    end

    def metric=(m)
      case m
      when Integer
        protobuf.metric_sint64 = m
      when Float
        protobuf.metric_d = m
      end  # BigDecimal? Anything else?
    end

    def metric
      protobuf.metric_sint64 || protobuf.metric_d || protobuf.metric_f
    end

    def maybe_apply_defaults
      if protobuf.service == ""
        @service ||= "#{$0};#{$PID}"
        protobuf.service = @service
      end
      if protobuf.host == ""
        protobuf.host = @host
      end

      if !@tags.nil?
        protobuf.tags = @tags
      end
      if !@ttl.nil?
        protobuf.ttl = @ttl
      end
    end

    def to_s
      maybe_apply_defaults
      protobuf.to_s
    end

    alias_method :to_sym, :to_s
    alias_method :dump, :to_s

    def respond_to?(m, include_private = false)
      ms = m.to_s
      mnoeq = ms[0..-2]
      if ms.end_with?("=") && ms.length >= 2
        true
      elsif attribute_get_value(ms)
        true
      else
        super
      end
    end

    def method_missing(m, *rest, &blk)
      ms = m.to_s
      if ms.end_with?("=") && ms.length >= 2
        attribute_set(ms[0..-2], rest.first.to_s)
      else
        val = attribute_get_value(ms)
        if val.nil?
          super
        else
          val
        end
      end
    end
  end
end
 
