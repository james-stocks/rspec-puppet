module Puppet
  # Allow rspec-puppet to prevent Puppet::Type from automatically picking
  # a provider for a resource. We need to do this because in order to fully
  # resolve the graph edges, we have to convert the Puppet::Resource objects
  # into Puppet::Type objects so that their autorequires are evaluated. We need
  # to prevent provider code from being called during this process as it's very
  # platform specific.
  class Type
    old_set_default = instance_method(:set_default)

    define_method(:set_default) do |attr|
      return if attr == :provider && self.class.suppress_provider?
      old_set_default.bind(self).call(attr)
    end

    def self.suppress_provider?
      @suppress_provider ||= false
    end

    def self.suppress_provider
      @suppress_provider = true
    end

    def self.unsuppress_provider
      @suppress_provider = false
    end
  end

  module Util
    # Allow rspec-puppet to pretend to be windows.
    module Platform
      def windows?
        pretend_windows? || !!File::ALT_SEPARATOR
      end
      module_function :windows?

      def pretend_windows?
        @pretend_windows ||= false
      end
      module_function :pretend_windows?

      def pretend_windows
        @pretend_windows = true
      end
      module_function :pretend_windows

      def unpretend_windows
        @pretend_windows = false
      end
      module_function :unpretend_windows
    end
  end
end

# Prevent Puppet from requiring 'puppet/util/windows' if we're pretending to be
# windows, otherwise it will require other libraries that probably won't be
# available on non-windows hosts.
module Kernel
  alias :old_require :require
  def require(path)
    return if path == 'puppet/util/windows' && Puppet::Util::Platform.pretend_windows?
    old_require(path)
  end
end