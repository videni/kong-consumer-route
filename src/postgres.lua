return {
  {
    name = "2018-06-13-105303_create_consumer_routes_table",
    up = [[
      create table consumer_routes(
        consumer_id uuid constraint consumer_id_fk references consumers on delete cascade,
        route_id  uuid  constraint route_id_fk  references routes on delete cascade
      );
      create unique index consumer_routes_consumer_id__route_id_uindex on consumer_routes (consumer_id, route_id);
    ]],
    down = [[
      DROP TABLE consumer_routes;
    ]]
  }
}