{ lib, pkgs, ... }:

{
  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.6.33"
  ];

  services.ollama = {
    enable = true;
    package = pkgs.ollama-vulkan;
    user = "ollama";
    group = "ollama";
    host = "127.0.0.1";
    port = 11434;
    loadModels = [
      "qwen3.5:2b"
      "qwen3.5:4b"
      "qwen3.5:9b"
    ];
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "32768";
      OLLAMA_KEEP_ALIVE = "5m";
      OLLAMA_MAX_LOADED_MODELS = "1";
      OLLAMA_NUM_PARALLEL = "1";
    };
  };

  systemd.services.ollama.serviceConfig.DynamicUser = lib.mkForce false;
  systemd.tmpfiles.rules = [ "d /var/lib/ollama/models 0755 ollama ollama - -" ];

  virtualisation.podman.dockerCompat = true;

  environment.persistence."/persist".directories = [ "/var/lib/ollama" ];
}
