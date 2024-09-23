# Convert one or more resource strings (eg. "File[foo]") into  a list of
# resource references.
#
# Similar to stdlib::str2resource, but if a resource is not found, a new
# reference will be created.
#
# The behavior provided is roughly equivalent to puppet DSL:
#
#     Resource["type","title"]
#
# Read more about puppet Type references here:
# https://www.puppet.com/docs/puppet/8/lang_data_resource_type.html#lang_data_resource_type_resource_type
#
# @example Parsing various string references
#
#   resref('File[/tmp]', 'Exec[daemon reload]') == [File["/tmp"], Exec["daemon reload"]]
#
Puppet::Functions.create_function(:'resource_tree::resref') do
  dispatch :resref do
    repeated_param 'String', :args
  end

  def resref(*args)
    args.map do |res|
      type_name, title = Puppet::Resource.type_and_title(res, nil)
      closure_scope.findresource(type_name, title) || Puppet::Resource.new(type_name, title)
    end
  end
end
