class resource_tree (
  $collections    = {},
  $apply          = [],
) {
  $allcollections = hiera_hash('resource_tree::collections', $collections)
  $allapply = hiera_array('resource_tree::apply', $apply)
  
  if is_hash($allcollections) and is_array($allapply) and (size(intersection($allapply, keys($allcollections))) > 0) {
      $uniq_resources = parseyaml(template('resource_tree/main.erb'))
      create_resources('resource_tree::resource', $uniq_resources, {})
  }
}
