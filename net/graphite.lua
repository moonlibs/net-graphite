--[[

local g = net.graphite {
    host   = host;
    port   = 2003;          -- 2003
    proto  = "tcp";         -- default udp

    prefix = "my.metrics."; -- default ""
}

g:send("res.200.put_object", 0.123, [ ts = os.time() ])
	-> my.metrics.res.200.put_object 0.123 ts

]]

local socket = require 'socket'
local errno  = require 'errno'
local log    = require 'log'
local ffi    = require 'ffi'

local function redef(t,def)
	if not pcall(ffi.typeof, t) then
		ffi.cdef(def)
	end
end
local function fdef(fn,def)
	if not pcall(function(fn) local t = ffi.C[fn] end, fn) then
		ffi.cdef(def)
	end
end

redef('size_t',    'typedef unsigned int    size_t;')
redef('ssize_t',   'typedef int             ssize_t;')
redef('in_addr_t', 'typedef uint32_t        in_addr_t;')
redef('socklen_t', 'typedef int             socklen_t;')
redef('struct sockaddr', [[
	struct sockaddr {
		unsigned short    sa_family;    // address family, AF_xxx
		char              sa_data[14];  // 14 bytes of protocol address
	};
]])
redef('struct in_addr', [[
	struct in_addr {
		in_addr_t s_addr;               // load with inet_pton()
	};
]])
redef('struct sockaddr_in', [[
	struct sockaddr_in {
		short            sin_family;   // e.g. AF_INET, AF_INET6    (2)
		unsigned short   sin_port;     // e.g. htons(3490)          (2)
		struct in_addr   sin_addr;     // see struct in_addr, below (4)
		char             sin_zero[8];  // zero this if you want to  (8)
	};
]])

fdef('socket',   [[ int socket(int domain, int type, int protocol); ]])
fdef('connect',  [[ int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen); ]])
fdef('memset',   [[ void *memset(void *s, int c, size_t n); ]])
fdef('htons',    [[ uint16_t htons(uint16_t hostshort); ]])
fdef('inet_addr',[[ in_addr_t inet_addr(const char *cp); ]])
fdef('sendto',   [[ ssize_t sendto(int sockfd, const void *buf, size_t len, int flags, const struct sockaddr *dest_addr, socklen_t addrlen); ]])
fdef('strlen',   [[ size_t strlen(const char *s); ]])
fdef('close',    [[ int close(int fd); ]])
fdef('strerror', [[ char *strerror(int errnum); ]])

local sockaddr_in = ffi.typeof("struct sockaddr_in")
local in_addr     = ffi.typeof("struct in_addr")


local M = {}
M.__index = M

setmetatable(M,{
	__call = function(t,...) return t:new(...) end,
})

function M.new( class, args )
	if not args then
		print("Creating dummy graphite with no args")
		return { send = function() end }
	end
	assert(args.host, "host required");
	if args.proto and args.proto ~= "udp" then
		error("protos other than udp not supported")
	end
	local self = setmetatable({
		host    = tostring(args.host);
		port    = tostring(args.port or 2003);
		prefix  = tostring(args.prefix or "");
		timeout = tonumber(args.timeout or 1);
	}, class)

	-- print(self.host,self.port, self.timeout)
	local ais = socket.getaddrinfo(self.host, self.port, self.timeout, { type = 'SOCK_DGRAM', protocol = 'udp', family = 'AF_INET' })
	if not ais then error("Failed to resolve "..self.host..':'..self.port) end

	local sock = socket('AF_INET', 'SOCK_DGRAM', 'udp')
	if not sock then error("Failed to create socket: "..errno.strerror()) end
	-- print(sock)
	-- print(sock:fd())
	self.sock = sock;
	self.sockfd = sock:fd();

	for _,ai in pairs(ais) do 
		-- print(ai.host, ai.port)
		-- print(ffi.C.inet_addr ( ffi.cast("const char *", ad.host ) ))
		local chost = in_addr( ffi.C.inet_addr ( ffi.cast("const char *", ai.host ) ) )
		-- print("chost ok: ", chost)
		local cport = ffi.C.htons(ffi.cast("unsigned short", tonumber(ai.port)))
		-- print("cport ok")
		local cinzero  = ffi.new("char[8]", {})

		self.sa = sockaddr_in(2, cport, chost, cinzero)
		self.dest_addr    = ffi.cast("struct sockaddr *", self.sa)
		self.addr_len     = ffi.cast("socklen_t", ffi.sizeof(self.sa))
		-- print(self.dest_addr,tonumber(self.addr_len))
		-- local r = ffi.C.connect(sock:fd(), self.dest_addr,self.addr_len)
		-- print(r, errno.strerror())
		log.info("Using %s:%s for graphite %s", ai.host, ai.port, self.host)
		return self
	end
	error("XXX");
	-- if true then return self end
end

function M:send(key, value, ts)
	if not ts then ts = os.time() end
	local m = self.prefix .. key .. ' ' .. tostring(value)..' '..ts.. "\n"
	local r = ffi.C.sendto(self.sockfd, m, #m, 0, self.dest_addr, self.addr_len)
	if r == -1 then
		log.error("failed to send: %s",errno.strerror())
	end
end

-- rawset (_G, "udptest", function ()
-- 	local u = M:new {
-- 		host = "localhost";
-- 	}
-- 	u:send("test",123)
-- 	return u
-- end)

return M
