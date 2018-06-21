local SCHEMA = {
  table = "consumer_routes",
  fields = {
    consumer_id = {type = "id", required = true, foreign = "consumers:id"},
    route_id = {type = "id", required = true},
  }
}

return {
	consumer_routes = SCHEMA,
}