# encoding: utf-8
require 'warden'
require 'base64'

module TiRailsAuth
  # Support for grants HTTP header authentication in Warden
  class GrantsHeaderAuthenticable < ::Warden::Strategies::Base

    attr_accessor :grants
    attr_accessor :email

    def valid?
      email! && grants!
    end

    def authenticate!
      resource = email && Config.model.find_by_email(email)
      if resource
        if resource.respond_to? :controls=
          resource.controls = grants['controls']
        end
        if resource.respond_to? :preferences=
          resource.preferences = grants['preferences']
        end
        success! resource
      else
        fail!
      end
    end

    private

    def grants_header
      request.env['HTTP_X_GRANTS']
    end

    def from_header
      request.env['HTTP_FROM']
    end

    def grants!
      self.grants ||= if grants_header
                        begin
                          header = ActiveSupport::JSON.decode Base64.decode64(grants_header)
                          if header && header['grants'] && header['grants'].first && header['grants'].first.is_a?(Hash)
                            header['grants'].first
                          end
                        rescue ActiveSupport::JSON.parse_error
                          nil
                        end
                      end
    end

    def email!
      self.email ||= from_header
    end
  end
end
