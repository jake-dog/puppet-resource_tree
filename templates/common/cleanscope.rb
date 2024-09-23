# We need to create a clean scope to evaluate any strings.
# Since we're resetting scope, we also add some convenience
# methods like lookup, inline_template, inline_epp, and puppetdb_query.
# Support for puppet data types is also added via ptype().
# "scope" is passed in to preserve compatibility with other methods.
# Instance variables are also copied over from scope.
class CleanScope
  def scope_call(*params)
    if scope.respond_to?(:call_function)
      scope.call_function(__callee__.to_s, params)
    else
      # This technique is still seemingly valid in puppet7/stdlib, but
      # it almost certainly never executed.
      Puppet::Parser::Functions.function(__callee__)
      scope.method("function_#{__callee__}").call(params)
    end
  end

  define_method 'lookup', instance_method(:scope_call)
  define_method 'inline_template', instance_method(:scope_call)
  define_method 'inline_epp', instance_method(:scope_call)
  define_method 'puppetdb_query', instance_method(:scope_call)

  def ptype(type_name)
    Puppet::Pops::Types::TypeParser.singleton.parse(type_name)
  end

  def scope_eval(code)
    unless @clientcert
      scope.to_hash.each do |name, value|
        realname = name.gsub(%r{[^\w]}, '_')
        instance_variable_set("@#{realname}", value)
      end
    end

    instance_eval(code)
  end

  def initialize(scope)
    @__scope__ = scope
  end

  def scope
    @__scope__
  end
end
