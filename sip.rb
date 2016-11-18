require 'socket'

$userInfoTable = Hash.new

class SipServer
	attr_reader :header, :body, :type, :version

	def initialize
		@header = Hash.new
	end

	def parse data
		(header, body) = data.split /\r\n\r\n/
		 puts "\033[36m#{header}\033[m"
		 puts "\033[36m#{body}\033[m"
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
				when /^ACK.+/ then
					@type = 'ACK'
					@version = line.split(' ')[2]
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

				$userInfoTable[ @header['Contact']] = @header['Contact']

				response = "#{@version} 200 OK\r\n"
				@header.each {|map|
					print(map[0]+"\n")
					next if map[0]=='Max-Forwards'
					response += "#{map[0]}:#{map[1]}\r\n"
				}
				response += "\r\n"
				return response

			when 'INVITE' then
				puts "dialing"
				response = "#{@version} 302 Moved Temporarily\r\n"
				@header.each {|map|
					print map[0]+"\n"
					#next if map[0]=~/Content-.+/ || map[0]=='Contact' || map[0]=='Max-Forwards'
					response += "#{map[0]}:#{map[1]}\r\n"
				}
				response += "Contact: #{$userInfoTable[@header['To']]}\r\n"
				response += "\r\n"
				return response
			when 'ACK' then

				return nil
			end

	end
end
class Server
	def initialize port

		socket = UDPSocket.new

		socket.bind('', port)

		while true
			(data, addr) = socket.recvfrom 1024
			response = SipServer.new.parse(data).action
			puts ("\033[31m#{response}\033[m")
			socket.send(response, 0, addr[3], addr[1]) if response != nil
			# $userInfoTable.each {|user| puts "\033[31m#{user.inspect}\033[m" }
			# puts ''
		end
	end
end

if ARGV.size != 1 then
	puts '請輸入 : ruby ' + __FILE__ + ' <port>'
	exit 1
end

Server.new ARGV[0].to_i
