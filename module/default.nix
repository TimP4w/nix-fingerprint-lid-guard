{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.services.fprintd.lid-guard;

  lidScript = pkgs.writeShellScript "pam-fprint-lid-guard" ''
    read -r state < /proc/acpi/button/lid/${cfg.lidPath}/state 2>/dev/null || exit 1
    case "$state" in
      *closed*) exit 0 ;;
      *)        exit 1 ;;
    esac
  '';

  lidGuardRule = {
    # Exit 0 (success) when lid is closed → PAM jumps over pam_fprintd.so.
    # Exit 1 (failure) → result ignored, falls through to fingerprint normally.
    order = 11390; # slightly less than pam_fprintd.so which is assigned to 11400 in nixpkgs
    control = "[success=1 default=ignore]";
    modulePath = "${pkgs.pam}/lib/security/pam_exec.so";
    args = [
      "quiet"
      "${lidScript}"
    ];
  };
in
{
  options.services.fprintd.lid-guard = {
    enable = mkEnableOption "fingerprint auth with lid-open guard";
    lidPath = mkOption {
      type = types.str;
      default = "LID";
      description = "ACPI lid device name under /proc/acpi/button/lid/. Common values: LID, LID0, LID1.";
    };
    pamServices = mkOption {
      type = types.listOf types.str;
      default = [
        "chfn"
        "chpasswd"
        "chsh"
        "cups"
        "groupadd"
        "groupdel"
        "groupmems"
        "groupmod"
        "passwd"
        "polkit-1"
        "runuser"
        "runuser-l"
        "su"
        "sudo"
        "systemd-run0"
        "systemd-user"
        "useradd"
        "userdel"
        "usermod"
        "vlock"
        "xlock"
      ];
      description = "PAM services to inject the lid-guard rule into.";
    };
    extraPamServices = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional PAM services to inject the lid-guard rule into, merged with pamServices.";
    };
  };

  config = mkIf cfg.enable {
    security.pam.services = mkMerge (
      map (name: { ${name}.rules.auth.lid-guard = lidGuardRule; }) (
        cfg.pamServices ++ cfg.extraPamServices
      )
    );
  };
}
