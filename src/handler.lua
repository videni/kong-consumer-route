local BasePlugin = require "kong.plugins.base_plugin"
local singletons = require "kong.singletons"
local fmt        = string.format
local responses     = require "kong.tools.responses"

local function get_consumer_id()
   if ngx.ctx['authenticated_credential'] ~= nil then return  ngx.ctx.authenticated_credential.consumer_id  end

   ngx.log(ngx.ERR, "no consumer found: ");

   return nil
end

local function load_consumer_routes(consumer_id)
  local query =fmt([[
    SELECT route_id FROM consumer_routes
    WHERE consumer_id='%s'
  ]], consumer_id)

  local db = singletons.db

  local rows, err, partial, num_queries = db.connector:query(query)

  return rows
end

local ConsumerRoute = BasePlugin:extend()

ConsumerRoute.PRIORITY = 992

function ConsumerRoute:new()
    ConsumerRoute.super.new(self, "ConsumerRoute")
end

function ConsumerRoute:access(conf)
    ConsumerRoute.super.access(self)

    consumer_id = get_consumer_id();
    if consumer_id == nil then return false end

    local cache = singletons.cache

    local routes, err = cache:get("consumer_route." .. consumer_id, nil,
                                  load_consumer_routes, consumer_id)
    if err then
      return response.HTTP_INTERNAL_SERVER_ERROR(err)
    end

    local ctx = ngx.ctx
    local current_route_id = ctx.route.id
    if current_route_id == nil then return false end

    local deny = true

    for key, val in pairs(routes) do
      if val.route_id == current_route_id then
        deny = false
        break
      end
    end

    if deny then
      return responses.send_HTTP_FORBIDDEN("You are not allowed to call this route")
    end
end

function ConsumerRoute:init_worker()
  local worker_events = singletons.worker_events

  worker_events.register(function(data)
    -- currently , Kong doen't have api to invalidate cache like this consumer-route.*,
    -- so we have to invalidate all cache, since route deleletion seldom happen， this is not big deal
    local cache = singletons.cache
    cache:purge()
  end, "crud", "routes:delete")
end

return ConsumerRoute
