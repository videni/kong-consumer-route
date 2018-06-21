local crud = require "kong.api.crud_helpers"
local fmt = string.format
local app_helpers   = require "lapis.application"
local encode_base64 = ngx.encode_base64
local decode_base64 = ngx.decode_base64
local cjson         = require "cjson"
local type          = type
local next          = next
local responses     = require "kong.tools.responses"
local encode_args   = ngx.encode_args
local ceil 		    = math.ceil
local validate      = require("lapis.validate").validate
local singletons = require "kong.singletons"

local function select_query(select_clause, consumer_id)
	local query =fmt([[
		 SELECT %s FROM routes AS a
	 	  INNER JOIN consumer_routes AS b
	 	  ON a.id= b.route_id
	 	  WHERE b.consumer_id='%s'
	]], select_clause, consumer_id)

	return query;
end

local function count(db_connector, consumer_id)
	local query = select_query('count(*)', consumer_id)

	local res, err = db_connector:query(query)

	if not res then  return nil, err
	elseif #res <= 1 then return res[1].count
	else return nil, "bad rows result" end
end

local function get_route_ids()
	ngx.req.read_body()
    local args, err = ngx.req.get_post_args()
	if not args then  return nil  end
    local route_ids
    for key, val in pairs(args) do
        if key == 'routes[]' then
        	if type(val) == 'boolean' then return  {} end
         	if type(val) ~= 'table'   then route_ids = {tostring(val)}
         	else route_ids = val end

            break
        end
 	end

 	return route_ids
end

local function validate_cache(consumer_id)
	local cache = singletons.cache
	cache:invalidate("consumer_route."..consumer_id)
end
return {
  ["/consumers/:username_or_id/routes"] = {
    before = function(self, dao_factory, helpers)
	    crud.find_consumer_by_username_or_id(self, dao_factory, helpers)
	    self.params.consumer_id = self.consumer.id
    end,

    GET = function(self, dao_factory, helpers)
    	local size   = self.params.size   and tonumber(self.params.size) or 100
  		local page = self.params.page and tonumber(self.params.page) or 1

  		self.params.size   = nil
		self.params.page = nil

  		local db_connector = dao_factory.apis.db.new_db.connector;

		local total_count, err = count(db_connector, self.params.consumer_id)
		if err then
			return app_helpers.yield_error(err)
		end
		local total_pages = ceil(total_count/size)

		local query = select_query('*', self.params.consumer_id);
		if size then
			query = query .. " LIMIT " .. size
		end

  		local offset = size * (page - 1)
		if offset and offset > 0 then
			query = query .. " OFFSET " .. offset
		end
		local rows, err, partial, num_queries = db_connector:query(query)
		if not rows then
		    return app_helpers.yield_error(err)
		end

		next_page = page + 1;
		nex_page = (next_page <= total_pages and next_page or nil)

		local next_url
		if nex_page then
			next_url = self:build_url(self.req.parsed_url.path, {
			  port     = self.req.parsed_url.port,
			  query    = encode_args {
			    page = nex_page,
			    size   = size
			  }
			})
		end

		local data = setmetatable(rows, cjson.empty_array_mt)

		return responses.send_HTTP_OK {
			data     = data,
			total    = total_count,
			page     = page,
			["next"] = next_url
		}
    end,

    POST = function(self, dao_factory)
		local errors = validate(self.params, {
    		{'routes', exists = true}
    	})

    	if errors ~= nil then
    		return responses.send_HTTP_BAD_REQUEST {
    			message =  errors
    		}
    	end

		local consumer_routes_dao = dao_factory.consumer_routes

		local route_ids = get_route_ids()

		local accepted = {}
    	for i, route_id in ipairs(route_ids) do
			local row = {
    			consumer_id = self.params.consumer_id,
    			route_id = route_id
    		}
    		local consumer_route, err = consumer_routes_dao:insert(row)

    		if not err then
    			table.insert(accepted, route_id)
    		end
    	end

		local data = setmetatable(accepted, cjson.empty_array_mt)

    	validate_cache(self.params.consumer_id)

    	return responses.send_HTTP_CREATED  {
    		data = data
    	}
	end,

	DELETE = function(self, dao_factory)
  		local errors = validate(self.params, {
    		{'routes', exists = true}
    	})

    	if errors ~= nil then
    		return app_helpers.yield_error(errors)
    	end
		local db_connector = dao_factory.consumer_routes.db.new_db.connector;

		local route_ids = get_route_ids()
		local next = next

		if  next(route_ids) == nil then
			return responses.send_HTTP_BAD_REQUEST {
    			message =  'routes parameters should\'t be empty'
			}
		end

		local routes= ''
    	for i, route_id in ipairs(route_ids) do
    		routes = routes.."'"..route_id.."'"
		end

		local query =fmt([[
		DELETE FROM consumer_routes
		WHERE  consumer_id = '%s' AND route_id IN (%s)
		]], self.params.consumer_id, routes)

		local rows, err, partial, num_queries = db_connector:query(query)

		if not rows then
		    return app_helpers.yield_error(err)
		end

    	validate_cache(self.params.consumer_id)

    	return responses.send_HTTP_NO_CONTENT()
   end
  }
}