class resource_tree (
  $collections       = {},
  $apply = [],
) {
  $allcollections = hiera_hash('resource_tree::collections', $collections)
  $allapply = hiera_array('resource_tree::apply', $apply)
  
  if is_hash($allcollections) and is_array($allapply) and (size(intersection($allapply, keys($allcollections))) > 0) {
      $uniq_resources = parseyaml(inline_template('<%= @allcollections.reject {|k,v| !(@allapply.include? k) }.map{|k,v| ((v.to_s == v) && eval(v)) || v }.inject({}) {|a,b| a.merge(Hash[(a.keys & b.keys).map {|k| [k,a[k].merge(((b[k].to_s == b[k]) && eval(b[k])) || b[k])] }]).merge(b.reject {|k,v| (a.keys & b.keys).include? k }) }.map {|k,v| Hash[(((v.to_s == v) && eval(v)) || v).map {|a,b| [a, (((b.to_s == b) && eval(b)) || b)] }.map {|a,b| [k+"-"+a,{"type" => k, "rt_notify" => b.fetch("rt_notify",nil), "rt_requires" => b.fetch("rt_requires",nil), "rt_resources" => b.fetch("rt_resources",nil),"params" => {a=>b.reject {|x,y| ["rt_resources", "rt_requires", "rt_notify"].include? x }}}]}] }.flatten(1).inject({}) {|a,b| a.merge(b) }.to_yaml %>'))
      create_resources('resource_tree::resource', $uniq_resources, {})
  }
}
