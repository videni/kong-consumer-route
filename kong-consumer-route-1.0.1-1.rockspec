package = "kong-consumer-route"
version = "1.0.1-1"
source = {
  url = "https://github.com/videni/kong-consumer-route.git",
  tag = "1.0.1"
}
description = {
  summary = "A plugin for Kong to associate consumer and route",
  homepage = "none",
  license = "Apache 2.0"
}
dependencies = {
  "lua >= 5.1"
}
build = {
  type = "builtin",
  modules = {
    ["kong.plugins.consumer-route.handler"] = "src/handler.lua",
    ["kong.plugins.consumer-route.daos"] = "src/daos.lua",
    ["kong.plugins.consumer-route.api"] = "src/api.lua",
    ["kong.plugins.consumer-route.schema"] = "src/schema.lua",
    ["kong.plugins.consumer-route.migrations.postgres"] = "src/postgres.lua"
  }
}