{ pkgs, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usb_storage"
        "sd_mod"
      ];
      luks.devices.crypted.device = "/dev/disk/by-uuid/208b84fc-d18e-42a6-9ede-489f50421821";
      services.lvm.enable = true;
    };

    kernelModules = [
      "kvm-intel"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 100;
      "vm.page-cluster" = 0;
    };
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C33D-CFED";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    {
      device = "/dev/vg/nixos-swap";
      priority = 10;
    }
  ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  hardware = {
    acpilight.enable = true;
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    bluetooth.enable = true;
    firmware = with pkgs; [
      sof-firmware
    ];
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };
}
