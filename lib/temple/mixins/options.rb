module Temple
  module Mixins
    # @api public
    module DefaultOptions
      def set_default_options(opts)
        default_options.update(opts)
      end

      def default_options
        @default_options ||= OptionHash.new(superclass.respond_to?(:default_options) ?
                                            superclass.default_options : nil) do |hash, key, deprecated|
          unless @option_validator_disabled
            if deprecated
              puts "Option #{key.inspect} is deprecated by #{self}"
            else
              raise ArgumentError, "Option #{key.inspect} is not supported by #{self}"
            end
          end
        end
      end

      def define_options(*opts)
        if opts.last.respond_to?(:keys)
          hash = opts.pop
          default_options.add_valid_keys(hash.keys)
          default_options.update(hash)
        end
        default_options.add_valid_keys(opts)
      end

      def deprecated_options(*opts)
        if opts.last.respond_to?(:keys)
          hash = opts.pop
          default_options.add_deprecated_keys(hash.keys)
          default_options.update(hash)
        end
        default_options.add_deprecated_keys(opts)
      end

      def disable_option_validator!
        @option_validator_disabled = true
      end
    end

    module ThreadOptions
      def thread_options_key
        @thread_options_key ||= "#{self.name}-thread-options".to_sym
      end

      def with_options(opts)
        Thread.current[thread_options_key] = opts
        yield
      ensure
        Thread.current[thread_options_key] = nil
      end

      def thread_options
        Thread.current[thread_options_key]
      end
    end

    # @api public
    module Options
      def self.included(base)
        base.class_eval do
          extend DefaultOptions
          extend ThreadOptions
        end
      end

      attr_reader :options

      def initialize(opts = {})
        self.class.default_options.validate_hash!(opts)
        self.class.default_options.validate_hash!(self.class.thread_options) if self.class.thread_options
        @options = ImmutableHash.new(opts, self.class.thread_options, self.class.default_options)
      end
    end
  end
end
