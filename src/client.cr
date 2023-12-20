# Copyright 2023 Jason C. Nucciarone
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 3 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "http/client"
require "socket"
require "uri"


class Arbitrator
  def initialize(url : URI)
    # http+unix scheme means that we are using HTTP over a Unix socket.
    if url.scheme == "http+unix"
      socket = UNIXSocket.new(url.path)
      @client = HTTP::Client.new(socket)
    elsif url.scheme == "http" || url.scheme == "https"
      raise "Remote LXD servers are currently unsupported; use local Unix socket instead."
    else
      raise "Unsupported scheme #{url.scheme}. Ensure that LXD API URL #{url.to_s} is correct."
    end
  end

  def get
    response = @client.get "/"
    puts response.status_code
  end

  def post
  end
end


class Client
  def initialize(
    endpoint : String | Nil = nil,
    version : String = "1.0",
    cert : Tuple(String, String) | Nil = nil,
    verify : Bool | String = true,
    timeout : Int32 | Tuple(Int32, Int32) | Nil = nil,
    project : String | Nil = nil,
  )
    if !endpoint.nil?
      if endpoint.starts_with?("/") && File.exists?(endpoint)
        path = URI.encode_path(endpoint)
        url = URI.parse("http+unix://#{path}")
      else
        raise "Remote LXD servers are currently unsupported; use local Unix socket instead."
      end
    else
      if ENV.has_key?("LXD_DIR")
        path = Path[ENV["LXD_DIR"]].join("unix.socket").to_s
      elsif File.exists?("/var/snap/lxd/common/lxd/unix.socket")
        path = URI.encode_path("/var/snap/lxd/common/lxd/unix.socket")
      else
        path = URI.encode_path("/var/lib/lxd/unix.socket")
      end
      url = URI.parse("http+unix://#{path}")
    end

    @api = Arbitrator.new(url)
    @api.get
  end
end

test = Client.new timeout: {45, 60}

