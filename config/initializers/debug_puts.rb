# Temporarily uncomment this block when you need to locate calls to `puts` or `ap`.
# It is limited to development and stays disabled by default.
#
# if Rails.env.development?
#   module Kernel
#     alias_method :oldputs, :puts
#
#     def puts(value)
#       oldputs("PUTS #{caller_locations.first}: #{value}")
#     end
#   end
#
#   module APWithCaller
#     def ap(*args)
#       location = caller_locations(1, 1).first
#       prefix = "#{location.path}:#{location.lineno}: "
#       args.each { |arg| super("#{prefix}#{arg.inspect}") }
#     end
#   end
#
#   Kernel.prepend(APWithCaller)
# end
