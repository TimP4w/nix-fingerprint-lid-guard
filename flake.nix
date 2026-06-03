{
  description = "PAM: skip fingerprint auth when laptop lid is closed";

  outputs =
    { self, ... }:
    {
      nixosModules.fingerprint = import ./module;
      nixosModules.default = self.nixosModules.fingerprint;
    };
}
