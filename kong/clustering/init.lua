-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local _M = {}
local _MT = { __index = _M, }


local pl_file = require("pl.file")
local pl_tablex = require("pl.tablex")
local ws_server = require("resty.websocket.server")
local ws_client = require("resty.websocket.client")
local ssl = require("ngx.ssl")
local openssl_x509 = require("resty.openssl.x509")
local ngx_log = ngx.log
local assert = assert
local sort = table.sort

local check_protocol_support =
  require("kong.clustering.utils").check_protocol_support

local check_for_revocation_status = clustering_utils.check_for_revocation_status

-- XXX EE
local semaphore = require("ngx.semaphore")
local cjson = require("cjson.safe")
local utils = require("kong.tools.utils")
local declarative = require("kong.db.declarative")
local assert = assert
local setmetatable = setmetatable
local ngx = ngx
local ngx_log = ngx.log
local ngx_WARN = ngx.WARN
local ngx_NOTICE = ngx.NOTICE
local ngx_var = ngx.var
local cjson_decode = cjson.decode
local kong = kong
local ngx_exit = ngx.exit
local exiting = ngx.worker.exiting
local table_insert = table.insert
local table_remove = table.remove
local inflate_gzip = utils.inflate_gzip
local deflate_gzip = utils.deflate_gzip
local get_cn_parent_domain = utils.get_cn_parent_domain
local ngx_ERR = ngx.ERR
local ngx_DEBUG = ngx.DEBUG
local server_on_message_callbacks = {}
local MAX_PAYLOAD = kong.configuration.cluster_max_payload
local WS_OPTS = {
  timeout = constants.CLUSTERING_TIMEOUT,
  max_payload_len = MAX_PAYLOAD,
}


local _log_prefix = "[clustering] "


function _M.new(conf)
  assert(conf, "conf can not be nil", 2)

  local self = {
    conf = conf,
  }

  setmetatable(self, _MT)

  local cert = assert(pl_file.read(conf.cluster_cert))
  self.cert = assert(ssl.parse_pem_cert(cert))

  cert = openssl_x509.new(cert, "PEM")
  self.cert_digest = cert:digest("sha256")
  local _, cert_cn_parent = get_cn_parent_domain(cert)

  if conf.cluster_allowed_common_names and #conf.cluster_allowed_common_names > 0 then
    self.cn_matcher = {}
    for _, cn in ipairs(conf.cluster_allowed_common_names) do
      self.cn_matcher[cn] = true
    end

  else
    self.cn_matcher = setmetatable({}, {
      __index = function(_, k)
        return string.match(k, "^[%a%d-]+%.(.+)$") == cert_cn_parent
      end
    })

  end

  local key = assert(pl_file.read(conf.cluster_cert_key))
  self.cert_key = assert(ssl.parse_pem_priv_key(key))

  --- XXX EE: needed for encrypting config cache at the rest
  -- this will be used at init_worker()
  if conf.role == "data_plane" and conf.data_plane_config_cache_mode == "encrypted" then
    self.cert_public = cert:get_pubkey()
    self.cert_private = key
  end
  --- EE

  if conf.role == "control_plane" then
    self.json_handler =
      require("kong.clustering.control_plane").new(self.conf, self.cert_digest)

    self.wrpc_handler =
      require("kong.clustering.wrpc_control_plane").new(self.conf, self.cert_digest)
  end


  return self
end


function _M:handle_cp_websocket()
  return self.json_handler:handle_cp_websocket()
end



function _M:validate_client_cert(cert, log_prefix, log_suffix)
  if not cert then
    return false, "data plane failed to present client certificate during handshake"
  end

  local err
  cert, err = openssl_x509.new(cert, "PEM")
  if not cert then
    return false, "unable to load data plane client certificate during handshake: " .. err
  end

  if kong.configuration.cluster_mtls == "shared" then
    local digest, err = cert:digest("sha256")
    if not digest then
      return false, "unable to retrieve data plane client certificate digest during handshake: " .. err
    end

    if digest ~= self.cert_digest then
      return false, "data plane presented incorrect client certificate during handshake (expected: " ..
                    self.cert_digest .. ", got: " .. digest .. ")"
    end

  elseif kong.configuration.cluster_mtls == "pki_check_cn" then
    local cn, _ = get_cn_parent_domain(cert)
    if not cn then
      return false, "data plane presented incorrect client certificate " ..
                    "during handshake, unable to extract CN: " .. cn

    elseif not self.cn_matcher[cn] then
      return false, "data plane presented client certificate with incorrect CN " ..
                    "during handshake, got: " .. cn
    end
  elseif kong.configuration.cluster_ocsp ~= "off" then
    local ok
    ok, err = check_for_revocation_status()
    if ok == false then
      err = "data plane client certificate was revoked: " ..  err
      return false, err

    elseif not ok then
      if self.conf.cluster_ocsp == "on" then
        err = "data plane client certificate revocation check failed: " .. err
        return false, err

      else
        if log_prefix and log_suffix then
          ngx_log(ngx_WARN, log_prefix, "data plane client certificate revocation check failed: ", err, log_suffix)
        else
          ngx_log(ngx_WARN, "data plane client certificate revocation check failed: ", err)
        end
      end
    end
  end
  -- with cluster_mtls == "pki", always return true as in this mode we only check
  -- if client cert matches CA and it's already done by Nginx

  return true
end


-- XXX EE telemetry_communicate is written for hybrid mode over websocket.
-- It should be migrated to wRPC later.
-- ws_event_loop, is_timeout, and send_ping is for handle_cp_telemetry_websocket only.
-- is_timeout and send_ping is copied here to keep the code functioning.

local function is_timeout(err)
  return err and sub(err, -7) == "timeout"
end

local function send_ping(c, log_suffix)
  log_suffix = log_suffix or ""

  local hash = declarative.get_current_hash()

  if hash == true then
    hash = DECLARATIVE_EMPTY_CONFIG_HASH
  end

  local _, err = c:send_ping(hash)
  if err then
    ngx_log(is_timeout(err) and ngx_NOTICE or ngx_WARN, _log_prefix,
            "unable to send ping frame to control plane: ", err, log_suffix)

  else
    ngx_log(ngx_DEBUG, _log_prefix, "sent ping frame to control plane", log_suffix)
  end
end

-- XXX EE only used for telemetry, remove cruft
local function ws_event_loop(ws, on_connection, on_error, on_message)
  local sem = semaphore.new()
  local queue = { sem = sem, }

  local function queued_send(msg)
    table_insert(queue, msg)
    queue.sem:post()
  end

  local recv = ngx.thread.spawn(function()
    while not exiting() do
      local data, typ, err = ws:recv_frame()
      if err then
        ngx.log(ngx.ERR, "error while receiving frame from peer: ", err)
        if ws.close then
          ws:close()
        end

        if on_connection then
          local _, err = on_connection(false)
          if err then
            ngx_log(ngx_ERR, "error when executing on_connection function: ", err)
          end
        end

        if on_error then
          local _, err = on_error(err)
          if err then
            ngx_log(ngx_ERR, "error when executing on_error function: ", err)
          end
        end
        return
      end

      if (typ == "ping" or typ == "binary") and on_message then
        local cbs
        if typ == "binary" then
          data = assert(inflate_gzip(data))
          data = assert(cjson_decode(data))

          cbs = on_message[data.type]
        else
          cbs = on_message[typ]
        end

        if cbs then
          for _, cb in ipairs(cbs) do
            local _, err = cb(data, queued_send)
            if err then
              ngx_log(ngx_ERR, "error when executing on_message function: ", err)
            end
          end
        end
      elseif typ == "pong" then
        ngx_log(ngx_DEBUG, "received PONG frame from peer")
      end
    end
    end)

    local send = ngx.thread.spawn(function()
      while not exiting() do
        local ok, err = sem:wait(10)
        if ok then
          local payload = table_remove(queue, 1)
          assert(payload, "client message queue can not be empty after semaphore returns")

          if payload == "PONG" then
            local _
            _, err = ws:send_pong()
            if err then
              ngx_log(ngx_ERR, "failed to send PONG back to peer: ", err)
              return ngx_exit(ngx_ERR)
            end

            ngx_log(ngx_DEBUG, "sent PONG packet back to peer")
          elseif payload == "PING" then
            local _
            _, err = send_ping(ws)
            if err then
              ngx_log(ngx_ERR, "failed to send PING to peer: ", err)
              return ngx_exit(ngx_ERR)
            end

            ngx_log(ngx_DEBUG, "sent PING packet to peer")
          else
            payload = assert(deflate_gzip(payload))
            local _, err = ws:send_binary(payload)
            if err then
              ngx_log(ngx_ERR, "unable to send binary to peer: ", err)
            end
          end

        else -- not ok
          if err ~= "timeout" then
            ngx_log(ngx_ERR, "semaphore wait error: ", err)
          end
        end
      end
    end)

    local wait = function()
      return ngx.thread.wait(recv, send)
    end

    return queued_send, wait

end

local function telemetry_communicate(premature, self, uri, server_name, on_connection, on_message)
  if premature then
    -- worker wants to exit
    return
  end

  local reconnect = function(delay)
    return ngx.timer.at(delay, telemetry_communicate, self, uri, server_name, on_connection, on_message)
  end

  local c = assert(ws_client:new(WS_OPTS))

  local opts = {
    ssl_verify = true,
    client_cert = self.cert,
    client_priv_key = self.cert_key,
    server_name = server_name,
  }

  local res, err = c:connect(uri, opts)
  if not res then
    local delay = math.random(5, 10)

    ngx_log(ngx_ERR, "connection to control plane ", uri, " broken: ", err,
            " retrying after ", delay , " seconds")

    assert(reconnect(delay))
    return
  end

  local queued_send, wait = ws_event_loop(c,
    on_connection,
    function()
      assert(reconnect(9 + math.random()))
    end,
    on_message)


  if on_connection then
    local _, err = on_connection(true, queued_send)
    if err then
      ngx_log(ngx_ERR, "error when executing on_connection function: ", err)
    end
  end

  wait()

end

_M.telemetry_communicate = telemetry_communicate

function _M:handle_cp_telemetry_websocket()
  -- use mutual TLS authentication
  local ok, err = self:validate_client_cert(ngx_var.ssl_client_raw_cert)
  if not ok then
    ngx_log(ngx_ERR, err)
    return ngx_exit(444)
  end

  local node_id = ngx_var.arg_node_id
  if not node_id then
    ngx_exit(400)
  end

  local wb, err = ws_server:new(WS_OPTS)
  if not wb then
    ngx_log(ngx_ERR, "failed to perform server side WebSocket handshake: ", err)
    return ngx_exit(444)
  end

  local current_on_message_callbacks = {}
  for k, v in pairs(server_on_message_callbacks) do
    current_on_message_callbacks[k] = v
  end

  local _, wait = ws_event_loop(wb,
    nil,
    function(_)
      return ngx_exit(ngx_ERR)
    end,
    current_on_message_callbacks)

  wait()
end

function _M:handle_wrpc_websocket()
  return self.wrpc_handler:handle_cp_websocket()
end

function _M:init_cp_worker(plugins_list)
  self.json_handler:init_worker(plugins_list)
  self.wrpc_handler:init_worker(plugins_list)
end

function _M:init_dp_worker(plugins_list)
  local start_dp = function(premature)
    if premature then
      return
    end

    local config_proto, msg = check_protocol_support(self.conf, self.cert, self.cert_key)

    if not config_proto and msg then
      ngx_log(ngx_ERR, _log_prefix, "error check protocol support: ", msg)
    end

    ngx_log(ngx_DEBUG, _log_prefix, "config_proto: ", config_proto, " / ", msg)

    local data_plane
    if config_proto == "v0" or config_proto == nil then
      data_plane = "kong.clustering.data_plane"

    else -- config_proto == "v1" or higher
      data_plane = "kong.clustering.wrpc_data_plane"
    end

    self.child = require(data_plane).new(self.conf, self.cert, self.cert_key)

    --- XXX EE: clear private key as it is not needed after this point
    self.cert_private = nil
    --- EE

    if self.child then
      self.child:init_worker(plugins_list)
    end
  end

  assert(ngx.timer.at(0, start_dp))
end

function _M:init_worker()
  local plugins_list = assert(kong.db.plugins:get_handlers())
  sort(plugins_list, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  plugins_list = pl_tablex.map(function(p)
    return { name = p.name, version = p.handler.VERSION, }
  end, plugins_list)

  local role = self.conf.role

  if role == "control_plane" then
    self:init_cp_worker(plugins_list)
    return
  end

  if role == "data_plane" and ngx.worker.id() == 0 then
    self:init_dp_worker(plugins_list)
  end
end

function _M.register_server_on_message(typ, cb)
  if not server_on_message_callbacks[typ] then
    server_on_message_callbacks[typ] = { cb }
  else
    table.insert(server_on_message_callbacks[typ], cb)
  end
end

return _M
