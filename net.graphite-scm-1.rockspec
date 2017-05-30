package = 'net.graphite'
version = 'scm-1'
source  = {
    url    = 'git@github.com:moonlibs/tnt-net-graphite.git',
    branch = 'master',
}
description = {
    summary  = "Module for send stats to graphite/ethine",
    homepage = 'https://github.com/moonlibs/tnt-net-graphite',
    license  = 'BSD',
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
