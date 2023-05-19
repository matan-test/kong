package = "kong-plugin-statsd-advanced"
version = "dev-0"

source = {
  url = "https://github.com/Kong/kong-plugin-statsd-advanced",
  tag = "dev"
}

supported_platforms = {"linux", "macosx"}
description = {
  summary = "StatsD Advanced Plugin",
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.statsd-advanced.handler"] = "kong/plugins/statsd-advanced/handler.lua",
    ["kong.plugins.statsd-advanced.schema"]  = "kong/plugins/statsd-advanced/schema.lua",
  }
}