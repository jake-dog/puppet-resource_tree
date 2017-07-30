# We need to create a clean scope to evaluate any strings
# Variable collisions only seem to effect jruby.
# Since we're resetting scope, we also add some convenience
# methods, like hiera, hiera_hash, without the function_*
# aliases.  We cannot use alias_method, nor do we support
# ruby 1.8.7, so "scope" is passed in to preserve compatibility
# with unaliased methods. Instance variables are also copied
# over from scope, much like Puppet::Parser::TemplateWrapper.
class CleanScope
  def scope_call(*params)
    # Detecting future parser is how call_function() does it,
    # but is that strategy robust enough or do we need to use
    # Puppet.version?
    if scope.respond_to?(:call_function)
      scope.call_function(__callee__, params)
    else
      Puppet::Parser::Functions.function(__callee__)
      scope.method(:"function_#{__callee__}").call(params)
    end
  end

  define_method "hiera", instance_method(:scope_call)
  define_method "hiera_hash", instance_method(:scope_call)
  define_method "hiera_array", instance_method(:scope_call)
  define_method "inline_template", instance_method(:scope_call)

  def scope_eval(code)
    if !@clientcert
      scope.to_hash.each do |name, value|
        realname = name.gsub(/[^\w]/, "_")
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
