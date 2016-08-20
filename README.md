Resource Tree Puppet Module
===========================
A puppet swiss army knife, bridging the gap between code and configuration, making ad hoc modifications a bit more elegant.

Operating Principle
===================
Resource Tree is ideal for building simple collections of puppet resources, both user defined and [built-ins](https://docs.puppetlabs.com/references/latest/type.html), which have logical relationships to each other.

A trivial example of such a resource collection would be an `index.html` running on a standard apache server with a docroot of `/var/www/html`, requiring a total of three `file` resources, assuming that `/var` is a given.  Written briefly:

        File['/var/www']->File['/var/www/html']->File['/var/www/html/index.html']

Where the aformentioned `file` resource objects would be written in puppet code like so:

```ruby
file {
  '/var/www':
    ensure  => 'directory';
    
  '/var/www/html':
    ensure  => 'directory';
    
  '/var/www/html/index.html':
    content => 'hello world!',
    group   => 'apache',
    owner   => 'apache';
}
```

Resource Tree provides a method of building the same collection of `file` resources entirely in yaml, without creating a separate module:

```yaml
resource_tree::collections:
  'httpd_index_file': # collection
    file: # resource type
      '/var/www': # resource name
        ensure: 'directory' # resource parameter
      
      '/var/www/html': # resource name
        ensure: 'directory' # resource parameter
      
      '/var/www/html/index.html': # resource name
        content: 'hello world!' # resource parameter
        group: 'apache' # resource parameter
        owner: 'apache' # resource parameter
```

The collection would only be applied to a node if `resource_tree::apply`, an array, contains the value `httpd_index_file` in the local hiera scope.  This allows the author to have a shared set of Resource Tree collections, but only apply the desired collections to a given node.

Each resource in the tree implicitly requires any resources closer to the root of the tree, eg. `/var/www/html` implicitly requires `/var/www` in the previous example.

Resource tree allows three special parameters for each resource:
        
+ `rt_resources` - declare additional resources which require the current resource
+ `rt_requires` - explicitly require a resource_tree resource which is not parent to the current resource
+ `rt_notify` - notify a service, mount or exec declared in the catalog when current resource changes

Although Resource Tree enables users to do terrible blasphemous things to puppet, it's highly advisable to keep Resource Tree configurations short and sweet.  Avoid writing collections which would be better suited to a module.

Advanced Usage
==============
Resource Tree provides a number of advanced features so collections can be built dynamically.  Any individual resource definition, resource collection, or collection of child resources which is a string will be evaluated as ruby code, eg.

```yaml
resource_tree::collections:
  'resource_tree_advanced_examples':
    file:
      '/tmp/thetime.txt': |
        
        # Create a file containing just the time
        { 'content' => Time.now.to_s }
      
      '/tmp/test':
        ensure: 'directory'
        rt_resources: |
        
          # Create five files in /tmp/test
          { 'file' => 
            Hash[(1..5).map {|n|
              [
                "/tmp/test/test-file-#{n}",
                { "content" => rand(500).to_s }
              ]
            }]
          }
          
    host: |
      
      # Add five host entries
      Hash[(1..5).map {|n|
        [
          "test-node-0#{n}",
          {"ip" => "192.168.1.#{n}", "ensure" => "present" }
        ]
      }]
```

Additionally individual resource parameters can be evaluated by prefixing them with `rt_eval::` and parsed as yaml by prefixing the paramater name as `rt_parse`.
