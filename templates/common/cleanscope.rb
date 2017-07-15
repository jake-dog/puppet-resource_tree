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
    if !Puppet.future_parser?(compiler.environment)
      @__scope__.method(:"function_#{__callee__}").call(params)
    else
      @__scope__.call_function(__callee__, params)
    end
  end
  
  def compat_call(*args, &block)
    if __callee__.to_s.starts_with?("function_") and Puppet.future_parser?(compiler.environment)
      @__scope__.call_function(method.to_s.gsub(/^function_/,""), args, &block)
    elsif __callee__.to_s == "call_function" and !Puppet.future_parser?(compiler.environment)
      @__scope__.method(:"function_#{method.to_s}").call(args)
    else
      @__scope__.method(__callee__).call(args, &block)
    end
  end

  define_method "hiera", instance_method(:scope_call)
  define_method "hiera_hash", instance_method(:scope_call)
  define_method "hiera_array", instance_method(:scope_call)
  define_method "inline_template", instance_method(:scope_call)

  def scope_eval(code)
    if !@clientcert
      @__scope__.to_hash.each do |name, value|
        realname = name.gsub(/[^\w]/, "_")
        instance_variable_set("@#{realname}", value)
      end
    end

    instance_eval(code)
  end
  def initialize(scope)
    @__scope__ = scope
    @__scope__.instance_methods.each{|m| 
      if m.to_s.start_with?("function_")
        define_method m, instance_method(:compat_call)
      end
    }
  end
  def scope
    self
  end
end
