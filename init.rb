require 'suid_bit/relational_scope'
ActiveRecord::Base.send :include, SuidBit::RelationalScope
