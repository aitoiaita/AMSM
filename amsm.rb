#    _   __  __ ___ __  __ 
#   /_\ |  \/  / __|  \/  |
#  / _ \| |\/| \__ \ |\/| |
# /_/ \_\_|  |_|___/_|  |_|
#     AM Session Manager

class Session
	def initialize(name, exec)
			@name = name
			@exec = exec
	end

	def call
			system "startx #{@exec}"
	end

	attr_reader :name
end

commands = {
	/exit|quit/ => lambda { |argv, sessions|
		exit
	},
	/run|[0-9]+/ => lambda { |argv, sessions|
		argv = argv[1..-1] if argv[0] == 'run'
		session_index = argv[0].to_i
		sessions[session_index].call
	}
}
commands.default = lambda { |argv, sessions| puts "Invalid command" }

def parse_session(data)
	lines = data.split("\n")
	return nil if not lines[0] == '[Desktop Entry]'
	lines.shift

	options = lines.map{|l| (l=l.split '=').length == 2 ? l : (return nil)}.to_h
	return Session.new((options['Name'] or return nil), (options['Exec'] or return nil))
end

def read_sessions
	invalid_lambda = lambda { puts 'Invalid index'}	
	sessions = Dir.glob('/usr/share/xsessions/*.desktop').map.with_index(1) do |path, index|
		[index, parse_session(File.read(path))]
	end.reject{|session| session[1].nil?}.to_h
	sessions.default = invalid_lambda
	sessions
end

def print_sessions(session_array)
	session_array.each_pair do |index, session|
		puts "  #{index} #{session.name}"
	end
end

def prompt(sessions, commands)
	loop do
		print 'amsm> '
		argv = $stdin.gets.chomp.split ' '
		commands[commands.keys.select { |regex| argv[0].match regex }[0]][argv, sessions]
	end
end

sessions = read_sessions
print_sessions(sessions)
prompt(sessions, commands)
