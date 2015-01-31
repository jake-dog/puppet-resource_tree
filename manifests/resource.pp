define resource_tree::resource (
    type,
    params,
    resources = nil,
) {
  
  if $resources {
      $uniq_resources = parseyaml(inline_template('<%= Hash[@resources.map {|k,v| Hash[v.map {|a,b| [k+"-"+a,{"type" => k, "resources" => b.fetch("resources",nil),"params" => {a=>b.reject {|x,y| x=="resources"}}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, { 'require' => Resource_tree::Marker[$name] })
  }

  resource_tree::marker{ "$name": }
  create_resources(type, params, { 'before' => Resource_tree::Marker[$name] })
}
