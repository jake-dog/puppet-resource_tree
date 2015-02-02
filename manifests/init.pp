class resource_tree (
  $collections       = {},
) {
  $allcollections = hiera_hash('resource_tree::collections', $collections)
  
  if $allcollections {
      $uniq_resources = parseyaml(inline_template('<%= @allcollections.values().inject({}) {|a,b| a.merge(b) }.map {|k,v| Hash[v.map {|a,b| [k+"-"+a,{"type" => k, "rt_notify" => b.fetch("rt_notify",nil), "rt_requires" => b.fetch("rt_requires",nil), "resources" => b.fetch("resources",nil),"params" => {a=>b.reject {|x,y| ["resources", "rt_requires", "rt_notify"].include? x }}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, {})
  }
}
