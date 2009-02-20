require 'active_record'

module SuidBit
  module RelationalScope
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def has_relational_scope(relation, options = {})
        klass = (options[:class_name] ? options[:class_name] : reflections[relation].class_name).to_s.classify.constantize
        prefix = (options[:prefix] || relation).to_s

        klass.scopes.keys.each do |scope|
          named_scope "#{prefix}_#{scope}", lambda {|*args|
            with_relational_scope self, relation, klass, scope, args
          }
        end
      end

      protected
      def with_relational_scope(parent_scope, relation, klass, scope, args)
        options = klass.send(scope, *args).proxy_options

        # need to setup the includes to properly link
        case options[:include]
        when Hash, Array
          options[:include] = [{klass.table_name => options[:include]}]
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
end
