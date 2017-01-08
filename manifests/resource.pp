define resource_tree::resource (
    $type,
    $params,
    $rt_requires    = undef,
    $rt_notify      = undef,
    $rt_resources   = undef,
) {
  include stdlib
  
  if $rt_resources {
      $uniq_resources = parseyaml(template('resource_tree/resource.erb'))
      create_resources('resource_tree::resource', $uniq_resources)
  }
  
  # Allow arbitrary commands and nested yaml
  $parsed_params = parseyaml(template('resource_tree/param_parse.erb'))

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
      create_resources($type, $parsed_params, { 'rt_require' => rt_parse_resrefs($rt_requires), 'notify' => $all_notify })
    } else {
      create_resources($type, $parsed_params, { 'notify' => $all_notify })
    }
  } else {
    if $rt_requires {
      create_resources($type, $parsed_params, { 'rt_require' => rt_parse_resrefs($rt_requires) })
    } else {
      create_resources($type, $parsed_params, {})
    }
  }
}
