# For a complete list of puma configuration parameters, please see
# https://github.com/puma/puma

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum.
#
threads_count = ENV.fetch("PUMA_MAX_THREADS") { 5 }.to_i
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests, default is 2020.
#
port        ENV.fetch("DASHING_PORT") { 3030 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RACK_ENV") { "production" }

# Daemonize the server into the background. Highly suggest that
# this be combined with "pidfile" and "stdout_redirect".
#
# The default is "false".
#
daemonize ENV.fetch("DAEMONIZE") { false }

# Store the pid of the server in the file at "path".
#
pidfile './tmp/pids/puma.pid'

# Use "path" as the file to store the server info state. This is
# used by "pumactl" to query and control the server.
#
state_path './tmp/pids/puma.state'

# Redirect STDOUT and STDERR to files specified. The 3rd parameter
# ("append") specifies whether the output is appended, the default is
# "false".
#
# stdout_redirect '/u/apps/lolcat/log/stdout', '/u/apps/lolcat/log/stderr'
# stdout_redirect '/u/apps/lolcat/log/stdout', '/u/apps/lolcat/log/stderr', true