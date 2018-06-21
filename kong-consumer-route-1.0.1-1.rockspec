package = "kong-consumer-route"
version = "1.0.1-1"
source = {
  url = "none",
  tag = "1.0.1"
}
description = {
  summary = "A plugin for Kong to associat consumer and route",
  homepage = "none",
  license = "Apache 2.0"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.apistats.handler"] = "src/handler.lua",
    ["kong.plugins.apistats.daos"] = "src/daos.lua",
    ["kong.plugins.apistats.api"] = "src/api.lua",
    ["kong.plugins.apistats.migrations.postgres"] = "src/postgres.lua"
  }
}