require 'active_record'

module SuidBit
  module RelationalScope
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def has_relational_scoping(relation, *args)
        options = args.is_a?(Hash) ? args.pop : {}

        klass = (options[:class_name] ? options[:class_name] : relation).to_s.classify.constantize
        prefix = options[:prefix] or relation.to_s

        klass.scopes.keys.each do |scope|
          (class << self ; self end).instance_eval do
            define_method "#{prefix}_#{scope}" do |*args|
              with_relational_scope relation, klass, scope, options
            end
          end
        end
      end
    end

    protected
    def with_relational_scope(relation, klass, scope, args)
      options = klass.send(scope, *args).proxy_options

      # need to setup the includes to properly link
      case options[:include]
      when Hash, Array
        options[:include] = [{relation => options[:include]}]
      when NilClass
        options[:include] = [relation]
      end

      # conditions need to be string to ensure we get one query
      # hash conditions with includes dont always join the table
      # and the query crashes if conditions uses them
      # so we take the time now to sanitize them into strings
      case options[:conditions]
        when Array ; options[:conditions] = sanitize_sql_array options[:conditions]
        when Hash  ; options[:conditions] = sanitize_sql_hash_for_conditions options[:conditions], klass.table_name
      end

      options
    end
  end
end
