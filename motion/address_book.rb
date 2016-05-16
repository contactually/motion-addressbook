module AddressBook
  class << self
    attr_accessor :auto_connect

    def instance
      Dispatch.once { @contact_accessor ||= contact_accessor(auto_connect) }
      @contact_accessor
    end

    def respond_to?(method_name, include_private = false)
      instance.respond_to?(method_name, include_private) || super
    end

    def framework_as_sym
      case UIDevice.currentDevice.systemVersion.to_i
      # Use ABAddressBook (iOS < 9) - https://goo.gl/2Xbebu
      when 6, 7, 8 then :ab
      # Use CNContact (iOS >= 9) - https://goo.gl/RDAlRw
      when 9 then :cn
      else raise "This iOS is not supported by motion-addressbook"
      end
    end

    def authorized?
      auth_handler.granted?
    end

    # Will return one of the following:
    # :not_determined, :restricted, :denied, :authorized
    def authorization_status
      auth_handler.status
    end

    private

    def contact_accessor(autoconnect)
      # OSX
      return ABAddressBook.addressBook if Kernel.const_defined? :NSApplication

      # iOS
      contact_accessor.new(autoconnect)
    end

    def contact_accessor
      case framework_as_sym
      when :ab then AB::AddressBook
      when :cn then CN::ContactStore
      end
    end

    def auth_handler
      case framework_as_sym
      when :ab then AB::Authorization
      when :cn then CN::Authorization
      end
    end

    def method_missing(method_name, *args, &block)
      return super unless instance.respond_to?(method_name)
      instance.send(method_name, *args, &block)
    end
  end
end
