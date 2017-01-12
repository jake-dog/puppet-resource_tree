require 'puppet/parser/functions'

Puppet::Parser::Functions.newfunction(:resref,
                                      :type => :rvalue,
                                      :doc => <<-'ENDOFDOC'
Convert a dict of {type: title}, one or more resource strings (eg. "File[foo]"),
or one or more resource_tree style resource references (eg. "type-title") into
a list of resource references.

This function will first attempt to find the resource in the catalog, and return
the full resource reference as defined by puppet.  If the resource cannot be
found, it will create a blank resource and return it.

The behavior here should be roughly equivalent to the following in puppet DSL:

    Resource["type","title"]

If the user has only an individual string to convert into a resource ref, the
aforementioned method is faster and easier to read.

Read more about puppet Type references here:
https://docs.puppet.com/puppet/latest/lang_data_resource_type.html#examples-1
ENDOFDOC
) do |args|
  # our basic string resource reference structure
  RefString ||= Struct.new(:type, :title)

  # This will return a resource either by RefString struct, or string
  str2res = lambda {|rs|
    begin
      compiler.findresource(rs.type, rs.title) || Puppet::Resource.new(rs.type, rs.title)
    rescue
      # this use of Resource.new is valid per docs
      # https://docs.puppet.com/puppet/4.8/yard/Puppet/Resource.html
      compiler.findresource(rs) || Puppet::Resource.new(rs)
    end
  }

  # convert all args to list of RefString or resource string
  args.map{|res|
    if res.is_a? (Hash)
      # hash could include array or string args so we join them
      res.map{|k,v|
        v.is_a?(Array)? v.map{|e| RefString.new(k,e) } : RefString.new(k,v)
      }.flatten
    else
      # Convert whatever remains into an array
      (res.is_a?(Array)? res : [res]).map{|e|
        # regex is straight from puppetlabs, but with a dash at the end
        # https://docs.puppet.com/puppet/latest/lang_reserved.html#classes-and-defined-resource-types
        if e =~ /\A([a-z][a-z0-9_]*)?(::[a-z][a-z0-9_]*)*-/
          RefString.new(e.to_s.split("-")[0].capitalize, e.to_s.split("-")[1..-1].join("-"))
        elsif e.is_a?(Array)
          RefString.new(e[0].to_s.capitalize, e[1].to_s)
        else
          e
        end
      }
    end
  }.flatten.map {|refstring| str2res.call(refstring) }
end
