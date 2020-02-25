package = "kong"
version = "2.0.0-0"
supported_platforms = {"linux", "macosx"}
source = {
  url = "git://github.com/Kong/kong",
  tag = "2.0.0"
}
description = {
  summary = "Kong is a scalable and customizable API Management Layer built on top of Nginx.",
  homepage = "https://konghq.com",
  license = "Apache 2.0"
}
dependencies = {
  "inspect == 3.1.1",
  "luasec == 0.9",
  "luasocket == 3.0-rc1",
  "penlight == 1.7.0",
  "lua-resty-http == 0.15",
  "lua-resty-jit-uuid == 0.0.7",
  "multipart == 0.5.6",
  "version == 1.0.1",
  "kong-redis-cluster == 1.1-0",
  "kong-lapis == 1.7.0.1",
  "lua-cassandra == 1.5.0",
  "pgmoon == 1.10.0",
  "luatz == 0.4",
  "lua_system_constants == 0.1.4",
  "lyaml == 6.2.4",
  "lua-resty-iputils == 0.3.0",
  "luasyslog == 1.0.0",
  "lua_pack == 1.0.5",
  "lua-resty-mail == 1.0.2",
  "lua-resty-redis-connector == 0.08",
  "lua-resty-rsa == 0.04",
  "lyaml == 6.2.4",
  "bcrypt == 2.1",
  "lpeg_patterns == 0.5",
  "lua-resty-dns-client == 4.1.3",
  "lua-resty-worker-events == 1.0.0",
  "lua-resty-mediador == 0.1.2",
  "lua-resty-healthcheck == 1.1.2",
  "lua-resty-cookie == 0.1.0",
  "lua-resty-mlcache == 2.4.1",
  "lua-messagepack == 0.5.2",
  "lua-resty-openssl == 0.4.2",
  "lua-resty-counter == 0.2.0",
  "lua-resty-template == 1.9-1",
  "lua-resty-passwdqc == 1.1-1",
  -- external Kong plugins
  "kong-plugin-kubernetes-sidecar-injector ~> 0.2.1",
  "kong-plugin-azure-functions ~> 0.4.1",
  "kong-plugin-serverless-functions ~> 0.3.1",
  "kong-prometheus-plugin ~> 0.7",
  "kong-plugin-session == 2.2.0",
  "kong-proxy-cache-plugin ~> 1.2.2",
  "kong-plugin-request-transformer ~> 1.2.4",
  "kong-plugin-aws-lambda ~> 3.1.0",
  "kong-plugin-zipkin ~> 0.2",
  "kong-plugin-acme ~> 0.2",
}
build = {
  type = "builtin",
  modules = {
    ["kong"] = "kong/init.lua",
    ["kong.meta"] = "kong/meta.lua",
    ["kong.cache"] = "kong/cache.lua",
    ["kong.global"] = "kong/global.lua",
    ["kong.router"] = "kong/router.lua",
    ["kong.reports"] = "kong/reports.lua",
    ["kong.constants"] = "kong/constants.lua",
    ["kong.singletons"] = "kong/singletons.lua",
    ["kong.concurrency"] = "kong/concurrency.lua",
    ["kong.conf_loader"] = "kong/conf_loader.lua",
    ["kong.cache_warmup"] = "kong/cache_warmup.lua",
    ["kong.globalpatches"] = "kong/globalpatches.lua",
    ["kong.error_handlers"] = "kong/error_handlers.lua",
    ["kong.clustering"] = "kong/clustering.lua",

    ["kong.cluster_events"] = "kong/cluster_events/init.lua",
    ["kong.cluster_events.strategies.cassandra"] = "kong/cluster_events/strategies/cassandra.lua",
    ["kong.cluster_events.strategies.postgres"] = "kong/cluster_events/strategies/postgres.lua",
    ["kong.cluster_events.strategies.off"] = "kong/cluster_events/strategies/off.lua",

    ["kong.tracing"] = "kong/tracing/init.lua",
    ["kong.tracing.strategies"] = "kong/tracing/strategies.lua",

    ["kong.counters"] = "kong/counters/init.lua",
    ["kong.counters.sales"] = "kong/counters/sales/init.lua",
    ["kong.counters.sales.strategies.postgres"] = "kong/counters/sales/strategies/postgres/init.lua",
    ["kong.counters.sales.strategies.cassandra"] = "kong/counters/sales/strategies/cassandra/init.lua",

    ["kong.enterprise_edition"] = "kong/enterprise_edition/init.lua",
    ["kong.enterprise_edition.admin.emails"] = "kong/enterprise_edition/admin/emails.lua",
    ["kong.enterprise_edition.admins_helpers"] = "kong/enterprise_edition/admins_helpers.lua",
    ["kong.enterprise_edition.api_helpers"] = "kong/enterprise_edition/api_helpers.lua",
    ["kong.enterprise_edition.audit_log"] = "kong/enterprise_edition/audit_log.lua",
    ["kong.enterprise_edition.auth_helpers"] = "kong/enterprise_edition/auth_helpers.lua",
    ["kong.enterprise_edition.conf_loader"] = "kong/enterprise_edition/conf_loader.lua",
    ["kong.enterprise_edition.consumer_reset_secret_helpers"] = "kong/enterprise_edition/consumer_reset_secret_helpers.lua",
    ["kong.enterprise_edition.crud_helpers"] = "kong/enterprise_edition/crud_helpers.lua",
    ["kong.enterprise_edition.dao.enums"] = "kong/enterprise_edition/dao/enums.lua",
    ["kong.enterprise_edition.dao.factory"] = "kong/enterprise_edition/dao/factory.lua",
    ["kong.enterprise_edition.db.migrations.helpers"] = "kong/enterprise_edition/db/migrations/helpers.lua",
    ["kong.enterprise_edition.db.migrations.migrate_core_entities"] = "kong/enterprise_edition/db/migrations/migrate_core_entities.lua",
    ["kong.enterprise_edition.db.typedefs"] = "kong/enterprise_edition/db/typedefs.lua",
    ["kong.enterprise_edition.feature_flags"] = "kong/enterprise_edition/feature_flags.lua",
    ["kong.enterprise_edition.jwt"] = "kong/enterprise_edition/jwt.lua",
    ["kong.enterprise_edition.license_helpers"] = "kong/enterprise_edition/license_helpers.lua",
    ["kong.enterprise_edition.meta"] = "kong/enterprise_edition/meta.lua",
    ["kong.enterprise_edition.oas_config"] = "kong/enterprise_edition/oas_config.lua",
    ["kong.enterprise_edition.plugin_overwrite"] = "kong/enterprise_edition/plugin_overwrite.lua",
    ["kong.enterprise_edition.proxies"] = "kong/enterprise_edition/proxies.lua",
    ["kong.enterprise_edition.redis"] = "kong/enterprise_edition/redis/init.lua",
    ["kong.enterprise_edition.smtp_client"] = "kong/enterprise_edition/smtp_client.lua",
    ["kong.enterprise_edition.utils"] = "kong/enterprise_edition/utils.lua",
    ["kong.enterprise_edition.invoke_plugin"] = "kong/enterprise_edition/invoke_plugin.lua",
    ["kong.enterprise_edition.distributions_constants"] = "kong/enterprise_edition/distributions_constants.lua",
    ["kong.enterprise_edition.pdk.response"] = "kong/enterprise_edition/pdk/response.lua",

    ["kong.templates.nginx"] = "kong/templates/nginx.lua",
    ["kong.templates.nginx_kong"] = "kong/templates/nginx_kong.lua",
    ["kong.templates.nginx_kong_stream"] = "kong/templates/nginx_kong_stream.lua",
    ["kong.templates.kong_defaults"] = "kong/templates/kong_defaults.lua",
    ["kong.templates.kong_yml"] = "kong/templates/kong_yml.lua",

    ["kong.resty.ctx"] = "kong/resty/ctx.lua",
    ["kong.vendor.classic"] = "kong/vendor/classic.lua",

    ["kong.cmd"] = "kong/cmd/init.lua",
    ["kong.cmd.roar"] = "kong/cmd/roar.lua",
    ["kong.cmd.stop"] = "kong/cmd/stop.lua",
    ["kong.cmd.quit"] = "kong/cmd/quit.lua",
    ["kong.cmd.start"] = "kong/cmd/start.lua",
    ["kong.cmd.check"] = "kong/cmd/check.lua",
    ["kong.cmd.config"] = "kong/cmd/config.lua",
    ["kong.cmd.reload"] = "kong/cmd/reload.lua",
    ["kong.cmd.restart"] = "kong/cmd/restart.lua",
    ["kong.cmd.prepare"] = "kong/cmd/prepare.lua",
    ["kong.cmd.migrations"] = "kong/cmd/migrations.lua",
    ["kong.cmd.health"] = "kong/cmd/health.lua",
    ["kong.cmd.version"] = "kong/cmd/version.lua",
    ["kong.cmd.runner"] = "kong/cmd/runner.lua",
    ["kong.cmd.hybrid"] = "kong/cmd/hybrid.lua",
    ["kong.cmd.utils.log"] = "kong/cmd/utils/log.lua",
    ["kong.cmd.utils.kill"] = "kong/cmd/utils/kill.lua",
    ["kong.cmd.utils.env"] = "kong/cmd/utils/env.lua",
    ["kong.cmd.utils.migrations"] = "kong/cmd/utils/migrations.lua",
    ["kong.cmd.utils.tty"] = "kong/cmd/utils/tty.lua",
    ["kong.cmd.utils.nginx_signals"] = "kong/cmd/utils/nginx_signals.lua",
    ["kong.cmd.utils.prefix_handler"] = "kong/cmd/utils/prefix_handler.lua",

    ["kong.api"] = "kong/api/init.lua",
    ["kong.api.api_helpers"] = "kong/api/api_helpers.lua",
    ["kong.api.arguments"] = "kong/api/arguments.lua",
    ["kong.api.endpoints"] = "kong/api/endpoints.lua",
    ["kong.api.routes.kong"] = "kong/api/routes/kong.lua",
    ["kong.api.routes.health"] = "kong/api/routes/health.lua",
    ["kong.api.routes.config"] = "kong/api/routes/config.lua",
    ["kong.api.routes.consumers"] = "kong/api/routes/consumers.lua",
    ["kong.api.routes.plugins"] = "kong/api/routes/plugins.lua",
    ["kong.api.routes.routes"] = "kong/api/routes/routes.lua",
    ["kong.api.routes.services"] = "kong/api/routes/services.lua",
    ["kong.api.routes.cache"] = "kong/api/routes/cache.lua",
    ["kong.api.routes.upstreams"] = "kong/api/routes/upstreams.lua",
    ["kong.api.routes.targets"] = "kong/api/routes/targets.lua",
    ["kong.api.routes.certificates"] = "kong/api/routes/certificates.lua",
    ["kong.api.routes.snis"] = "kong/api/routes/snis.lua",
    ["kong.api.routes.rbac" ] = "kong/api/routes/rbac.lua",
    ["kong.api.routes.vitals" ] = "kong/api/routes/vitals.lua",
    ["kong.api.routes.workspaces"] = "kong/api/routes/workspaces.lua",
    ["kong.api.routes.files"] = "kong/api/routes/files.lua",
    ["kong.api.routes.admins"] = "kong/api/routes/admins.lua",
    ["kong.api.routes.audit"] = "kong/api/routes/audit.lua",
    ["kong.api.routes.oas_config"] = "kong/api/routes/oas_config.lua",
    ["kong.api.routes.developers"] = "kong/api/routes/developers.lua",
    ["kong.api.routes.tags"] = "kong/api/routes/tags.lua",
    ["kong.api.routes.groups"] = "kong/api/routes/groups.lua",
    ["kong.api.routes.license"] = "kong/api/routes/license.lua",
    ["kong.api.routes.entities"] = "kong/api/routes/entities.lua",
    ["kong.api.routes.keyring"] = "kong/api/routes/keyring.lua",
    ["kong.api.routes.clustering"] = "kong/api/routes/clustering.lua",

    ["kong.status"] = "kong/status/init.lua",

    ["kong.tools.dns"] = "kong/tools/dns.lua",
    ["kong.tools.utils"] = "kong/tools/utils.lua",
    ["kong.tools.printable"] = "kong/tools/printable.lua",
    ["kong.tools.timestamp"] = "kong/tools/timestamp.lua",
    ["kong.tools.batch_queue"] = "kong/tools/batch_queue.lua",

    ["kong.tools.public.rate-limiting"] = "kong/tools/public/rate-limiting/init.lua",
    ["kong.tools.public.rate-limiting.strategies.cassandra"] = "kong/tools/public/rate-limiting/strategies/cassandra.lua",
    ["kong.tools.public.rate-limiting.strategies.postgres"] = "kong/tools/public/rate-limiting/strategies/postgres.lua",
    ["kong.tools.public.rate-limiting.strategies.redis"] = "kong/tools/public/rate-limiting/strategies/redis.lua",

    -- XXX merge - files added or modified by enterprise, all of which no longer exist
    -- upstream (in 0.15.0)
    ["kong.enterprise_edition.db.migrations.enterprise"] = "kong/enterprise_edition/db/migrations/enterprise/init.lua",
    ["kong.enterprise_edition.db.migrations.enterprise.000_base"] = "kong/enterprise_edition/db/migrations/enterprise/000_base.lua",
    ["kong.enterprise_edition.db.migrations.enterprise.006_1301_to_1400"] = "kong/enterprise_edition/db/migrations/enterprise/006_1301_to_1400.lua",

    ["kong.runloop.handler"] = "kong/runloop/handler.lua",
    ["kong.runloop.certificate"] = "kong/runloop/certificate.lua",
    ["kong.runloop.plugins_iterator"] = "kong/runloop/plugins_iterator.lua",
    ["kong.runloop.balancer"] = "kong/runloop/balancer.lua",

    ["kong.db.schema.entities.credentials"] = "kong/db/schema/entities/credentials.lua",
    ["kong.db.schema.entities.files"] = "kong/db/schema/entities/files.lua",
    ["kong.db.schema.entities.legacy_files"] = "kong/db/schema/entities/legacy_files.lua",
    ["kong.db.schema.entities.consumer_reset_secrets"] = "kong/db/schema/entities/consumer_reset_secrets.lua",
    ["kong.db.schema.entities.login_attempts"] = "kong/db/schema/entities/login_attempts.lua",

    ["kong.rbac"] = "kong/rbac/init.lua",
    ["kong.rbac.migrations.01_defaults"] = "kong/rbac/migrations/01_defaults.lua",
    ["kong.rbac.migrations.03_user_default_role"] = "kong/rbac/migrations/03_user_default_role.lua",
    ["kong.rbac.migrations.04_kong_admin_basic_auth"] = "kong/rbac/migrations/04_kong_admin_basic_auth.lua",
    ["kong.rbac.migrations.05_super_admin"] = "kong/rbac/migrations/05_super_admin.lua",

    ["kong.workspaces"] = "kong/workspaces/init.lua",
    ["kong.workspaces.counters"] = "kong/workspaces/counters.lua",

    ["kong.portal"] = "kong/portal/init.lua",
    ["kong.portal.api"] = "kong/portal/api.lua",
    ["kong.portal.dao_helpers"] = "kong/portal/dao_helpers.lua",
    ["kong.portal.crud_helpers"] = "kong/portal/crud_helpers.lua",
    ["kong.portal.utils"] = "kong/portal/utils.lua",
    ["kong.portal.migrations.01_initial_files"] = "kong/portal/migrations/01_initial_files.lua",
    ["kong.portal.migrations.01_legacy_files"] = "kong/portal/migrations/01_legacy_files.lua",
    ["kong.portal.emails"] = "kong/portal/emails.lua",
    ["kong.portal.gui"] = "kong/portal/gui.lua",
    ["kong.portal.auth"] = "kong/portal/auth.lua",
    ["kong.portal.renderer"] = "kong/portal/renderer.lua",
    ["kong.portal.permissions"] = "kong/portal/permissions.lua",
    ["kong.portal.file_helpers"] = "kong/portal/file_helpers.lua",
    ["kong.portal.gui_helpers"] = "kong/portal/gui_helpers.lua",
    ["kong.portal.router"] = "kong/portal/router.lua",
    ["kong.portal.template"] = "kong/portal/template.lua",
    ["kong.portal.legacy_renderer"] = "kong/portal/legacy_renderer.lua",
    ["kong.portal.render_toolset.base"] = "kong/portal/render_toolset/base/init.lua",
    ["kong.portal.render_toolset.looper"] = "kong/portal/render_toolset/looper.lua",
    ["kong.portal.render_toolset.markdown"] = "kong/portal/render_toolset/markdown.lua",
    ["kong.portal.render_toolset.base.boolean"] = "kong/portal/render_toolset/base/boolean.lua",
    ["kong.portal.render_toolset.base.number"] = "kong/portal/render_toolset/base/number.lua",
    ["kong.portal.render_toolset.base.string"] = "kong/portal/render_toolset/base/string.lua",
    ["kong.portal.render_toolset.base.table"] = "kong/portal/render_toolset/base/table.lua",
    ["kong.portal.render_toolset.handler"] = "kong/portal/render_toolset/handler.lua",
    ["kong.portal.render_toolset.helpers"] = "kong/portal/render_toolset/helpers.lua",
    ["kong.portal.render_toolset.page"] = "kong/portal/render_toolset/page/init.lua",
    ["kong.portal.render_toolset.portal"] = "kong/portal/render_toolset/portal/init.lua",
    ["kong.portal.render_toolset.theme"] = "kong/portal/render_toolset/theme/init.lua",
    ["kong.portal.render_toolset.user"] = "kong/portal/render_toolset/user/init.lua",

    ["kong.vitals"] = "kong/vitals/init.lua",
    ["kong.vitals.cassandra.strategy"] = "kong/vitals/cassandra/strategy.lua",
    ["kong.vitals.postgres.strategy"] = "kong/vitals/postgres/strategy.lua",
    ["kong.vitals.postgres.table_rotater"] = "kong/vitals/postgres/table_rotater.lua",
    ["kong.vitals.prometheus.strategy"] = "kong/vitals/prometheus/strategy.lua",
    ["kong.vitals.prometheus.statsd.logger"] = "kong/vitals/prometheus/statsd/logger.lua",
    ["kong.vitals.prometheus.statsd.handler"] = "kong/vitals/prometheus/statsd/handler.lua",
    ["kong.vitals.influxdb.strategy"] = "kong/vitals/influxdb/strategy.lua",
    ["kong.db"] = "kong/db/init.lua",
    ["kong.db.errors"] = "kong/db/errors.lua",
    ["kong.db.iteration"] = "kong/db/iteration.lua",
    ["kong.db.dao"] = "kong/db/dao/init.lua",
    ["kong.db.dao.admins"] = "kong/db/dao/admins.lua",
    ["kong.db.dao.consumers"] = "kong/db/dao/consumers.lua",
    ["kong.db.dao.developers"] = "kong/db/dao/developers.lua",
    ["kong.db.dao.certificates"] = "kong/db/dao/certificates.lua",
    ["kong.db.dao.snis"] = "kong/db/dao/snis.lua",
    ["kong.db.dao.targets"] = "kong/db/dao/targets.lua",
    ["kong.db.dao.plugins"] = "kong/db/dao/plugins.lua",
    ["kong.db.dao.rbac_role_endpoints"] = "kong/db/dao/rbac_role_endpoints.lua",
    ["kong.db.dao.workspaces"] = "kong/db/dao/workspaces.lua",
    ["kong.db.dao.plugins.go"] = "kong/db/dao/plugins/go.lua",
    ["kong.db.dao.tags"] = "kong/db/dao/tags.lua",
    ["kong.db.dao.files"] = "kong/db/dao/files.lua",
    ["kong.db.dao.keyring_meta"] = "kong/db/dao/keyring_meta.lua",
    ["kong.db.declarative"] = "kong/db/declarative/init.lua",
    ["kong.db.schema"] = "kong/db/schema/init.lua",
    ["kong.db.schema.entities.admins"] = "kong/db/schema/entities/admins.lua",
    ["kong.db.schema.entities.consumers"] = "kong/db/schema/entities/consumers.lua",
    ["kong.db.schema.entities.routes"] = "kong/db/schema/entities/routes.lua",
    ["kong.db.schema.entities.routes_subschemas"] = "kong/db/schema/entities/routes_subschemas.lua",
    ["kong.db.schema.entities.services"] = "kong/db/schema/entities/services.lua",
    ["kong.db.schema.entities.certificates"] = "kong/db/schema/entities/certificates.lua",
    ["kong.db.schema.entities.snis"] = "kong/db/schema/entities/snis.lua",
    ["kong.db.schema.entities.upstreams"] = "kong/db/schema/entities/upstreams.lua",
    ["kong.db.schema.entities.targets"] = "kong/db/schema/entities/targets.lua",
    ["kong.db.schema.entities.plugins"] = "kong/db/schema/entities/plugins.lua",
    ["kong.db.schema.entities.developers"] = "kong/db/schema/entities/developers.lua",
    ["kong.db.schema.entities.workspaces"] = "kong/db/schema/entities/workspaces.lua",
    ["kong.db.schema.entities.workspace_entities"] = "kong/db/schema/entities/workspace_entities.lua",
    ["kong.db.schema.entities.workspace_entity_counters"] = "kong/db/schema/entities/workspace_entity_counters.lua",
    ["kong.db.schema.entities.rbac_users"] = "kong/db/schema/entities/rbac_users.lua",
    ["kong.db.schema.entities.rbac_user_roles"] = "kong/db/schema/entities/rbac_user_roles.lua",
    ["kong.db.schema.entities.rbac_roles"] = "kong/db/schema/entities/rbac_roles.lua",
    ["kong.db.schema.entities.rbac_role_endpoints"] = "kong/db/schema/entities/rbac_role_endpoints.lua",
    ["kong.db.schema.entities.rbac_role_entities"] = "kong/db/schema/entities/rbac_role_entities.lua",
    ["kong.db.schema.entities.audit_objects"] = "kong/db/schema/entities/audit_objects.lua",
    ["kong.db.schema.entities.audit_requests"] = "kong/db/schema/entities/audit_requests.lua",
    ["kong.db.schema.entities.keyring_meta"] = "kong/db/schema/entities/keyring_meta.lua",
    ["kong.db.schema.entities.tags"] = "kong/db/schema/entities/tags.lua",
    ["kong.db.schema.entities.ca_certificates"] = "kong/db/schema/entities/ca_certificates.lua",
    ["kong.db.schema.entities.groups"] = "kong/db/schema/entities/groups.lua",
    ["kong.db.schema.entities.group_rbac_roles"] = "kong/db/schema/entities/group_rbac_roles.lua",
    ["kong.db.schema.others.migrations"] = "kong/db/schema/others/migrations.lua",
    ["kong.db.schema.others.declarative_config"] = "kong/db/schema/others/declarative_config.lua",
    ["kong.db.schema.entity"] = "kong/db/schema/entity.lua",
    ["kong.db.schema.metaschema"] = "kong/db/schema/metaschema.lua",
    ["kong.db.schema.typedefs"] = "kong/db/schema/typedefs.lua",
    ["kong.db.schema.plugin_loader"] = "kong/db/schema/plugin_loader.lua",
    ["kong.db.schema.topological_sort"] = "kong/db/schema/topological_sort.lua",
    ["kong.db.strategies"] = "kong/db/strategies/init.lua",
    ["kong.db.strategies.connector"] = "kong/db/strategies/connector.lua",
    ["kong.db.strategies.cassandra"] = "kong/db/strategies/cassandra/init.lua",
    ["kong.db.strategies.cassandra.connector"] = "kong/db/strategies/cassandra/connector.lua",
    ["kong.db.strategies.cassandra.tags"] = "kong/db/strategies/cassandra/tags.lua",
    -- [[ XXX EE
    ["kong.db.strategies.cassandra.plugins"] = "kong/db/strategies/cassandra/plugins.lua",
    ["kong.db.strategies.cassandra.consumers"] = "kong/db/strategies/cassandra/consumers.lua",
    ["kong.db.strategies.cassandra.rbac_role_endpoints"] = "kong/db/strategies/cassandra/rbac_role_endpoints.lua",
    ["kong.db.strategies.cassandra.keyring_meta"] = "kong/db/strategies/cassandra/keyring_meta.lua",
    -- EE ]]
    ["kong.db.strategies.postgres"] = "kong/db/strategies/postgres/init.lua",
    ["kong.db.strategies.postgres.connector"] = "kong/db/strategies/postgres/connector.lua",
    ["kong.db.strategies.postgres.tags"] = "kong/db/strategies/postgres/tags.lua",
    -- XXX EE [[
    ["kong.db.strategies.postgres.plugins"] = "kong/db/strategies/postgres/plugins.lua",
    ["kong.db.strategies.postgres.consumers"] = "kong/db/strategies/postgres/consumers.lua",
    -- EE ]]
    ["kong.db.strategies.off"] = "kong/db/strategies/off/init.lua",
    ["kong.db.strategies.off.connector"] = "kong/db/strategies/off/connector.lua",
    ["kong.db.strategies.off.tags"] = "kong/db/strategies/off/tags.lua",
    ["kong.db.strategies.postgres.rbac_role_endpoints"] = "kong/db/strategies/postgres/rbac_role_endpoints.lua",
    ["kong.db.strategies.postgres.keyring_meta"] = "kong/db/strategies/postgres/keyring_meta.lua",

    ["kong.db.migrations.state"] = "kong/db/migrations/state.lua",
    ["kong.db.migrations.helpers"] = "kong/db/migrations/helpers.lua",
    ["kong.db.migrations.core"] = "kong/db/migrations/core/init.lua",
    ["kong.db.migrations.core.000_base"] = "kong/db/migrations/core/000_base.lua",
    ["kong.db.migrations.core.003_100_to_110"] = "kong/db/migrations/core/003_100_to_110.lua",
    ["kong.db.migrations.core.004_110_to_120"] = "kong/db/migrations/core/004_110_to_120.lua",
    ["kong.db.migrations.core.005_120_to_130"] = "kong/db/migrations/core/005_120_to_130.lua",
    ["kong.db.migrations.core.006_130_to_140"] = "kong/db/migrations/core/006_130_to_140.lua",
    ["kong.db.migrations.core.007_140_to_150"] = "kong/db/migrations/core/007_140_to_150.lua",
    ["kong.db.migrations.core.008_150_to_200"] = "kong/db/migrations/core/008_150_to_200.lua",

    ["kong.pdk"] = "kong/pdk/init.lua",
    ["kong.pdk.private.checks"] = "kong/pdk/private/checks.lua",
    ["kong.pdk.private.phases"] = "kong/pdk/private/phases.lua",
    ["kong.pdk.client"] = "kong/pdk/client.lua",
    ["kong.pdk.client.tls"] = "kong/pdk/client/tls.lua",
    ["kong.pdk.ctx"] = "kong/pdk/ctx.lua",
    ["kong.pdk.ip"] = "kong/pdk/ip.lua",
    ["kong.pdk.log"] = "kong/pdk/log.lua",
    ["kong.pdk.service"] = "kong/pdk/service.lua",
    ["kong.pdk.service.request"] = "kong/pdk/service/request.lua",
    ["kong.pdk.service.response"] = "kong/pdk/service/response.lua",
    ["kong.pdk.router"] = "kong/pdk/router.lua",
    ["kong.pdk.request"] = "kong/pdk/request.lua",
    ["kong.pdk.response"] = "kong/pdk/response.lua",
    ["kong.pdk.table"] = "kong/pdk/table.lua",
    ["kong.pdk.node"] = "kong/pdk/node.lua",
    ["kong.pdk.nginx"] = "kong/pdk/nginx.lua",

    ["kong.keyring"] = "kong/keyring/init.lua",
    ["kong.keyring.startup"] = "kong/keyring/startup.lua",
    ["kong.keyring.utils"] = "kong/keyring/utils.lua",
    ["kong.keyring.strategies.cluster"] = "kong/keyring/strategies/cluster.lua",
    ["kong.keyring.strategies.vault"] = "kong/keyring/strategies/vault.lua",

    ["kong.plugins.base_plugin"] = "kong/plugins/base_plugin.lua",

    ["kong.plugins.basic-auth.migrations"] = "kong/plugins/basic-auth/migrations/init.lua",
    ["kong.plugins.basic-auth.migrations.000_base_basic_auth"] = "kong/plugins/basic-auth/migrations/000_base_basic_auth.lua",
    ["kong.plugins.basic-auth.migrations.002_130_to_140"] = "kong/plugins/basic-auth/migrations/002_130_to_140.lua",
    ["kong.plugins.basic-auth.crypto"] = "kong/plugins/basic-auth/crypto.lua",
    ["kong.plugins.basic-auth.handler"] = "kong/plugins/basic-auth/handler.lua",
    ["kong.plugins.basic-auth.access"] = "kong/plugins/basic-auth/access.lua",
    ["kong.plugins.basic-auth.schema"] = "kong/plugins/basic-auth/schema.lua",
    ["kong.plugins.basic-auth.api"] = "kong/plugins/basic-auth/api.lua",
    ["kong.plugins.basic-auth.daos"] = "kong/plugins/basic-auth/daos.lua",

    ["kong.plugins.key-auth.migrations"] = "kong/plugins/key-auth/migrations/init.lua",
    ["kong.plugins.key-auth.migrations.000_base_key_auth"] = "kong/plugins/key-auth/migrations/000_base_key_auth.lua",
    ["kong.plugins.key-auth.migrations.002_130_to_140"] = "kong/plugins/key-auth/migrations/002_130_to_140.lua",
    ["kong.plugins.key-auth.handler"] = "kong/plugins/key-auth/handler.lua",
    ["kong.plugins.key-auth.schema"] = "kong/plugins/key-auth/schema.lua",
    ["kong.plugins.key-auth.daos"] = "kong/plugins/key-auth/daos.lua",

    ["kong.plugins.oauth2.migrations"] = "kong/plugins/oauth2/migrations/init.lua",
    ["kong.plugins.oauth2.migrations.000_base_oauth2"] = "kong/plugins/oauth2/migrations/000_base_oauth2.lua",
    ["kong.plugins.oauth2.migrations.003_130_to_140"] = "kong/plugins/oauth2/migrations/003_130_to_140.lua",
    ["kong.plugins.oauth2.handler"] = "kong/plugins/oauth2/handler.lua",
    ["kong.plugins.oauth2.access"] = "kong/plugins/oauth2/access.lua",
    ["kong.plugins.oauth2.schema"] = "kong/plugins/oauth2/schema.lua",
    ["kong.plugins.oauth2.daos"] = "kong/plugins/oauth2/daos.lua",


    ["kong.plugins.log-serializers.basic"] = "kong/plugins/log-serializers/basic.lua",

    ["kong.plugins.tcp-log.handler"] = "kong/plugins/tcp-log/handler.lua",
    ["kong.plugins.tcp-log.schema"] = "kong/plugins/tcp-log/schema.lua",

    ["kong.plugins.udp-log.handler"] = "kong/plugins/udp-log/handler.lua",
    ["kong.plugins.udp-log.schema"] = "kong/plugins/udp-log/schema.lua",

    ["kong.plugins.http-log.handler"] = "kong/plugins/http-log/handler.lua",
    ["kong.plugins.http-log.schema"] = "kong/plugins/http-log/schema.lua",

    ["kong.plugins.file-log.handler"] = "kong/plugins/file-log/handler.lua",
    ["kong.plugins.file-log.schema"] = "kong/plugins/file-log/schema.lua",

    ["kong.plugins.rate-limiting.migrations"] = "kong/plugins/rate-limiting/migrations/init.lua",
    ["kong.plugins.rate-limiting.migrations.000_base_rate_limiting"] = "kong/plugins/rate-limiting/migrations/000_base_rate_limiting.lua",
    ["kong.plugins.rate-limiting.migrations.003_10_to_112"] = "kong/plugins/rate-limiting/migrations/003_10_to_112.lua",
    ["kong.plugins.rate-limiting.handler"] = "kong/plugins/rate-limiting/handler.lua",
    ["kong.plugins.rate-limiting.schema"] = "kong/plugins/rate-limiting/schema.lua",
    ["kong.plugins.rate-limiting.daos"] = "kong/plugins/rate-limiting/daos.lua",
    ["kong.plugins.rate-limiting.policies"] = "kong/plugins/rate-limiting/policies/init.lua",
    ["kong.plugins.rate-limiting.policies.cluster"] = "kong/plugins/rate-limiting/policies/cluster.lua",

    ["kong.plugins.response-ratelimiting.migrations"] = "kong/plugins/response-ratelimiting/migrations/init.lua",
    ["kong.plugins.response-ratelimiting.migrations.000_base_response_rate_limiting"] = "kong/plugins/response-ratelimiting/migrations/000_base_response_rate_limiting.lua",
    ["kong.plugins.response-ratelimiting.handler"] = "kong/plugins/response-ratelimiting/handler.lua",
    ["kong.plugins.response-ratelimiting.access"] = "kong/plugins/response-ratelimiting/access.lua",
    ["kong.plugins.response-ratelimiting.header_filter"] = "kong/plugins/response-ratelimiting/header_filter.lua",
    ["kong.plugins.response-ratelimiting.log"] = "kong/plugins/response-ratelimiting/log.lua",
    ["kong.plugins.response-ratelimiting.schema"] = "kong/plugins/response-ratelimiting/schema.lua",
    ["kong.plugins.response-ratelimiting.daos"] = "kong/plugins/response-ratelimiting/daos.lua",
    ["kong.plugins.response-ratelimiting.policies"] = "kong/plugins/response-ratelimiting/policies/init.lua",
    ["kong.plugins.response-ratelimiting.policies.cluster"] = "kong/plugins/response-ratelimiting/policies/cluster.lua",

    ["kong.plugins.request-size-limiting.handler"] = "kong/plugins/request-size-limiting/handler.lua",
    ["kong.plugins.request-size-limiting.schema"] = "kong/plugins/request-size-limiting/schema.lua",

    ["kong.plugins.response-transformer.handler"] = "kong/plugins/response-transformer/handler.lua",
    ["kong.plugins.response-transformer.body_transformer"] = "kong/plugins/response-transformer/body_transformer.lua",
    ["kong.plugins.response-transformer.header_transformer"] = "kong/plugins/response-transformer/header_transformer.lua",
    ["kong.plugins.response-transformer.schema"] = "kong/plugins/response-transformer/schema.lua",
    ["kong.plugins.response-transformer.feature_flags.limit_body"] = "kong/plugins/response-transformer/feature_flags/limit_body.lua",

    ["kong.plugins.cors.handler"] = "kong/plugins/cors/handler.lua",
    ["kong.plugins.cors.schema"] = "kong/plugins/cors/schema.lua",

    ["kong.plugins.ip-restriction.handler"] = "kong/plugins/ip-restriction/handler.lua",
    ["kong.plugins.ip-restriction.schema"] = "kong/plugins/ip-restriction/schema.lua",

    ["kong.plugins.acl.migrations"] = "kong/plugins/acl/migrations/init.lua",
    ["kong.plugins.acl.migrations.000_base_acl"] = "kong/plugins/acl/migrations/000_base_acl.lua",
    ["kong.plugins.acl.migrations.002_130_to_140"] = "kong/plugins/acl/migrations/002_130_to_140.lua",
    ["kong.plugins.acl.handler"] = "kong/plugins/acl/handler.lua",
    ["kong.plugins.acl.schema"] = "kong/plugins/acl/schema.lua",
    ["kong.plugins.acl.daos"] = "kong/plugins/acl/daos.lua",
    ["kong.plugins.acl.groups"] = "kong/plugins/acl/groups.lua",
    ["kong.plugins.acl.acls"] = "kong/plugins/acl/acls.lua",
    ["kong.plugins.acl.api"] = "kong/plugins/acl/api.lua",

    ["kong.plugins.correlation-id.handler"] = "kong/plugins/correlation-id/handler.lua",
    ["kong.plugins.correlation-id.schema"] = "kong/plugins/correlation-id/schema.lua",

    ["kong.plugins.jwt.migrations"] = "kong/plugins/jwt/migrations/init.lua",
    ["kong.plugins.jwt.migrations.000_base_jwt"] = "kong/plugins/jwt/migrations/000_base_jwt.lua",
    ["kong.plugins.jwt.migrations.002_130_to_140"] = "kong/plugins/jwt/migrations/002_130_to_140.lua",
    ["kong.plugins.jwt.handler"] = "kong/plugins/jwt/handler.lua",
    ["kong.plugins.jwt.schema"] = "kong/plugins/jwt/schema.lua",
    ["kong.plugins.jwt.daos"] = "kong/plugins/jwt/daos.lua",
    ["kong.plugins.jwt.jwt_parser"] = "kong/plugins/jwt/jwt_parser.lua",
    ["kong.plugins.jwt.asn_sequence"] = "kong/plugins/jwt/asn_sequence.lua",

    ["kong.plugins.hmac-auth.migrations"] = "kong/plugins/hmac-auth/migrations/init.lua",
    ["kong.plugins.hmac-auth.migrations.000_base_hmac_auth"] = "kong/plugins/hmac-auth/migrations/000_base_hmac_auth.lua",
    ["kong.plugins.hmac-auth.migrations.002_130_to_140"] = "kong/plugins/hmac-auth/migrations/002_130_to_140.lua",
    ["kong.plugins.hmac-auth.handler"] = "kong/plugins/hmac-auth/handler.lua",
    ["kong.plugins.hmac-auth.access"] = "kong/plugins/hmac-auth/access.lua",
    ["kong.plugins.hmac-auth.schema"] = "kong/plugins/hmac-auth/schema.lua",
    ["kong.plugins.hmac-auth.daos"] = "kong/plugins/hmac-auth/daos.lua",

    ["kong.plugins.ldap-auth.handler"] = "kong/plugins/ldap-auth/handler.lua",
    ["kong.plugins.ldap-auth.access"] = "kong/plugins/ldap-auth/access.lua",
    ["kong.plugins.ldap-auth.schema"] = "kong/plugins/ldap-auth/schema.lua",
    ["kong.plugins.ldap-auth.ldap"] = "kong/plugins/ldap-auth/ldap.lua",
    ["kong.plugins.ldap-auth.asn1"] = "kong/plugins/ldap-auth/asn1.lua",

    ["kong.plugins.syslog.handler"] = "kong/plugins/syslog/handler.lua",
    ["kong.plugins.syslog.schema"] = "kong/plugins/syslog/schema.lua",

    ["kong.plugins.loggly.handler"] = "kong/plugins/loggly/handler.lua",
    ["kong.plugins.loggly.schema"] = "kong/plugins/loggly/schema.lua",

    ["kong.plugins.datadog.handler"] = "kong/plugins/datadog/handler.lua",
    ["kong.plugins.datadog.schema"] = "kong/plugins/datadog/schema.lua",
    ["kong.plugins.datadog.statsd_logger"] = "kong/plugins/datadog/statsd_logger.lua",

    ["kong.plugins.statsd.handler"] = "kong/plugins/statsd/handler.lua",
    ["kong.plugins.statsd.schema"] = "kong/plugins/statsd/schema.lua",
    ["kong.plugins.statsd.statsd_logger"] = "kong/plugins/statsd/statsd_logger.lua",

    ["kong.plugins.bot-detection.handler"] = "kong/plugins/bot-detection/handler.lua",
    ["kong.plugins.bot-detection.schema"] = "kong/plugins/bot-detection/schema.lua",
    ["kong.plugins.bot-detection.rules"] = "kong/plugins/bot-detection/rules.lua",

    ["kong.plugins.request-termination.handler"] = "kong/plugins/request-termination/handler.lua",
    ["kong.plugins.request-termination.schema"] = "kong/plugins/request-termination/schema.lua",
  }
}
