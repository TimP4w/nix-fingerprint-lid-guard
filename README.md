# nix-fingerprint-lid-guard

Skip PAM fingerprint authentication when laptop lid is closed.

When closing the lid of the laptop and `fprintd` is enabled, PAM modules will still present the "scan your fingerprint" message that must be cancelled, or the timeout awaited, before being able to input the password.

It's quite an annoying behaviour to have, when connected to an external display.

This module inserts a PAM route that detects the lid state and skips `pam_fprintd` presenting the password prompt directly.

## How it works

A small shell script reads `/proc/acpi/button/lid/<lidPath>/state`. If the lid is closed, it exits 0, causing PAM to skip the next rule (the fprintd rule). If the lid is open, it exits 1 and PAM falls through to fingerprint auth as normal.

The rule is injected into every PAM service that `services.fprintd.enable` touches.

## Installation

Add the flake as an input and import the module:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    fingerprint-lid-guard = {
      url = "github:timp4w/nix-fingerprint-lid-guard";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, fingerprint-lid-guard, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      modules = [
        fingerprint-lid-guard.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

Then enable it in your NixOS configuration:

```nix
services.fprintd.lid-guard = {
  enable = true;
  # lidPath = "LID0"; # override if your ACPI device has a different name
  # pamServices = [...]; # override if you want to choose the PAM services selectively
  extraPamServices = [
    "gdm" # or any other PAM services not in the default list
  ];
};
```

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `services.fprintd.lid-guard.enable` | bool | `false` | Enable the module |
| `services.fprintd.lid-guard.lidPath` | string | `"LID"` | ACPI lid device name under `/proc/acpi/button/lid/`. Check `ls /proc/acpi/button/lid/` if `"LID"` doesn't work. |
| `services.fprintd.lid-guard.pamServices` | list of string | see module | Names of PAM services (files under `/etc/pam.d`) to inject the lid-check rule into. Only add services that have a password fallback: services like `gdm-fingerprint` require fingerprint, so skipping it would bypass auth entirely. |
| `services.fprintd.lid-guard.extraPamServices` | list of string | `[]` | Additional PAM services to inject the lid-check rule into, merged with the default `pamServices` list. Use this to add services like `"gdm"` or `"login"` without overriding the defaults. |

## Acknowledgment

Inspired by this blog post on [heywoodlg.io](https://heywoodlh.io/disable-fprint-clamshell-laptop/).

The original author also proposed a PR here [NixOS/nixpkgs#342676](https://github.com/NixOS/nixpkgs/pull/342676), however it wasn't merged, hence this flake to add the same functionality, with some configurable options.
