# Test whether a given class or definition is defined
require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:rt_resources,
                                      :type => :statement,
                                      :doc => <<-'ENDOFDOC'
This is a thin wrapper on top of the default 'create_resources' function
which accepts Resource Tree parameters 'rt_requires' and 'rt_subscribes'
and converts them into appropriate Puppet Resource references.

For any concerns about the behavior of this function, read up the
'create_resources' documentation, and Resource Tree documentation.
ENDOFDOC
) do |args|
  raise ArgumentError, ("rt_resources(): wrong number of arguments (#{args.length}; must be 2 or 3)") if args.length > 3
  raise ArgumentError, ('rt_resources(): second argument must be a hash') unless args[1].is_a?(Hash)
  if args.length == 3
    raise ArgumentError, ('rt_resources(): third argument, if provided, must be a hash') unless args[2].is_a?(Hash)
  end

  type, instances, defaults = args
  defaults ||= {}
  metaparams = ['require', 'subscribe']
  metaparams.each {|m|
    defaults[m] = [defaults.fetch("rt_#{m}",[])].flatten.map {|rt_resref|
      rtype = rt_resref.split("-")[0]
      rtitle = rt_resref.split("-")[1..-1].join("-")
      Puppet::Resource.new(
        rtype.capitalize, rtitle,
      )
    }
  }
  Puppet::Parser::Functions.function(:create_resources)
  function_create_resources([
    type, instances,
    defaults.delete_if {|k,v| metaparams.map{|m| "rt_#{m}"}.include? k }
  ])
end
