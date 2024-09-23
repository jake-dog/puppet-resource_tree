# @summary
#   Create a puppet resource with resource_tree
#
# @param type
#   Set the resource type
#
# @param params
#   Set the parameters to be passed
#
# @param rt_before
#   Set the "before" relationship metaparameter
#
# @param rt_subscribe
#   Set the "subscribe" relationship metaparameter
#
# @param rt_require
#   Set the "require" relationship metaparameter
#
# @param rt_notify
#   Set the "notify" relationship metaparameter
#
# @param rt_resources
#   Set resources as requiring this resource
#
define resource_tree::resource (
  String $type,
  Hash $params,
  Variant[String[1], Array[String[1]]] $rt_before    = [],
  Variant[String[1], Array[String[1]]] $rt_subscribe = [],
  Variant[String[1], Array[String[1]]] $rt_require   = [],
  Variant[String[1], Array[String[1]]] $rt_notify    = [],
  Optional[Variant[Hash, String]] $rt_resources      = undef,
) {
  if $rt_resources {
    $uniq_resources = parseyaml(template('resource_tree/resource.erb'))
    create_resources('resource_tree::resource', $uniq_resources)
  }

  # Allow arbitrary commands and nested yaml
  $parsed_params = parseyaml(template('resource_tree/param_parse.erb'))

  # Parse before/subscribe/notify
  if !empty($rt_before) {
    $before = resource_tree::resref(*$rt_before)
  } else {
    $before = []
  }
  if !empty($rt_subscribe) {
    $subscribe = resource_tree::resref(*$rt_subscribe)
  } else {
    $subscribe = []
  }
  if !empty($rt_notify) {
    $notify = resource_tree::resref(*$rt_notify)
  } else {
    $notify = []
  }
  if !empty($rt_require) {
    $require = resource_tree::resref(*$rt_require)
  } else {
    $require = []
  }

  create_resources($type, $parsed_params, {
      'require' => $require, 'notify' => $notify,
      'subscribe' => $subscribe, 'before' => $before
  })
}
