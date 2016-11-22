require 'socket'

$userInfoTable = Hash.new

class SipServer
	attr_reader :header, :body, :type, :version

	def initialize
		@header = Hash.new
	end

	def parse data
		(header, body) = data.split /\r\n\r\n/
		 print header
		 print body
    header.split("\n").each {|line|
			case line.chomp!
				when /^REGISTER.+/ then
					@type = 'REGISTER'
					@version = line.split(' ')[2]
					@body = body
				when /^INVITE.+/ then
					@type= 'INVITE'
					@version =line.split(' ')[2]
					@body = body
				else
					map = line.split(':', 2)
					@header[map[0]] = map[1]
					@body = body
				end
		} unless header.nil?

		return self
	end

	def action
		case @type
			when 'REGISTER' then
				puts "registering"

				$userInfoTable[ @header['To']] = @header['Contact']

				response = "#{@version} 200 OK\r\n"
				@header.each {|map|
					next if map[0]=='Max-Forwards'
					response += "#{map[0]}:#{map[1]}\r\n"
				}
				response += "\r\n"
				return response

			when 'INVITE' then
				puts "dialing"
				response = "#{@version} 302 Moved Temporarily\r\n"
				@header.each {|map|
					next if map[0]=~/Content-.+/ || map[0]=='Contact' || map[0]=='Max-Forwards'
					response += "#{map[0]}:#{map[1]}\r\n"
				}
				response += "Contact: #{$userInfoTable[@header['To']]}\r\n"
				response += "\r\n"
				return response
			end

	end
end
class Server
	def initialize port
		ip = UDPSocket.open {|s| s.connect("64.233.187.99", 1); s.addr.last}
		print("Server running on #{ip}:#{ARGV[0]}\n")

		socket = UDPSocket.new

		socket.bind('', port)

		while true
			(data, addr) = socket.recvfrom 1024
			response = SipServer.new.parse(data).action
			socket.send(response, 0, addr[3], addr[1]) if response != nil
		end
	end
end

if ARGV.size != 1 then
	puts '請輸入 : ruby ' + __FILE__ + ' <port>'
	exit 1
end

Server.new ARGV[0].to_i
