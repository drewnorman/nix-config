{
  config,
  lib,
  pkgs,
  ...
}:

let
  secretsFile = ../../secrets/x1c-g9.yaml;
  hasSecretsFile = builtins.pathExists secretsFile;
  persistedHostSshKey = "/persist/etc/ssh/ssh_host_ed25519_key";
  sopsAgeKeyFile = "/persist/etc/sops/age/keys.txt";
in
{
  boot.initrd.luks.devices.crypted.crypttabExtraOpts = [ "fido2-device=auto" ];

  services.openssh.hostKeys = [
    {
      path = persistedHostSshKey;
      type = "ed25519";
    }
  ];

  security.pam.u2f = {
    enable = hasSecretsFile;
    control = "required";
    settings = {
      authfile = if hasSecretsFile then config.sops.secrets.pam-u2f-keys.path else null;
      cue = true;
    };
  };

  security.pam.services.sudo.u2f = {
    enable = hasSecretsFile;
    control = "sufficient";
  };
  security.pam.services.login.u2f = {
    enable = hasSecretsFile;
    control = "sufficient";
  };
  security.pam.services.swaylock.u2f = {
    enable = hasSecretsFile;
    control = "sufficient";
  };
  security.pam.services.swaylock-effects.u2f = {
    enable = hasSecretsFile;
    control = "sufficient";
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
  };

  services.pcscd.enable = true;

  sops = lib.mkIf hasSecretsFile {
    defaultSopsFile = secretsFile;
    defaultSopsFormat = "yaml";

    age.keyFile = sopsAgeKeyFile;

    secrets = {
      drew-password-hash = {
        neededForUsers = true;
      };

      pam-u2f-keys = {
        owner = "root";
        group = "root";
        mode = "0400";
      };
    };
  };

  users.users.drew.hashedPasswordFile = lib.mkIf hasSecretsFile (
    lib.mkForce config.sops.secrets.drew-password-hash.path
  );

  environment.systemPackages = with pkgs; [
    age
    gnupg
    pam_u2f
    pcsc-tools
    pinentry-curses
    yubikey-manager
  ];

  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  warnings = lib.optionals (!hasSecretsFile) [
    "Missing ${secretsFile}; leaving the bootstrap password hash in place and skipping declarative PAM U2F mappings until the sops file is created."
  ];
}
