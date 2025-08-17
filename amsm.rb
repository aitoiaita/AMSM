#    _   __  __ ___ __  __ 
#   /_\ |  \/  / __|  \/  |
#  / _ \| |\/| \__ \ |\/| |
# /_/ \_\_|  |_|___/_|  |_|
#     AM Session Manager

INDENT = 2
PROMPT = 'amsm> '
XSESS_DIR = '/usr/share/xsessions/'

commands = {
	/exit|quit/ => lambda { |argv, sessions|
		exit
	},
	/run|[0-9]+/ => lambda { |argv, sessions|
		argv = argv[1..-1] if argv[0] == 'run'
		session_index = argv[0].to_i
		system "startx #{sessions[session_index]['Exec']}"
	}
}
commands.default = lambda { |argv, sessions| puts "Invalid command" }

def parse_session(data)
	lines = data.split("\n")
	return nil if not lines[0] == '[Desktop Entry]' # session files need to start with this line

	options = lines[1..] # remove the first element ("[Desktop Entry]") from the lines
		.select{|l| l.include?('=') }      # only keep lines that have '='
		.map{|l| l.split('=') }             # split ["key=value"] into [["key", "value"]]
		.map{|la| la.fill('', la.size..1) } # handle empty "value"s
		.to_h                               # convert [["key", "value"]] into {"key" => "value"}
	return nil if options['Name'].nil? or options['Exec'].nil? # the session needs to contain a name and command
	return options
end

def read_sessions
	sessions = Dir.glob("#{XSESS_DIR}/*.desktop")
		.map{|p| parse_session(File.read(p))} # parse the session file at each path
		.reject(&:nil?)     # remove invalid sessions
		.each.with_index(1) # iterate through each object with its index starting at 1 instead of 0
		.to_a               # convert to an array like [[session1, 1], [session2, 2]]
		.map(&:reverse)     # reverse each element of the array into [[1, session1], [2, session2]]
		.to_h               # convert into a hash like {1 => session1, 2 => session2}
	sessions.default = lambda { puts 'Invalid index' }
	sessions
end

def print_sessions(session_array)
	puts session_array
		.map{|index, session| (' ' * INDENT) + "#{index} #{session['Name']}"}
		.join("\n")
end

def prompt(sessions, commands)
	loop do
		print PROMPT
		(argv = $stdin.gets.chomp.split(' ')).empty? and next
		r = commands.find(->{0}) {|regex, func| argv[0].match(regex)}[0]
		commands[r][argv, sessions]
	end
end

sessions = read_sessions
print_sessions(sessions)
prompt(sessions, commands)
