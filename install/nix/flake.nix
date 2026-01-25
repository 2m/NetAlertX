{
  description = "NixOS module for NetAlertX network monitoring";

  outputs = { self }: {
    nixosModules.default = { config, lib, ... }:
      with lib;
      let
        cfg = config.services.netalertx;
      in {
        options.services.netalertx = {
          enable = mkEnableOption "netalertx";
          port = mkOption {
            type = types.port;
            default = 20211;
            description = "Port to listen on for web gui";
          };
          graphqlPort = mkOption {
            type = types.port;
            default = 20212;
            description = "Port to listen on for GraphQL requests";
          };
          user = mkOption {
            type = types.str;
            default = "netalertx";
            description = "User to run the app";
          };
          group = mkOption {
            type = types.str;
            default = "netalertx";
            description = "Group to run the app";
          };
          imageTag = mkOption {
            type = types.str;
            default = "latest";
            description = "Image tag to run";
          };
        };
        config = mkIf cfg.enable {
          users.users."${cfg.user}" = {
            isSystemUser = true;
            group = cfg.group;
            uid = 20211;
          };
          users.groups."${cfg.group}" = {
            gid = 20211;
          };
          systemd.tmpfiles.rules = [
            "d /var/lib/netalertx 0755 ${cfg.user} ${cfg.group} -"
            "d /var/lib/netalertx/db 0755 ${cfg.user} ${cfg.group} -"
            "d /var/lib/netalertx/config 0755 ${cfg.user} ${cfg.group} -"
          ];
          virtualisation.oci-containers = {
            containers = {
              netalertx = {
                image = "ghcr.io/jokob-sk/netalertx:${imageTag}";
                autoStart = true;
                extraOptions = [
                  "--network=host"
                  "--cap-drop=ALL"
                  "--cap-add=NET_ADMIN"
                  "--cap-add=NET_RAW"
                  "--cap-add=NET_BIND_SERVICE"
                  "--cap-add=CHOWN"
                  "--cap-add=SETUID"
                  "--cap-add=SETGID"
                  "--read-only"
                  "--tmpfs=/tmp"
                ];
                volumes = [
                  "/var/lib/netalertx:/data"
                  "/etc/localtime:/etc/localtime:ro"
                ];
                environment = {
                  LISTEN_ADDR = "0.0.0.0";
                  PORT = "${toString cfg.port}";
                  GRAPHQL_PORT = "${toString cfg.graphqlPort}";
                  ALWAYS_FRESH_INSTALL = "false";
                  NETALERTX_DEBUG = "0";
                };
              };
            };
          };
        };
      };
  };
}
