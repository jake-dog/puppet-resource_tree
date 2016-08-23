Puppet::Type.newtype(:placeholder) do
  @doc = %q{Creates a resource_tree::placeholder which
    implicitly requires the resource identified by
    the name parameter.  Although this is intended to
    be used internally by resource_tree, it may be
    useful for anyone writing abstract puppet code.
    
    As an example, the following puppet resources are
    functionally equivalent:
    
        file {'/tmp/test.txt':
              ensure => present,
              content => 'hello world',
              requires  => File['/tmp'],
        }
        
        file {'/tmp/test.txt':
              ensure => present,
              content => 'hello world',
              requires  => Resource_tree::Placeholder['file-/tmp'],
        }
    }
    
  newparam(:name) do
      desc "<type>-<name>"
  end
  
  autorequire(:"#{@resource[:name].split("-")[0]}") do
      self[:"#{@resource[:name].split("-")[1..-1].join("-")}"]
  end
end