# Limit each rails process to a 512Mb resident set size
Process.setrlimit Process::RLIMIT_AS, 640*1024*1024, Process::RLIM_INFINITY

# Force a restart after every 10000 requests
COUNT = 0
MAX_COUNT = 10000
