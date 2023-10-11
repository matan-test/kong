-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local pl_file = require "pl.file"
local helpers = require "spec.helpers"

for _, strategy in helpers.each_strategy() do
  describe("vitals tsdb strategy with #" .. strategy , function()
    local license_env

    setup(function()
      license_env = os.getenv("KONG_LICENSE_DATA")
      helpers.setenv("KONG_LICENSE_DATA", pl_file.read("spec-ee/fixtures/mock_license.json"))
    end)

    teardown(function()
      -- in case anything failed, stop kong here
      helpers.stop_kong()

      if type(license_env) == "string" then
        helpers.setenv("KONG_LICENSE_DATA", license_env)
      end
    end)

    it("loads TSDB strategy with feature flags properly", function()
     assert(helpers.start_kong({
        portal = true,
        portal_and_vitals_key = "753252c37f163b4bb601f84f25f0ab7609878673019082d50776196b97536880",
        vitals = "on",
        feature_conf_path = "spec-ee/fixtures/feature_vitals_tsdb.conf"
      }))

      local client = helpers.admin_client()

      local res = assert(client:send {
        method = "GET",
        path = "/vitals"
      })
      assert.res_status(200, res)

      helpers.stop_kong()
    end)
  end)

  describe("vitals tsdb strategy with " .. strategy , function()
    -- in case anything failed, stop kong here
    teardown(helpers.stop_kong)

    it("loads stock vitals properly", function()
      assert(helpers.start_kong({
        portal = true,
        portal_and_vitals_key = "753252c37f163b4bb601f84f25f0ab7609878673019082d50776196b97536880",
        vitals = "on",
        vitals_strategy = "database"
      }))

      local client = helpers.admin_client()

      local res = assert(client:send {
        method = "GET",
        path = "/vitals"
      })
      assert.res_status(200, res)

      helpers.stop_kong()
    end)
  end)

  pending("vitals tsdb strategy with " .. strategy , function()
    -- mark as pending because we don't have statsd-advanced plugin bundled
    -- in case anything failed, stop kong here
    teardown(helpers.stop_kong)

    it("loads prometheus strategy properly", function()
      assert(helpers.start_kong({
        portal = true,
        portal_and_vitals_key = "753252c37f163b4bb601f84f25f0ab7609878673019082d50776196b97536880",
        vitals = "on",
        vitals_strategy = "prometheus",
        vitals_tsdb_address = "127.0.0.1:9090",
        vitals_statsd_address = "127.0.0.1:8125",
      }))

      local client = helpers.admin_client()

      local res = assert(client:send {
        method = "GET",
        path = "/vitals"
      })
      assert.res_status(200, res)

      helpers.stop_kong()
    end)
  end)

  describe("vitals tsdb strategy with " .. strategy , function()
    -- in case anything failed, stop kong here
    teardown(helpers.stop_kong)

    it("errors if strategy is unexpected", function()
      local ok, err = helpers.start_kong({
        portal = true,
        portal_and_vitals_key = "753252c37f163b4bb601f84f25f0ab7609878673019082d50776196b97536880",
        vitals = "on",
        vitals_strategy = "sometsdb",
        vitals_tsdb_address = "127.0.0.1:9090",
        vitals_statsd_address = "127.0.0.1:8125",
      })
      assert.is.falsy(ok)
      assert.matches("Error: vitals_strategy must be one of \"database\", \"prometheus\", or \"influxdb\"", err)

      helpers.stop_kong()
    end)
  end)
end
