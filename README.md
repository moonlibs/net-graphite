Connector to graphite/ethine

```lua
local g = net.graphite {
    host   = host;
    port   = 2003;          -- 2003
    proto  = "tcp";         -- default udp

    prefix = "my.metrics."; -- default ""
}

g:send("res.200.put_object", 0.123, [ ts = os.time() ])
    -> my.metrics.res.200.put_object 0.123 ts
```
