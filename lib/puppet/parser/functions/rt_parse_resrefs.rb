require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:rt_parse_resrefs,
                                      :type => :rvalue,
                                      :doc => <<-'ENDOFDOC'
Convert a list of Resource Tree style resource references of the format
"<type>-<name>" into Puppet resource references using the string2resource
function.
ENDOFDOC
) do |args|
  raise ArgumentError, ("rt_parse_resrefs(): wrong number of arguments (#{args.length}; must be 1)") if args.length > 1

  # Handle rt_resource refs as a hash (would usually be handled via
  # stdlib join_keys_to_values but behavior we want was introduced
  # only in version 4.14.0)
  if args[0].is_a?(Hash)
    args[0] = args[0].map{|k,v|
      v.is_a?(Array)?  v.map{|e| "#{k}-#{e}" } : "#{k}-#{v}"
    }.flatten
  end

  # Convert rt resource refs into Puppet format resource strings
  resources = args[0].is_a?(Array)? args[0] : [args[0]]
  resrefs = resources.map{|r| "#{r.split("-")[0].capitalize}[#{r.split("-")[1..-1].join("-")}]" }
  
  # Convert resource strings into resource objects
  Puppet::Parser::Functions.function(:string2resource)
  function_string2resource([resrefs])
end
