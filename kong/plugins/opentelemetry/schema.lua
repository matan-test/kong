-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local typedefs = require "kong.db.schema.typedefs"
local Schema = require "kong.db.schema"
local deprecation = require("kong.deprecation")

local function custom_validator(attributes)
  for _, v in pairs(attributes) do
    local vtype = type(v)
    if vtype ~= "string" and
       vtype ~= "number" and
       vtype ~= "boolean"
    then
      return nil, "invalid type of value: " .. vtype
    end

    if vtype == "string" and #v == 0 then
      return nil, "required field missing"
    end
  end

  return true
end

local resource_attributes = Schema.define {
  type = "map",
  keys = { type = "string", required = true },
  -- TODO: support [string, number, boolean]
  values = { type = "string", required = true },
  custom_validator = custom_validator,
}

return {
  name = "opentelemetry",
  fields = {
    { protocols = typedefs.protocols_http }, -- TODO: support stream mode
    { config = {
      type = "record",
      fields = {
        { endpoint = typedefs.url { required = true } }, -- OTLP/HTTP
        { headers = {
          type = "map",
          keys = typedefs.header_name,
          values = {
            type = "string",
            referenceable = true,
          },
        } },
        { resource_attributes = resource_attributes },
        { batch_span_count = { type = "integer" } },
        { batch_flush_delay = { type = "integer" } },
        { queue = typedefs.queue },
        { connect_timeout = typedefs.timeout { default = 1000 } },
        { send_timeout = typedefs.timeout { default = 5000 } },
        { read_timeout = typedefs.timeout { default = 5000 } },
        { http_response_header_for_traceid = { type = "string", default = nil }},
        { header_type = { type = "string", required = false, default = "preserve",
                          one_of = { "preserve", "ignore", "b3", "b3-single", "w3c", "jaeger", "ot" } } },
      },
      entity_checks = {
        { custom_entity_check = {
          field_sources = { "batch_span_count", "batch_flush_delay" },
          fn = function(entity)
            if (entity.batch_span_count or ngx.null) ~= ngx.null and entity.batch_span_count ~= 200 then
              deprecation("opentelemetry: batch_span_count no longer works, please use config.queue.max_batch_size instead",
                          { after = "4.0", })
            end
            if (entity.batch_flush_delay or ngx.null) ~= ngx.null and entity.batch_flush_delay ~= 3 then
              deprecation("opentelemetry: batch_flush_delay no longer works, please use config.queue.max_coalescing_delay instead",
                          { after = "4.0", })
            end
            return true
          end
        } },
      },
    }, },
  },
}
