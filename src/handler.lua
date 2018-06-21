local BasePlugin = require "kong.plugins.base_plugin"

local function get_consumer_id()
   if ngx.ctx['authenticated_credential'] ~= nil then return  ngx.ctx.authenticated_credential.consumer_id  end

   ngx.log(ngx.ERR, "no consumer found: ");

   return nil
end

local ConsumerRoute = BasePlugin:extend()

ConsumerRoute.PRIORITY = 992

function ConsumerRoute:new()
    ConsumerRoute.super.new(self, "ConsumerRoute")
end

function ConsumerRoute:::access(conf)
    ConsumerRoute.super.access(self)

    
end

return ConsumerRoute
