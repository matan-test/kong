local crud      = require "kong.api.crud_helpers"
local utils     = require "kong.tools.utils"
local rbac      = require "kong.rbac"
local bit       = require "bit"
local cjson     = require "cjson"
local responses = require "kong.tools.responses"
local new_tab   = require "table.new"
local singletons = require "kong.singletons"
local tablex     = require "pl.tablex"
local api_helpers = require "kong.enterprise_edition.api_helpers"
local workspaces = require "kong.workspaces"


local band  = bit.band
local bxor  = bit.bxor
local fmt   = string.format


local entity_relationships = rbac.entity_relationships

local rbac_users = kong.db.rbac_users
local consumers = kong.db.consumers
local rbac_roles = kong.db.rbac_roles
local endpoints   = require "kong.api.endpoints"

local function rbac_operation_allowed(kong_conf, rbac_ctx, current_ws, dest_ws)
  if kong_conf.rbac == "off" then
    return true
  end

  if current_ws == dest_ws then
    return true
  end

  -- dest is different from current
  if rbac.user_can_manage_endpoints_from(rbac_ctx, dest_ws) then
    return true
  end

  return false
end


local function objects_from_names(db, given_names, object_name)
  local names      = utils.split(given_names, ",")
  local objs       = new_tab(#names, 0)
  local object_dao = fmt("rbac_%ss", object_name)

  for i = 1, #names do
    local object, err = db[object_dao]:select_by_name(names[i])
    if err then
      return nil, err
    end

    if not object then
      return nil, fmt("%s not found with name '%s'", object_name, names[i])
    end

    -- track the whole object so we have the id for the mapping later
    objs[i] = object
  end

  return objs
end


local function action_bitfield(self)
  local action_bitfield = 0x0

  if type(self.params.actions) == "string" then
    local action_names = utils.split(self.params.actions, ",")

    for i = 1, #action_names do
      local action = action_names[i]

      -- keyword all sets everything
      if action == "*" then
        for k in pairs(rbac.actions_bitfields) do
          action_bitfield = bxor(action_bitfield, rbac.actions_bitfields[k])
        end

        break
      end

      if not rbac.actions_bitfields[action] then
        return responses.send_HTTP_BAD_REQUEST("Undefined RBAC action " ..
                                               action_names[i])
      end

      action_bitfield = bxor(action_bitfield, rbac.actions_bitfields[action])
    end
  end

  self.params.actions = action_bitfield
end


local function post_process_actions(row)
  local actions_t = setmetatable({}, cjson.empty_array_mt)
  local actions_t_idx = 0


  for k, n in pairs(rbac.actions_bitfields) do
    if band(n, row.actions) == n then
      actions_t_idx = actions_t_idx + 1
      actions_t[actions_t_idx] = k
    end
  end


  row.actions = actions_t
  return row
end


local function post_process_role(role)
  -- don't expose column that is for internal use only
  role.is_default = nil
  return role
end


local function post_process_user(user)
  local map, err = rbac.get_consumer_user_map(user.id)

  if err then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(
        "error finding map for rbac_user: ", user.id)
  end

  -- don't include user associated to a consumer
  if map then
    return nil
  end

  return user
end


local function remove_default_roles(roles)
  return tablex.map(post_process_role,
    tablex.filter(roles,
      function(role)
        return not role.is_default
  end))
end


local function find_current_user(self, db, helpers)
  local rbac_user, _, err_t = endpoints.select_entity(self, db, rbac_users.schema)
  if err_t then
    return endpoints.handle_error(err_t)
  end
  if not rbac_user then
    return kong.response.exit(404, { message = "No RBAC user by name or id " .. self.params.rbac_users})
  end
  self.rbac_user = rbac_user
end


return {
  ["/rbac/users"] = {
    schema = rbac_users.schema,
    methods = {
      GET  = endpoints.get_collection_endpoint(rbac_users.schema),
      -- post_process_user should be called after GET , but no
      -- post_processing for GETS in endpoints framework
      POST = function(self, db, helpers, post_process)
        return endpoints.post_collection_endpoint(rbac_users.schema)(self, db, helpers)
      end
    }
  },

  ["/rbac/users/:rbac_users"] = {
    schema = rbac_users.schema,
    methods = {
      GET  =
        function(self, db, helpers)
          find_current_user(self, db, helpers)

          -- make sure it's not associated to a consumer
          local map, err = rbac.get_consumer_user_map(self.rbac_user.id)

          if err then
            return responses.send_HTTP_INTERNAL_SERVER_ERROR(
              "error finding map for rbac_user: ", self.rbac_user.id)
          end

          if map then
            return helpers.responses.send_HTTP_NOT_FOUND("No RBAC user by name or id "
              .. self.rbac_user.name)
          end

          return kong.response.exit(200, self.rbac_user)
        end,

      PUT     = endpoints.put_entity_endpoint(rbac_users.schema),
      PATCH   = endpoints.patch_entity_endpoint(rbac_users.schema),
      DELETE  = function(self, db, helpers)
        -- endpoints.delete_entity_endpoint(rbac_users.schema)(self, db, helpers)
        find_current_user(self, db, helpers)
        local roles = db.rbac_users:get_roles(db, self.rbac_user)
        local default_role

        for _, role in ipairs(roles) do
          db.rbac_user_roles:delete({
            user_id = self.rbac_user.id,
            role_id = role.id
          })

          if role.name == self.rbac_user.name then
            default_role = role
          end
        end

        if default_role then
          local _, err = rbac.remove_user_from_default_role(self.rbac_user,
            default_role)
          if err then
            helpers.yield_error(err)
          end
        end

        db.rbac_users:delete({id = self.rbac_user.id})
        return kong.response.exit(204)
      end
      -- XXX: EE DEAL WITH DELETING default role and user<->roles
      -- mappings
    }
  },
  -- XXX: EE
  -- ["/rbac/users/:name_or_id/permissions"] = {},
  ["/rbac/users/:rbac_users/roles"] = {
    schema = rbac_users.schema,
    methods = {
      before = function(self, db, helpers)
        local rbac_user, _, err_t = endpoints.select_entity(self, db, rbac_users.schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not rbac_user then
          return kong.response.exit(404, { message = "No RBAC user by name or id " .. self.params.rbac_users})
        end
        self.rbac_user = rbac_user
      end,

      GET = function(self, db, helpers)
        local rbac_roles = db.rbac_users:get_roles(db, self.rbac_user)

        rbac_roles = remove_default_roles(rbac_roles)

        setmetatable(rbac_roles, cjson.empty_array_mt)
        return kong.response.exit(200, {
          user = self.rbac_user,
          roles = rbac_roles
        })
      end,
      POST = function(self, db, helpers)
        -- we have the user, now verify our roles
        if not self.params.roles then
          return helpers.responses.send_HTTP_BAD_REQUEST("must provide >= 1 role")
        end

        local roles, err = objects_from_names(db, self.params.roles, "role")
        if err then
          if err:find("not found with name", nil, true) then
            return helpers.responses.send_HTTP_BAD_REQUEST(err)

          else
            return helpers.yield_error(err)
          end
        end

        -- we've now validated that all our roles exist, and this user exists,
        -- so time to create the assignment
        for i = 1, #roles do
          local _, _, err_t = db.rbac_user_roles:insert({
            user_id = self.rbac_user.id,
            role_id = roles[i].id
          })

          if err_t then
            return endpoints.handle_error(err_t) -- XXX EE: 400 vs
                                                 -- 409. primary key
                                                 -- validation failed
          end
        end

        -- invalidate rbac user so we don't fetch the old roles
        local cache_key = db["rbac_user_roles"]:cache_key(self.rbac_user.id)
        singletons.cache:invalidate(cache_key)

        -- re-fetch the users roles so we show all the role objects, not just our
        -- newly assigned mappings
        roles, err = db.rbac_users:get_roles(db, self.rbac_user)
        ngx.log(ngx.ERR, [[roles:]], require("inspect")(roles))

        if err then
          return helpers.yield_error(err)
        end

        roles = remove_default_roles(roles)
        ngx.log(ngx.ERR, [[roles:]], require("inspect")(roles))

        -- show the user and all of the roles they are in
        return helpers.responses.send_HTTP_CREATED({
          user  = self.rbac_user,
          roles = roles,
        })
      end,

      DELETE = function(self, db, helpers)
        if not self.params.roles then
          return helpers.responses.send_HTTP_BAD_REQUEST("must provide >= 1 role")
        end

        local roles, err = objects_from_names(db, self.params.roles, "role")
        if err then
          if err:find("not found with name", nil, true) then
            return helpers.responses.send_HTTP_BAD_REQUEST(err)

          else
            return helpers.yield_error(err)
          end
        end

        for i = 1, #roles do
          db.rbac_user_roles:delete({
            user_id = self.rbac_user.id,
            role_id = roles[i].id,
          })
        end

        local cache_key = db.rbac_user_roles:cache_key(self.rbac_user.id)
        -- XXX EE was it a bug before?
        singletons.cache:invalidate(cache_key)

        return helpers.responses.send_HTTP_NO_CONTENT()
      end
    },
  },
  ["/rbac/roles"] = {
    schema = rbac_roles.schema,
    methods = {
      GET  = function(self, db, helpers, parent)
        self.params["is_default"] = false
        return endpoints.get_collection_endpoint(rbac_roles.schema)(self, db, helpers, parent)
      end,
      POST = endpoints.post_collection_endpoint(rbac_roles.schema),
    }
  },
  -- XXX EE:
  -- ["/rbac/roles/:name_or_id/permissions"] = {},

  ["/rbac/roles/:rbac_roles"] = {
    schema = rbac_roles.schema ,
    methods = {
      before = function(self, db, helpers)
        self.params.is_default = false
      end,
      GET  = endpoints.get_entity_endpoint(rbac_roles.schema),
      PUT     = endpoints.put_entity_endpoint(rbac_roles.schema),
      PATCH   = endpoints.patch_entity_endpoint(rbac_roles.schema),

      --- XXX EE: DOESNT WORK. tries to fetch user?
      DELETE = function(self, db, helpers)
        local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not rbac_role then
          return kong.response.exit(404, { message = "Not found" })
        end
        self.rbac_role = rbac_role

        -- delete the user <-> role mappings
        -- we have to get our row, then delete it
        local users, err = db.rbac_roles:get_users(db, self.rbac_role)
        if err then
          return helpers.yield_error(err)
        end

        for i = 1, #users do
          db.rbac_user_roles:delete({
            user_id = users[i].id,
            role_id = self.rbac_role.id,
          })
        end

      local err = rbac.role_relation_cleanup(self.rbac_role)

      if err then
        return nil, err
      end

      -- XXX EE: crud.delete
      db.rbac_roles:delete({id = rbac_role.id})
      return kong.response.exit(204)
      end,
    },
  },

  ["/rbac/roles/:rbac_roles/entities"] = {
    schema = rbac_roles.schema,
    methods = {
    before = function(self, db, helpers)
      local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
      if err_t then
        return endpoints.handle_error(err_t)
      end
      if not rbac_role then
        return kong.response.exit(404, { message = "Not found" })
      end
      self.rbac_role = rbac_role
    end,
    GET = function(self, db, helpers)
      -- XXX: EE. do proper pagination??
      ngx.log(ngx.ERR, [["pre":]], require("inspect")("pre"))

      local entities = rbac.get_role_entities(db, self.rbac_role)
      ngx.log(ngx.ERR, [["post":]], require("inspect")("post"))

      entities = tablex.map(post_process_actions, entities)

      return kong.response.exit(200, {
        data = entities
      })
    end,

    POST = function(self, db, helpers)
      action_bitfield(self)

      if not self.params.entity_id then
        return helpers.responses.send_HTTP_BAD_REQUEST("Missing required parameter: 'entity_id'")
      end

      local entity_type = "wildcard"
      if self.params.entity_id ~= "*" then
        local _, err
        entity_type, _, err = api_helpers.resolve_entity_type(singletons.db,
                                                              singletons.dao,
                                                              self.params.entity_id)
        -- database error
        if entity_type == nil then
          return helpers.responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
        end
        -- entity doesn't exist
        if entity_type == false then
          return helpers.responses.send_HTTP_BAD_REQUEST(err)
        end
      end

      self.params.entity_type = entity_type

      local role_entity, _, err_t = db.rbac_role_entities:insert({
        entity_id = self.params.entity_id,
        role_id = self.rbac_role.id,
        entity_type = entity_type,
        actions = self.params.actions,
        -- negative = self.params.negative
      })
      if err_t then
        return error(err_t)
      end

      return helpers.responses.send_HTTP_CREATED(post_process_actions(role_entity))
    end,
    }
  },

  ["/rbac/roles/:rbac_roles/entities/:entity_id"] = {
    schema = rbac_roles.schema,
    methods = {
      before = function(self, db, helpers)
        local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not rbac_role then
          return kong.response.exit(404, { message = "Not found" })
        end
        self.rbac_role = rbac_role
        self.rbac_role_id = rbac_role.id

        if self.params.entity_id ~= "*" and not utils.is_valid_uuid(self.params.entity_id) then
          return helpers.responses.send_HTTP_BAD_REQUEST(
            self.params.entity_id .. " is not a valid uuid")
        end
        self.entity_id = self.params.entity_id
      end,

      GET = function(self, db, helpers)
        local entity, _, err_t = db.rbac_role_entities:select({
          entity_id = self.entity_id,
          role_id = self.rbac_role_id
        })
        if err_t then
          return endpoints.handle_error(err_t)
        end

        if entity then
          return helpers.responses.send_HTTP_OK(post_process_actions(entity))
        end
      end,
      DELETE = function(self, db, helpers)
        local _, _, err_t = db.rbac_role_entities:delete({
          entity_id = self.entity_id,
          role_id = self.rbac_role_id
        })
        if err_t then
          return endpoints.handle_error(err_t)
        end

        return kong.response.exit(204)
      end

    }

  --   GET = function(self, dao_factory, helpers)
  --     crud.get(self.params, dao_factory.rbac_role_entities,
  --              post_process_actions)
  --   end,

  --   PATCH = function(self, dao_factory, helpers)
  --     if self.params.actions then
  --       action_bitfield(self)
  --     end

  --     local filter = {
  --       role_id = self.params.role_id,
  --       entity_id = self.params.entity_id,
  --     }

  --     self.params.role_id = nil
  --     self.params.entity_id = nil

  --     crud.patch(self.params, dao_factory.rbac_role_entities, filter,
  --                post_process_actions)
  --   end,

  --   DELETE = function(self, dao_factory, helpers)
  --     crud.delete(self.params, dao_factory.rbac_role_entities)
      --   end,
  },

  ["/rbac/roles/:name_or_id/entities/permissions"] = {
    schema = rbac_roles.schema,
    methods = {
      before = function(self, db, helpers)
        error()
      end
    }
  --   before = function(self, dao_factory, helpers)
  --     crud.find_rbac_role_by_name_or_id(self, dao_factory, helpers)
  --   end,

  --   GET = function(self, dao_factory, helpers)
  --     local map = rbac.readable_entities_permissions({self.rbac_role})
  --     return helpers.responses.send_HTTP_OK(map)
  --   end,
  },

  ["/rbac/roles/:rbac_roles/endpoints"] = {
    schema = rbac_roles.schema,
    methods = {
      before = function(self, db, helpers)
        local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not rbac_role then
          return kong.response.exit(404, { message = "Not found" })
        end
        self.rbac_role = rbac_role
        self.params.role_id = self.rbac_role.id
      end,

      GET = function(self, db, helpers)
        local endpoints = db.rbac_roles:get_endpoints(db, self.rbac_role)

        tablex.map(post_process_actions, endpoints) -- post_process_actions
                                                   -- is destructive!
        return kong.response.exit(200, {
          endpoints = endpoints
        })
      end,

      POST = function(self, dao_factory, helpers)
        action_bitfield(self)
        if not self.params.endpoint then
          helpers.responses.send_HTTP_BAD_REQUEST("'endpoint' is a required field")
        end

        local ctx = ngx.ctx
        local request_ws = ctx.workspaces[1]

        -- if the `workspace` parameter wasn't passed, fallback to the current
        -- request's workspace
        self.params.workspace = self.params.workspace or request_ws.name

        local ws_name = self.params.workspace

        if ws_name ~= "*" then
          local w, err = workspaces.run_with_ws_scope({}, singletons.dao.workspaces.find_all, singletons.dao.workspaces, {
            name = ws_name
          })
          if err then
            helpers.yield_error(err)
          end
          if #w == 0 then
            local err = fmt("Workspace %s does not exist", self.params.workspace)
            helpers.responses.send_HTTP_NOT_FOUND(err)
          end
        end

        if not rbac_operation_allowed(singletons.configuration,
          ctx.rbac, request_ws, ws_name) then
          local err_str = fmt(
            "%s is not allowed to create cross workspace permissions",
            ctx.rbac.user.name)
          helpers.responses.send_HTTP_FORBIDDEN(err_str)
        end

        local cache_key = dao_factory["rbac_roles"]:cache_key(self.rbac_role.id)
        singletons.cache:invalidate(cache_key)

        -- strip any whitespaces from both ends
        self.params.endpoint = utils.strip(self.params.endpoint)

        if self.params.endpoint ~= "*" then
          -- normalize endpoint: remove trailing /
          self.params.endpoint = ngx.re.gsub(self.params.endpoint, "/$", "")

          -- make sure the endpoint starts with /, unless it's '*'
          self.params.endpoint = ngx.re.gsub(self.params.endpoint, "^/?", "/")
        end

        self.params.rbac_roles = nil
        local row, err = singletons.db.rbac_role_endpoints:insert(self.params)
        if err then
          return kong.response.exit(400, err)
        end

        return kong.response.exit(201, post_process_actions(row))
      end,
    },
  },
  -- ["/rbac/roles/:rbac_roles/endpoints/:workspace/*"] = {
  --   before = function(self, dao_factory, helpers)
  --     local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
  --     if err_t then
  --       return endpoints.handle_error(err_t)
  --     end
  --     if not rbac_role then
  --       return kong.response.exit(404, { message = "Not found" })
  --     end
  --     self.rbac_role = rbac_role
  --     self.params.role_id = self.rbac_role.id

  --     -- Note: /rbac/roles/:name_or_id/endpoints/:workspace// will be treated same as
  --     -- /rbac/roles/:name_or_id/endpoints/:workspace/
  --     -- this is the limitation of lapis implementation
  --     -- it's not possible to distinguish // from /
  --     -- since the self.params.splat will always be "/"
  --     if self.params.splat ~= "*" and self.params.splat ~= "/" then
  --       self.params.endpoint = "/" .. self.params.splat
  --     else
  --       self.params.endpoint = self.params.splat
  --     end
  --     self.params.splat = nil
  --   end,

  --   GET = function(self, dao_factory, helpers)
  --     crud.get(self.params, dao_factory.rbac_role_endpoints,
  --              post_process_actions)
  --   end,

  --   PATCH = function(self, dao_factory, helpers)
  --     if self.params.actions then
  --       action_bitfield(self)
  --     end

  --     local filter = {
  --       role_id = self.params.role_id,
  --       workspace = self.params.workspace,
  --       endpoint = self.params.endpoint,
  --     }

  --     self.params.role_id = nil
  --     self.params.workspace = nil
  --     self.params.endpoint = nil

  --     crud.patch(self.params, dao_factory.rbac_role_endpoints, filter,
  --                post_process_actions)
  --   end,

  --   DELETE = function(self, dao_factory, helpers)
  --     crud.delete(self.params, dao_factory.rbac_role_endpoints)
  --   end,
  -- },

  ["/rbac/roles/:rbac_roles/endpoints/permissions"] = {
    schema = rbac_roles.schema,
    methods = {
      before = function(self, db, helpers)
        local rbac_role, _, err_t = endpoints.select_entity(self, db, rbac_roles.schema)
        if err_t then
          return endpoints.handle_error(err_t)
        end
        if not rbac_role then
          return kong.response.exit(404, { message = "Not found" })
        end
        self.rbac_role = rbac_role
        self.params.role_id = self.rbac_role.id

      end,

      GET = function(self, dao_factory, helpers)
        local map = rbac.readable_endpoints_permissions({self.rbac_role})
        return helpers.responses.send_HTTP_OK(map)
      end,
    }
  },
  ["/rbac/users/consumers"] = {
    schema = consumers.schema,
    methods = {
      POST = function(self, dao_factory)
        -- TODO: validate consumer and user here
        crud.post(self.params, dao_factory.consumers_rbac_users_map)
      end
    },
  },

  -- ["/rbac/users/:user_id/consumers/:consumer_id"] = {
  --   before = function(self, dao_factory, helpers)
  --     crud.find_consumer_rbac_user_map(self, dao_factory, helpers)
  --   end,

  --   GET = function(self, dao_factory, helpers)
  --     return helpers.responses.send_HTTP_OK(self.consumer_rbac_user_map)
  --   end,
  -- },
  }
