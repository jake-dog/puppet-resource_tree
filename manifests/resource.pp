define resource_tree::resource (
    type,
    params,
    rt_requires = nil,
    resources = nil,
) {
  
  if $resources {
      $uniq_resources = parseyaml(inline_template('<%= Hash[@resources.map {|k,v| Hash[v.map {|a,b| [k+"-"+a,{"type" => k, "rt_requires" => b.fetch("rt_requires",[]), "resources" => b.fetch("resources",nil),"params" => {a=>b.reject {|x,y| ["resources", "rt_requires"].include? x }}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, { 'require' => Resource_tree::Placeholder[$name] })
  }

  resource_tree::placeholder{ "$name": }
  
  if $rt_requires {
    create_resources(type, params, { 'before' => Resource_tree::Placeholder[$name], 'require' => Resource_tree::Placeholder[$rt_requires] })
  } else {
    create_resources(type, params, { 'before' => Resource_tree::Placeholder[$name] })
  }
}
