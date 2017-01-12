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

  # Parse require/before/subscribe/notify in resource_tree >=1.0.0 style
  if has_key($params, 'before') {
    $before = resref($parsed_params['before'])
  } else {
    $before = []
  }
  if has_key($params, 'require') {
    $require = resref($parsed_params['require'])
  } else {
    $require = []
  }
  if has_key($params, 'notify') {
    $notify = resref($parsed_params['notify'])
  } else {
    $notify = []
  }
  if has_key($params, 'subscribe') {
    $subscribe = resref($parsed_params['subscribe'])
  } else {
    $subscribe = []
  }

  # Pre-1.0 support
  if $rt_notify {
    $all_notify = concat(resref($rt_notify), $notify)
  } else {
    $all_notify = $notify
  }
  if $rt_requires {
    $all_require = concat(resref($rt_requires), $require)
  } else {
    $all_require = $require
  }

  create_resources($type, delete($parsed_params, ['require', 'subscribe', 'notify', 'before']),
                   { 'require' => $all_require, 'notify' => $all_notify,
                     'subscribe' => $subscribe, 'before' => $before })
}
