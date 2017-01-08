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
  
  # Convert rt resource refs into Puppet format resource strings
  resources = args[0].is_a?(Array)? args[0] : [args[0]]
  resrefs = resources.map{|r| "#{r.split("-")[0].capitalize}[#{r.split("-")[1..-1].join("-")}]" }
  
  # Convert resource strings into resource objects
  Puppet::Parser::Functions.function(:string2resource)
  function_string2resource([resrefs])
end
