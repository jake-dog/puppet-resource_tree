# @summary
#  Define puppet resource collections using hiera and ruby.
#
# @param collections
#   Define a named collection of puppet resources which can be applied.
#   ``` puppet
#   $collections = {
#      "example_resources" => {
#        "file" => {
#          "/tmp/mydir" => {
#            "ensure" => "directory",
#          },
#        },
#      },
#   }
#   ```
#   Typically resource collections are defined in hieradata.
#
# @param apply
#   A list of collection names to be applied.
#
# @param default_params
#   Default parameters by resource type.
#
class resource_tree (
  Hash $collections       = {},
  Array[String[1]] $apply = [],
  Hash $default_params    = {},
) {
  $allcollections = lookup('resource_tree::collections', undef, 'hash', $collections)
  $allapply = lookup('resource_tree::apply', Array[String], 'deep', $apply)
  $defaults = lookup('resource_tree::default_params', Hash, 'hash', $default_params)

  if $allcollections.is_a(Hash) and $allapply.is_a(Array) and (size(intersection($allapply, keys($allcollections))) > 0) {
      $uniq_resources = parseyaml(template('resource_tree/main.erb'))
      create_resources('resource_tree::resource', $uniq_resources, {})
  }
}
