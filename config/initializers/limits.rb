# Set a hard limit of 1Gb on the virtual size of the process
if Process.const_defined?(:RLIMIT_AS)
  Process.setrlimit Process::RLIMIT_AS, 1024*1024*1024, Process::RLIM_INFINITY
end
