{
  config,
  pkgs,
  ...
}:

let
  sandboxRoot = pkgs.buildEnv {
    name = "openclaw-sandbox-root";
    paths = with pkgs; [
      bashInteractive
      cacert
      coreutils
      curl
      findutils
      gitMinimal
      gnugrep
      gnused
      jq
      python3
      ripgrep
    ];
    pathsToLink = [ "/bin" ];
  };
  sandboxImage = pkgs.dockerTools.buildLayeredImage {
    name = "openclaw-sandbox";
    tag = "bookworm-slim";
    contents = [ sandboxRoot ];
    config = {
      Cmd = [
        "${pkgs.coreutils}/bin/sleep"
        "infinity"
      ];
      Env = [
        "HOME=/tmp"
        "PATH=/bin"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      User = "1000:100";
      WorkingDir = "/workspace";
    };
  };
  openclawConfig = {
    gateway = {
      mode = "local";
      bind = "loopback";
      port = 18789;
      auth = {
        mode = "token";
        token = "\${OPENCLAW_GATEWAY_TOKEN}";
      };
    };

    models = {
      mode = "replace";
      pricing.enabled = false;
      providers.ollama = {
        api = "ollama";
        apiKey = "ollama-local";
        baseUrl = "http://127.0.0.1:11434";
        timeoutSeconds = 300;
        contextWindow = 32768;
        contextTokens = 32768;
        maxTokens = 4096;
        models =
          map
            (model: {
              id = model;
              name = model;
              reasoning = true;
              input = [ "text" ];
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
              contextWindow = 32768;
              contextTokens = 32768;
              maxTokens = 4096;
              params = {
                num_ctx = 32768;
                thinking = false;
                keep_alive = "5m";
              };
            })
            [
              "qwen3.5:2b"
              "qwen3.5:4b"
              "qwen3.5:9b"
            ];
      };
    };

    agents.defaults = {
      model.primary = "ollama/qwen3.5:9b";
      models = {
        "ollama/qwen3.5:2b".alias = "light";
        "ollama/qwen3.5:4b".alias = "fast";
        "ollama/qwen3.5:9b".alias = "quality";
      };
      contextTokens = 32768;
      maxConcurrent = 1;
      subagents = {
        allowAgents = [ ];
        maxConcurrent = 1;
      };
      sandbox = {
        mode = "all";
        scope = "agent";
        backend = "docker";
        workspaceAccess = "none";
        docker = {
          image = "openclaw-sandbox:bookworm-slim";
          network = "none";
          readOnlyRoot = true;
          capDrop = [ "ALL" ];
        };
      };
    };

    skills = {
      allowBundled = [ ];
      load.watch = false;
      workshop = {
        autonomous.enabled = false;
        approvalPolicy = "pending";
      };
    };

    tools = {
      profile = "minimal";
      alsoAllow = [
        "read"
        "memory_get"
        "memory_search"
        "exec"
      ];
      deny = [
        "write"
        "edit"
        "apply_patch"
        "process"
        "browser"
        "canvas"
        "web_search"
        "web_fetch"
        "cron"
        "gateway"
        "nodes"
        "sessions_spawn"
        "subagents"
      ];
      fs.workspaceOnly = true;
      elevated.enabled = false;
      exec = {
        host = "gateway";
        security = "allowlist";
        ask = "always";
        strictInlineEval = true;
        applyPatch.enabled = false;
      };
    };
  };
in
{
  home.packages = [ pkgs.openclaw ];

  home.persistence."/persist".directories = [ ".openclaw" ];

  home.file.".openclaw/openclaw.json".text = builtins.toJSON openclawConfig + "\n";

  home.activation.initializeOpenClaw = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    state_dir="${config.home.homeDirectory}/.openclaw"
    env_file="$state_dir/.env"
    approvals_file="$state_dir/exec-approvals.json"

    run ${pkgs.coreutils}/bin/install -d -m 700 "$state_dir"

    if [ ! -s "$env_file" ]; then
      if [[ -v DRY_RUN ]]; then
        echo "Would generate $env_file"
      else
        token="$(${pkgs.openssl}/bin/openssl rand -hex 32)"
        ${pkgs.coreutils}/bin/printf 'OPENCLAW_GATEWAY_TOKEN=%s\n' "$token" > "$env_file"
      fi
    fi

    if [[ ! -v DRY_RUN ]]; then
      ${pkgs.coreutils}/bin/chmod 600 "$env_file"
      ${pkgs.coreutils}/bin/printf '%s\n' '${
        builtins.toJSON {
          version = 1;
          defaults = {
            security = "allowlist";
            ask = "always";
            askFallback = "deny";
            autoAllowSkills = false;
          };
          agents.main = {
            security = "allowlist";
            ask = "always";
            askFallback = "deny";
            autoAllowSkills = false;
            allowlist = [ ];
          };
        }
      }' > "$approvals_file"
      ${pkgs.coreutils}/bin/chmod 600 "$approvals_file"
    fi
  '';

  systemd.user.services.openclaw-sandbox-image = {
    Unit.Description = "Load the OpenClaw tool sandbox image into rootless Podman";
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.podman}/bin/podman load --input ${sandboxImage}";
    };
  };

  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "OpenClaw local AI gateway";
      Wants = [ "network-online.target" ];
      Requires = [ "openclaw-sandbox-image.service" ];
      After = [
        "network-online.target"
        "openclaw-sandbox-image.service"
      ];
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.openclaw}/bin/openclaw gateway --port 18789";
      EnvironmentFile = "%h/.openclaw/.env";
      Environment = [
        "OPENCLAW_NO_RESPAWN=1"
        "NODE_COMPILE_CACHE=%h/.cache/openclaw/node"
      ];
      Restart = "always";
      RestartSec = 5;
      RestartPreventExitStatus = 78;
      TimeoutStartSec = 30;
      TimeoutStopSec = 30;
      SuccessExitStatus = "0 143";
      OOMPolicy = "continue";
      KillMode = "control-group";
    };
    Install.WantedBy = [ "default.target" ];
  };

}
