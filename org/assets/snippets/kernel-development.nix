{ system ? builtins.currentSystem
, configuration ? null
, nixpkgs ? import <nixpkgs> { }
, extraConfigFile ? "config"
, ...
}@args:
with nixpkgs.pkgs;
let
  buildLinuxArgs = builtins.removeAttrs args [
    "system"
    "configuration"
    "nixpkgs"
    "extraConfigFile"
  ];

  makeKernelVersion = src:
    stdenvNoCC.mkDerivation {
      name = "my-kernel-version";
      inherit src;
      phases = "installPhase";
      # make kernelversion also works.
      installPhase = ''
        set -x
        s="$(< "$src/Makefile")"
        get() {
          awk "/^$1 = / "'{print $3}' <<< "$s"
        }
        printf '%s.%s.%s%s' "$(get VERSION)" "$(get PATCHLEVEL)" "$(get SUBLEVEL)" "$(get EXTRAVERSION)" | tee $out
      '';
    };

  getKernelVersion = src: builtins.readFile "${makeKernelVersion src}";

  kernelSrc =
    let
      filter = name: type:
        let baseName = builtins.baseNameOf (builtins.toString name);
        in
        lib.cleanSourceFilter name type && !(baseName == ".ccls-cache"
        || baseName == extraConfigFile || lib.hasSuffix ".nix" baseName);
    in
    lib.cleanSourceWith {
      inherit filter;
      src = ./.;
    };

  kernelVersion = getKernelVersion kernelSrc;

  latestConfigFile = linuxPackages_latest.kernel.configfile;

  defaultConfigFile = (linuxConfig {
    src = kernelSrc;
    version = kernelVersion;
  }).overrideAttrs ({ prePatch ? "", ... }: {
    prePatch = linuxPackages_latest.kernel.prePatch + prePatch;
  });

  # We need to merge some `CONFIG_` to make qemu happy.
  allConfigFiles =
    let
      p = "${builtins.toPath ./.}/${extraConfigFile}";
      extraConfig = lib.optionals (builtins.pathExists p) [
        "${builtins.path {
          name = "extra-kernel-config";
          path = p;
        }}"
      ];
    in
    [ defaultConfigFile latestConfigFile ] ++ extraConfig;

  mergedConfigFile = (stdenv.mkDerivation {
    name = "merged-kernel-config";
    src = kernelSrc;
    phases = "unpackPhase prePatchPhase installPhase";
    prePatchPhase = linuxPackages_latest.kernel.prePatch;
    # make qemu happy with `CONFIG_EXPERIMENTAL=y`.
    installPhase = ''
      set -x
      KCONFIG_CONFIG=$out RUNMAKE=false "$src/scripts/kconfig/merge_config.sh" ${
        builtins.concatStringsSep " " allConfigFiles
      }
      grep -q '^CONFIG_EXPERIMENTAL=' $out && sed -i 's/^CONFIG_EXPERIMENTAL=.*/CONFIG_EXPERIMENTAL=y/' $out || echo 'CONFIG_EXPERIMENTAL=y' >> $out
    '';
  }).overrideAttrs ({ prePatch ? "", ... }: {
    prePatch = linuxPackages_latest.kernel.prePatch + prePatch;
  });

  nixosConfiguration = { config, pkgs, ... }: {
    imports = [ ] ++ lib.optionals (configuration != null) [ configuration ];

    boot.kernelPackages =
      # TODO: Does not work yet.
      # buildLinux {
      #   src = kernelSrc;
      #   version = kernelVersion;
      # };
      linuxPackages_custom {
        src = kernelSrc;
        version = kernelVersion;
        configfile = "${mergedConfigFile}";
      };

    environment = {
      enableDebugInfo = true;
      etc =
        let
          getHome = x: builtins.elemAt (builtins.split ":" x) 10;
          entries = builtins.filter (x: x != "" && x != [ ])
            (builtins.split "\n" (builtins.readFile /etc/passwd));
          homes = builtins.map getHome entries;
          currentFile = "${builtins.toPath ./.}";
          possibleUserHomes =
            builtins.filter (x: lib.hasPrefix x currentFile) homes;
          keyFiles = builtins.filter (x: builtins.pathExists x)
            (builtins.map (x: "${x}/.ssh/authorized_keys") possibleUserHomes);
          keys = builtins.concatStringsSep "\n"
            (builtins.map (x: builtins.readFile x) keyFiles);
        in
        lib.optionalAttrs (keys != "") {
          "ssh/authorized_keys.d/root" = {
            text = builtins.trace "Added the following keys for ssh access.\n${keys}\n" keys;
            mode = "0444";
          };
        };
    };

    # Generate with mkpasswd -m sha-512 pwFuerRoot
    users.users.root.initialHashedPassword = "$6$3zAawH1uhs$dlOiT.ckvpbBQ21tax1J4RI1EGm/1j1HDBoe5u1jy.gHw0QXCKA1dVEwKF.LD0bvzqBu4co.eaZCIK7b2E17k1";

    services.sshd.enable = true;
  };

  nixos = import (nixpkgs.path + "/nixos/") {
    inherit system;
    configuration = nixosConfiguration;
  };
in
nixos // {
  inherit allConfigFiles defaultConfigFile latestConfigFile mergedConfigFile
    kernelSrc;
}
