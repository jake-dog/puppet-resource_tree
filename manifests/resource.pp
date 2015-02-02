define resource_tree::resource (
    $type,
    $params,
    $rt_requires = undef,
    $rt_notify = undef,
    $resources = undef,
) {
  include stdlib
  
  if $resources {
      $uniq_resources = parseyaml(inline_template('<%= @resources.map {|k,v| Hash[v.map {|a,b| [k+"-"+a,{"type" => k, "rt_notify" => b.fetch("rt_notify",nil), "rt_requires" => b.fetch("rt_requires",nil), "resources" => b.fetch("resources",nil),"params" => {a=>b.reject {|x,y| ["resources", "rt_requires", "rt_notify"].include? x }}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, { 'require' => Resource_tree::Placeholder[$name] })
  }

  resource_tree::placeholder{ "$name": }
  
  if $rt_notify {
    if has_key($rt_notify, 'exec') {
      $exec_notify = [Exec[$rt_notify['exec']]]
    } else {
      $exec_notify = []
    }
    
    if has_key($rt_notify, 'mount') {
      $mount_notify = [Mount[$rt_notify['mount']]]
    } else {
      $mount_notify = []
    }
    
    if has_key($rt_notify, 'service') {
      $service_notify = [Service[$rt_notify['service']]]
    } else {
      $service_notify = []
    }
    
    $all_notify = concat(concat($exec_notify,$mount_notify),$service_notify)
    
    if $rt_requires {
      create_resources($type, $params, { 'before' => Resource_tree::Placeholder[$name], 'require' => Resource_tree::Placeholder[$rt_requires], 'notify' => $all_notify })
    } else {
      create_resources($type, $params, { 'before' => Resource_tree::Placeholder[$name], 'notify' => $all_notify })
    }
  } else {
    if $rt_requires {
      create_resources($type, $params, { 'before' => Resource_tree::Placeholder[$name], 'require' => Resource_tree::Placeholder[$rt_requires] })
    } else {
      create_resources($type, $params, { 'before' => Resource_tree::Placeholder[$name] })
    }
  }
}
