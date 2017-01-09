require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:string2resource,
                                      :type => :rvalue,
                                      :doc => <<-'ENDOFDOC'
Convert a type and name (eg. ["file", "foo"]), a resource string (eg. "File[foo]"),
or a list of resource strings into Puppet resources.  This function will first
attempt to find the resource in the catalog, and return the full resource reference
as defined by puppet.  If the resource cannot be found, it will create a blank
resource and return it.
ENDOFDOC
) do |args|
  raise ArgumentError, ("string2resource(): wrong number of arguments (#{args.length}; must be 1 or 2)") if args.length > 2
  if args.length == 2
    compiler.findresource(args[0].to_s.capitalize, args[1].to_s) || Puppet::Resource.new(args[0].to_s.capitalize, args[1].to_s)
  else
    if args[0].is_a?(Array)
      args[0].reduce([]) {|memo,resref|
        ref = compiler.findresource(resref.to_s) || Puppet::Resource.new(resref.split("[")[0], resref.split("[")[1..-1].join("[").rstrip()[0..-2])
        memo << ref
      }
    else
      compiler.findresource(args[0].to_s) || Puppet::Resource.new(args[0].split("[")[0], args[0].split("[")[1..-1].join("[").rstrip()[0..-2])
    end
  end
end
