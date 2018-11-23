#!/usr/bin/env ruby
# # Collector

# **collector.rb** is a simple disk statistics collector.  It has very few
# knobs.  It just runs "df -k" on localhost and, possibly, some remote
# hosts.  It stores disk usage, total, and filesystem in a simple space
# delimited file in ~/Data or a specified target directory.

# To start capturing data, you can merely run it:

#     collector.rb

# After running it, you will have have a file in ~/Data/<host>.df that looks like this:

#     2013-03-13T03:48Z 415279412 449218752 / 

# The fields:

#      <Date> <UsedKB> <TotalKB> <Mount>

# You will probably want to run it periodically.  The following cron entry will run
# it every 4 hours (good for capturing intraday growth):

#     0 */4 * * * collector.rb

# To collect stats from localhost and 2 remote hosts:

#     0 */4 * * * collector.rb remote1 remote2

# # Options parsing

require 'optparse'
options = {}
options[:dir] = "#{ ENV['HOME'] }/Data"

OptionParser.new do |opts|
  opts.banner = "Usage: collector.rb [options] [host1] ... [hostN]"

  opts.on("-d", "--data-dir DIRECTORY", "Save data files in DIRECTORY") do |dir|
    options[:dir] = dir
  end
end.parse!

# # Initialization

# We always log localhost's disk usage, but we want to capture the local hostname
# so we can move data files between servers with less chance of collission.  We also
# make note of the data directory, ~/Data

localhost = (`hostname`.chomp.split ".")[0]
dir       = options[:dir]

# Next, we generate the date in [ISO 8601](http://en.wikipedia.org/wiki/ISO_8601)
# format using an external date command.  (This is definitely far from ideal,
# and should be reimplemented using native methods.)

date = `date -u '+%Y-%m-%dT%H:%MZ'`.chomp

# Finally, if the data directory doesn't exist, create it!

Dir.mkdir( dir ) unless Dir.exists?( dir )

# # The Main Loop

# The main flow of the code is over each host.  For each host, we open an
# appendable data file.  

[ localhost, *ARGV ].each do |host|
	open("#{ dir }/#{ host }.df", 'a') {  |f|

		# We run a slightly different set of arguements for localhost vs
		# remote hosts.  (Besides the "ssh" of course.)

		# For OSX, we only look at NFS and HFS volumes, and we exclude inode
		# statistics (-P), as that skews our column counts vs most Linux
		# "df"s.

                # todo : df parameters
    
		cmd = 
			if host == localhost
				"df -k -P -t nfs,hfs"
			else
				"ssh #{host} df -k -P -t ext3 -t ext4 -t ext2 -t xfs"
			end

		# For each host, run "df", split each line, and write a subset of the
		# fields to the data file.

		IO.popen(cmd) do |df| 
			df.drop(1).each do |line|
				tokens = line.split

				f.puts "#{ date } #{ tokens[2] } #{ tokens[1] } #{ tokens[5] } "
			end
		end
	}
end

# # Wishlist

# * by default, collects statistics for local machine.  uses "hostname" to determine name of host. 
