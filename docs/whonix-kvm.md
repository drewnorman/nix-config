# Whonix on KVM

This host runs Whonix as two unprivileged libvirt VMs:

```text
internet -> Whonix-Gateway (Tor) -> loopback UDP link -> Whonix-Workstation
```

The Gateway's external interface uses `passt`. The Workstation has no external
interface and can reach the network only through the Gateway. The supplied
Whonix XML also disables clipboard sharing, file transfer, 3D acceleration, and
microphone input. Do not add shared folders, USB redirection, a microphone,
bridged networking, or another network interface.

The VM definitions, libvirt metadata, and images are persisted across the
host's root rollback in `~/.config/libvirt`, `~/.local/share/libvirt`, and
`~/.local/share/images`. They are encrypted at rest by the host's existing LUKS
volume.

Whonix's KVM documentation is community-supported. Read the upstream
[KVM guide](https://www.whonix.org/wiki/KVM),
[limitations](https://www.whonix.org/wiki/Whonix_and_Tor_Limitations), and
[post-installation advice](https://www.whonix.org/wiki/Post_Install_Advice)
before relying on this setup.

## Enable the host

Apply the NixOS configuration:

```sh
just switch
```

Log out and back in after the first rebuild so the new `kvm` and `libvirtd`
group memberships take effect. Confirm KVM and the user libvirt connection:

```sh
test -r /dev/kvm && test -w /dev/kvm
virsh -c qemu:///session list --all
```

Use `qemu:///session` throughout. The system libvirt connection shown by some
tools is not used for Whonix, and the host does not need a libvirt bridge or a
firewall exception.

## Download and verify

The current stable release when this guide was written is `18.2.1.9`. Before
installing, compare `whonix_version` below with the stable LXQt version on the
[official KVM download page](https://www.whonix.org/wiki/KVM#Download_Whonix).
Update the value if a newer stable version is listed.

Use a new staging directory so filename globs cannot select an older download:

```sh
install -d -m 700 ~/downloads/whonix-import
cd ~/downloads/whonix-import

whonix_version=18.2.1.9
whonix_archive="Whonix-LXQt-${whonix_version}.Intel_AMD64.qcow2.libvirt.xz"
whonix_url="https://www.whonix.org/download/libvirt/${whonix_version}"

curl --fail --location --remote-name "${whonix_url}/${whonix_archive}"
curl --fail --location --remote-name "${whonix_url}/${whonix_archive}.sha512sums"
curl --fail --location --remote-name "${whonix_url}/${whonix_archive}.sha512sums.sig"
curl --fail --location --output derivative.pub https://www.whonix.org/keys/derivative.pub
```

Verify the signature on the checksum file, then verify the archive itself:

```sh
signify -V -p derivative.pub -m "${whonix_archive}.sha512sums"
sha512sum -c "${whonix_archive}.sha512sums"
```

Both commands must succeed. Do not continue after a signature or checksum
failure. See Whonix's [image verification guide](https://www.whonix.org/wiki/Verify_the_images)
for key-verification considerations and alternative OpenPGP instructions.

## Extract and import

GNU tar's `-S` option preserves the qcow2 sparse files:

```sh
tar -xSvf "$whonix_archive"
```

Read the extracted binary license. Continue only if you accept it:

```sh
more WHONIX_BINARY_LICENSE_AGREEMENT
touch WHONIX_BINARY_LICENSE_AGREEMENT_accepted
```

Do not edit the supplied XML. Define both machines in the user session:

```sh
virsh -c qemu:///session define Whonix-Gateway*.xml
virsh -c qemu:///session define Whonix-Workstation*.xml
```

Install the images without replacing an existing Whonix installation:

```sh
install -d -m 700 ~/.local/share/images
test ! -e ~/.local/share/images/Whonix-Gateway.qcow2
test ! -e ~/.local/share/images/Whonix-Workstation.qcow2
mv Whonix-Gateway*.qcow2 ~/.local/share/images/Whonix-Gateway.qcow2
mv Whonix-Workstation*.qcow2 ~/.local/share/images/Whonix-Workstation.qcow2
```

Inspect the effective configuration before first boot:

```sh
virsh -c qemu:///session dumpxml Whonix-Gateway | rg 'interface|backend|clipboard|filetransfer|filesystem|redirdev|codec'
virsh -c qemu:///session dumpxml Whonix-Workstation | rg 'interface|backend|clipboard|filetransfer|filesystem|redirdev|codec'
```

The Gateway must have one `type='user'` interface with a `type='passt'`
backend and one `type='udp'` interface. The Workstation must have only one
`type='udp'` interface. Both displays must show clipboard and file transfer as
disabled; neither VM should contain a filesystem, USB redirection device, or
microphone codec.

## Operate Whonix

Start the Gateway first, followed by the Workstation:

```sh
virsh -c qemu:///session start Whonix-Gateway
virsh -c qemu:///session start Whonix-Workstation
virt-manager -c qemu:///session
```

On first boot, complete Whonix's setup and updates. Run `systemcheck` in the
Workstation and confirm that its browser reports a Tor exit address. Never use
the host browser as though it were routed through Whonix; only applications in
the Workstation use the Gateway.

Shut down the Workstation before the Gateway:

```sh
virsh -c qemu:///session shutdown Whonix-Workstation
virsh -c qemu:///session shutdown Whonix-Gateway
```

The VMs are deliberately not configured to autostart. Before a host reboot or
shutdown, confirm both have stopped with:

```sh
virsh -c qemu:///session list
```

For upgrades, follow the current upstream guidance. Apply normal package
updates inside each guest. When Whonix recommends replacing the images, export
only necessary data through an explicit, temporary mechanism, shut down both
VMs, and follow the upstream cleanup and import procedure. Do not overwrite the
existing qcow2 files in place.

Whonix does not protect against a compromised NixOS host: the host controls the
hypervisor and can observe VM activity. Qubes-Whonix is the stronger choice if
host compromise is part of the threat model.
