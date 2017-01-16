define resource_tree::resource (
    $type,
    $params,
    $rt_before      = [],
    $rt_subscribe   = [],
    $rt_requires    = [],
    $rt_notify      = [],
    $rt_resources   = undef,
) {
  include stdlib

  if $rt_resources {
      $uniq_resources = parseyaml(template('resource_tree/resource.erb'))
      create_resources('resource_tree::resource', $uniq_resources)
  }

  # Allow arbitrary commands and nested yaml
  $parsed_params = parseyaml(template('resource_tree/param_parse.erb'))

  # Parse before/subscribe/notify
  if !empty($rt_before) {
    $before = resref($rt_before)
  } else {
    $before = []
  }
  if !empty($rt_subscribe) {
    $subscribe = resref($rt_subscribe)
  } else {
    $subscribe = []
  }
  if !empty($rt_notify) {
    $notify = resref($rt_notify)
  } else {
    $notify = []
  }
  if !empty($rt_requires) {
    $require = resref($rt_requires)
  } else {
    $require = []
  }

  create_resources($type, $parsed_params, {
    'require' => $require, 'notify' => $notify,
    'subscribe' => $subscribe, 'before' => $before })
}
