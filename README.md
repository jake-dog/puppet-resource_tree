# resource_tree

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://github.com/jake-dog/puppet-resource_tree/blob/master/LICENSE)
![tests](https://github.com/jake-dog/puppet-resource_tree/actions/workflows/pdk-test-unit.yml/badge.svg?branch=master)

#### Table of Contents

1. [Overview](#overview)
2. [Motivation](#motivation)
3. [Operating Principle and Examples](#operating-principle)
4. [Relationship Metaparameters and Resource References](#relationship-metaparameters-and-resource-references)
5. [Default Parameters](#default-parameters)
6. [Advanced Usage](#advanced-usage)
7. [Crazy Advanced Usage](#crazy-advanced-usage)
8. [Legacy (pre-1.0.0) Support](#legacy-support)
9. [Reference](#reference)

## Overview

A puppet swiss army knife, bridging the gap between code and configuration, making ad hoc modifications a bit more elegant.

## Motivation

Most modern puppet deployments are composed of puppetlabs/r10k, hiera and an external node classifier.  Although the design is powerful and versioned, it doesn't leave much room for the reality of ad hoc configurations.  Often times puppet users find themselves adding a module, or editing an existing module, just to create a file or add a single package, which leads to an r10k push to multiple environments.  The addition of a single missing resource can result in several commits, new repositories and changes to production environments.

Resource Tree drastically reduces the complexity of ad hoc configurations in puppet by providing a simple mechanism to define puppet resources, and relationships between those resources, entirely in hieradata.

Of course Resource Tree's capabilities extend far beyond defining individual resources, enabling users to do terrible blasphemous things to puppet.  Therefore it is highly advisable to keep Resource Tree configurations short and sweet, and avoid writing collections which would be better suited to a module.

## Operating Principle

Resource Tree is ideal for building simple collections of puppet resources, both user defined and [built-ins](https://www.puppet.com/docs/puppet/7/cheatsheet_core_types), which have logical relationships to each other.

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
  httpd_index_file:               # collection
    file:                         # resource type
      '/var/www':                 # resource name
        ensure: 'directory'       # resource parameter
      
      '/var/www/html':            # resource name
        ensure: 'directory'       # resource parameter
      
      '/var/www/html/index.html': # resource name
        content: 'hello world!'   # resource parameter
        group: 'apache'           # resource parameter
        owner: 'apache'           # resource parameter
```

The collection would only be applied to a node if `resource_tree::apply`, an array, contains the value `httpd_index_file` in the local hiera scope.  This allows the author to have a shared set of Resource Tree collections, but only apply the desired collections to a given node.  For instance:

```yaml
resource_tree::apply:
  - httpd_index_file
```

Each resource in the tree may optionally contain an `rt_resources` parameter, where any included resources implicitly require those closer to the root of the tree.  For instance in the following example an apache configuration file and service implicitly require the httpd package:

```yaml
resource_tree::collections:
  apache:
    package:
      'httpd':
        ensure: 'installed'
        rt_resources:
          service:
            'httpd':
              ensure: 'running'
          file:
            '/etc/httpd/conf.d/status.load':
              ensure: 'present'
              owner: 'apache'
              group: 'apache'
              content: 'LoadModule status_module "modules/mod_status.so"'
              notify: 'Service[httpd]'
```

Relationships between resources in the tree can also be explicitly defined using the `require` parameter.  For instance the previous example could be rewritten with explicit relationships:

```yaml
resource_tree::collections:
  apache:
    package:
      'httpd':
        ensure: 'installed'
    service:
      'httpd':
        ensure: 'running'
        require: 'Package[httpd]'
    file:
      '/etc/httpd/conf.d/status.load':
        ensure: 'present'
        owner: 'apache'
        group: 'apache'
        content: 'LoadModule status_module "modules/mod_status.so"'
        require: 'Package[httpd]'
        notify: 'Service[httpd]'
```

## Relationship Metaparameters and Resource References

Resource Tree supports the four puppet relationship metaparameters: [before, require, notify and subscribe](https://www.puppet.com/docs/puppet/7/lang_relationships.html#lang_rel_metaparameters).  Multiple resource strings can be passed as an array.

```yaml
resource_tree::collections:
  remove_default_sysctl:
    file:
      '/etc/sysctl.d/99-sysctl.conf':
        ensure: 'absent'

        # Single resource relationship
        require: 'Package[puppet]'

        # Multiple resource relationship
        notify:
          - 'Service[puppet]'
          - 'Exec[reload sysctl]'
```

For more information, refer to the `resource_tree::resref` function documentation.

## Default Parameters

Users may provide [default parameters](https://www.puppet.com/docs/puppet/7/lang_defaults.html) for resources declared via Resource Tree.  This can greatly reduce repetition of parameters when declaring many resources of the same type.

In puppet we would define default parameters for `Package` resources like so:

```ruby
Package {
  provider => 'dnf'
}
```

In Resource Tree we would declare it similarly:

```yaml
resource_tree::default_params:
  package:
    provider: 'dnf'
```

*Note:* Relationship metaparameters are not supported as default parameters.

## Advanced Usage

Resource Tree provides a number of advanced features so collections can be built dynamically.  Any resource definition or collection, whose value is a string, will be evaluated as ruby code.  Individual resource parameters can also be evaluated as ruby code when prefixed with `rt_eval::`.

```yaml
resource_tree::collections:
  advanced_examples:

    # Set the irqbalance service as running on multicore systems
    service:
      irqbalance: |
        if @processorcount > 1
          { 'ensure' => 'running' }
        else
          {
            'ensure' => 'stopped',
            'enable' => 'false',
          }
        end

    file:

      # Create a file which contains the time when puppet last ran
      '/tmp/thetime.txt':
        content: 'rt_eval::Time.now.to_s'
      
      '/tmp/test':
        ensure: 'directory'
        rt_resources: |
        
          # Create five files in /tmp/test, each with a random number
          {
            'file' => (1..5).map { |n|
              [
                "/tmp/test/test-file-#{n}",
                { 'content' => rand(500).to_s },
              ]
            }.to_h
          }
          
    host: |
      
      # Add five host entries
      (1..5).map { |n|
        [
          "test-node-0#{n}",
          { 'ip' => "192.168.1.#{n}", 'ensure' => 'present' },
        ]
      }.to_h
```

Calling puppet functions from ERB usually requires a [complex syntax](https://www.puppet.com/docs/puppet/7/lang_template_erb#puppet_functions_templates).  Resource Tree provides four common functions with their traditional puppet syntax: `lookup`, `inline_template`, `inline_epp` and `puppetdb_query`.  The special function `ptype` can be used to evaluate [puppet data type](https://www.puppet.com/docs/puppet/7/lang_data_type.html) strings.

## Crazy Advanced Usage

A few intrepid users have discovered interesting ways to combine Resource Tree and ruby to dynamically create resources, including querying puppetdb to find members for proxies/load-balancers.  Here are a few tricks that tip the scales for what Resource Tree can do.

#### Emulating [`include`](https://www.puppet.com/docs/puppet/7/function.html#include)

```yaml
# Similar to: lookup('classes', Array[String], 'unique').include
resource_tree::collections:
  hiera_include:
    class: |
      lookup('classes', ptype('Array[String]'), 'unique').reject{|c| c == 'resource_tree'}.map {|c| {c => {}} }.reduce({}, :merge)
```

#### Using PuppetDB to discover puppetlabs/puppetlabs-haproxy balancer members

```yaml
resource_tree::collections:
  haproxy_webservers:
    haproxy::balancermember: |
      node_query = 'inventory[certname,facts.ipaddress]{ environment = "%{environment}" and app = "webserver" }'
      member_ip_by_cert = puppetdb_query(node_query).map{|fact|
        { fact['certname'] => fact['facts.ipaddress'] }
      }.reduce({}, :merge)
      {
        'webservers' => {
          'listening_service' => 'webservers',
          'ports'             => '80',
          'server_names'      => member_ip_by_cert.keys.sort.map{|h| h.split('.')[0] },
          'ipaddresses'       => member_ip_by_cert.keys.sort.map{|h| member_ip_by_cert[h] },
          'options'           => [ 'check' ]
        }
      }
```

#### Creating multiple files with templates

```yaml
# Puppet scope for inline_template requires "call_function" syntax.
# "@name" is the resource name, eg. 'file[/etc/sysctl.d/10-tcpmem.conf]'
sysctl_config_template: |
  <% config = scope.call_function('lookup', ['sysctld']).fetch(@name[19..-7], {}) -%>
  <% config.each do |k,v| -%>
  <%= k %> = <%= v.to_s %>
  <% end -%>

sysctld:
  '10-tcpmem':
    net.ipv4.tcp_rmem: '131072 524288 16777216'
    net.ipv4.tcp_wmem: '131072 524288 16777216'
  '20-tcpconn':
    net.core.somaxconn: '32768'
    net.ipv4.tcp_max_syn_backlog: '32768'
    net.ipv4.tcp_max_tw_buckets: '2000000'

resource_tree::collections:
  sysctl_configs:
    file: |
      Hash[lookup('sysctld', ptype('Hash'), 'hash').map {|k,v|
        [
          "/etc/sysctl.d/#{k}.conf",
          {
            'ensure'  => 'present',
            'owner'   => 'root',
            'group'   => 'root',
            'content' => 'rt_eval::inline_template(lookup("sysctl_config_template"))',
          }
        ]
      }]
```

## Legacy Support

The `str2resource` function was added to puppet stdlib in v8.2.0 and set the standard for defining puppet resources as strings.  Resource Tree v2.0+ now exclusively utilizes this resource string format, and the different syntax options available in prior versions are no longer supported.  Relationship metaparameters therefore must be either a resource string, or list of resource strings.  The `resref` function is now namespaced to `resource_tree::resref`.

Internally the `rt_requires` parameter is now `rt_require`, to more closely mimic the relationship metaparameter it represents.  Users should use the standard set of relationship metaparameters when defining resource collections via hiera, specifically `before`, `require`, `notify` and `subscribe`.  The pre-v1.0 `rt_*` format of relationship metaparameters in hiera is no longer supported.
