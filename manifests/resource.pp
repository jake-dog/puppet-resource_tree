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
  $parsed_params = parseyaml(inline_template('<%= Hash[@params.keys[0], Hash[@params.values[0].map {|k,v| ((k.start_with? "rt_parse::") && [k[10..-1], YAML.load((((v.respond_to? :start_with?) && (v.start_with? "rt_eval::")) && eval(v[9..-1])) || v)]) || [k,(((v.respond_to? :start_with?) && (v.start_with? "rt_eval::")) && eval(v[9..-1])) || v] }]].to_yaml %>'))

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
      rt_resources($type, $parsed_params, { 'rt_require' => $rt_requires, 'notify' => $all_notify })
    } else {
      rt_resources($type, $parsed_params, { 'notify' => $all_notify })
    }
  } else {
    if $rt_requires {
      rt_resources($type, $parsed_params, { 'rt_require' => $rt_requires })
    } else {
      rt_resources($type, $parsed_params, {})
    }
  }
}
