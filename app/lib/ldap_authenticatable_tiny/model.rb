# typed: true
require 'devise/strategies/authenticatable'
module Devise
  module Models
    module LdapAuthenticatableTiny
      # Because Devise's session_controller#new
      # takes the authentication params and passes them along, we
      # get the user's password here.  So we need to implement
      # a method to handle this, but we only want to
      # pass this along to the LDAP request so we
      # don't persist the password anywhere even in memory, and this can't
      # be read back out.
      def password=(new_password) end

      # Similarly, we receive a login_text attribute from the form,
      # but we don't want to persist this on the model at all,
      # so we just accept this when Devise calls it and drop it.
      def login_text=(login_text) end

      # Same here
      def login_code=(login_code) end
    end
  end
end
