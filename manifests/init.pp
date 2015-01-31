class resource_tree (
  $collections       = {},
) {
  $allcollections = hiera_hash('resource_tree::collections', $collections)
  
  if $allcollections {
      $uniq_resources = parseyaml(inline_template('<%= Hash[@allcollections.values().inject({}) {|a,b| a.merge(b) }.map {|k,v| Hash[v.map {|a,b| [k+"-"+a,{"type" => k, "resources" => b.fetch("resources",nil),"params" => {a=>b.reject {|x,y| x=="resources"}}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, {})
  }
}
