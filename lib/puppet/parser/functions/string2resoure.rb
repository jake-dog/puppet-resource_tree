require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:string2resource,
                                      :type => :statement,
                                      :doc => <<-'ENDOFDOC'
Convert a resource string (eg. "File[foo]"), a type and name (eg. ["file", "foo"]),
or a list of resource strings into Puppet resources.
ENDOFDOC
) do |args|
  raise ArgumentError, ("string2resource(): wrong number of arguments (#{args.length}; must be 1 or 2)") if args.length > 2
  if args.length == 2
    compiler.findresource(args[0].to_s, args[1].to_s)
  else
    if args[0].is_a?(Array)
      args[0].reduce([]) {|memo,resref|
        memo << compiler.findresource(resref.to_s)
      }
    else
      compiler.findresource(args[0].to_s)
    end
  end
end