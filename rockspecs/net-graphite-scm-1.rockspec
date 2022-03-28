package = 'net-graphite'
version = 'scm-1'
source  = {
    url    = 'git+https://github.com/moonlibs/net-graphite.git',
    branch = 'master',
}
description = {
    summary  = "Module for send stats to graphite/ethine",
    homepage = 'https://github.com/moonlibs/net-graphite',
    license  = 'Artistic',
}
dependencies = {
    
}
build = {
    type = 'builtin',
    modules = {
        ['net.graphite'] = 'net/graphite.lua'
    }
}

-- vim: syntax=lua
