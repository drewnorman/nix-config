# Secrets Bootstrap

This host expects its declarative secrets in `secrets/x1c-g9.yaml` once
`sops-nix` is enabled. The file should have two SOPS recipients:

- the machine age recipient for unattended system activation
- the YubiKey OpenPGP encryption subkey for human editing, recovery, and
  first-time bootstrap before the machine age key is available

## Age Recipient

The configuration uses a persisted native age key at
`/persist/etc/sops/age/keys.txt` as the machine decryption identity. This is
the only key used by `sops-nix` during non-interactive activation. It does not
need a PIN, touch, GPG agent, or logged-in user session.

This key is separate from the OpenSSH host key at
`/persist/etc/ssh/ssh_host_ed25519_key`. The SSH host key is only the SSH server
identity and is not a SOPS recipient.

Generate it once with:

```sh
sudo install -d -m 700 /persist/etc/sops /persist/etc/sops/age
sudo age-keygen -o /persist/etc/sops/age/keys.txt
sudo chmod 600 /persist/etc/sops/age/keys.txt
```

Show the public recipient with:

```sh
sudo age-keygen -y /persist/etc/sops/age/keys.txt
```

## YubiKey OpenPGP Recipient

Use the YubiKey OpenPGP encryption subkey as the human SOPS recipient. First
inspect the card. Do not reset the OpenPGP app unless it is empty or you
intentionally want to wipe existing OpenPGP data:

```sh
ykman openpgp info
gpg --card-status
```

If the OpenPGP app already has an encryption-capable key, reuse it and record
the encryption subkey fingerprint:

```sh
gpg --list-keys --with-subkey-fingerprint --keyid-format long
```

If the OpenPGP app is not configured, initialize it interactively:

```sh
gpg --card-edit
```

In `gpg --card-edit`, run:

```text
admin
passwd
name
lang
sex
login
generate
quit
```

Prefer modern ECC choices when prompted, such as `cv25519` for encryption and
`ed25519` for primary/signing keys where supported.

After keys exist, set touch policy:

```sh
ykman openpgp keys set-touch enc on
ykman openpgp keys set-touch sig on
ykman openpgp keys set-touch aut on
```

Export the public key for backup/import on other machines:

```sh
gpg --armor --export YOUR_KEY_FINGERPRINT > yubikey-openpgp-public.asc
```

Then add the encryption subkey fingerprint to `.sops.yaml` as the `pgp`
recipient for `secrets/x1c-g9.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/x1c-g9\.yaml$
    age: age1ucfachl45fkl66fpmp5q6a406j9kwe6fc5fcuq46tphzllpt043q53pzav
    pgp: "YOUR_YUBIKEY_OPENPGP_ENCRYPTION_SUBKEY_FINGERPRINT"
```

Update the encrypted file keys after adding the real fingerprint:

```sh
sops updatekeys secrets/x1c-g9.yaml
```

## Secret File Shape

Create `secrets/x1c-g9.yaml` with these keys before encrypting it with `sops`:

```yaml
drew-password-hash: "$y$..."
pam-u2f-keys: |
  drew:<pamu2fcfg output>
```

Generate the values with:

```sh
mkpasswd -m yescrypt
pamu2fcfg -u drew
```

Then encrypt the file. The repository `.sops.yaml` selects the host recipient:

```sh
sops --encrypt --in-place secrets/x1c-g9.yaml
```

Re-encrypt/update recipients whenever `.sops.yaml` changes:

```sh
sops updatekeys secrets/x1c-g9.yaml
```

## Verification

Verify smartcard visibility:

```sh
ykman openpgp info
gpg --card-status
```

Verify user editing/recovery access through the YubiKey recipient:

```sh
sops --decrypt secrets/x1c-g9.yaml >/dev/null
```

Verify root/system activation access through the machine age key:

```sh
sudo SOPS_AGE_KEY_FILE=/persist/etc/sops/age/keys.txt sops --decrypt secrets/x1c-g9.yaml >/dev/null
```
