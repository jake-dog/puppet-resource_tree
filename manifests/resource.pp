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

  # We gotta do something special with rt_requires due to implicit
  # requirements in the resource tree in hiera.  In the event that the
  # resource being created has an implicit parent, rt_requires will
  # have 2 elements, where the second element is the parent resource
  # specified in resource_tree reference style.
  if !empty($rt_requires) {
    if size($rt_requires) > 1 {
      $require = resref($rt_requires[0], $rt_requires[1])
    } else {
      $require = resref($rt_requires[0])
    }
  } else {
    $require = []
  }

  create_resources($type, $parsed_params,
                   { 'require' => $require, 'notify' => $notify,
                     'subscribe' => $subscribe, 'before' => $before })
}
