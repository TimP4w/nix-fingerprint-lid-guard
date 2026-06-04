{
  description = "PAM: skip fingerprint auth when laptop lid is closed";

  outputs =
    { self, ... }:
    {
      nixosModules.fingerprint = ./module;
      nixosModules.default = self.nixosModules.fingerprint;
    };
}
