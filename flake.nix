{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      libraries = with pkgs; [
        pkg-config
        stdenv.cc.cc.lib

        (pkgs.python312.withPackages (python-pkgs:
          with python-pkgs; [
            pip
          ]))
        libmysqlclient
        mariadb
        ghostscript
      ];
    in {
      devShell = pkgs.mkShell {
        buildInputs = libraries;

        shellHook = ''
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
          export XDG_DATA_DIRS=\
          ${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:\
          ${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:\
          $XDG_DATA_DIRS
          [[ ! -d .venv ]] && python3.12 -m venv .venv
          source .venv/bin/activate
        '';

        XDG_DATA_DIRS = let
          base = pkgs.lib.concatMapStringsSep ":" (x: "${x}/share") [
            pkgs.adwaita-icon-theme
            pkgs.shared-mime-info
          ];
          gsettings_schema = pkgs.lib.concatMapStringsSep ":" (x: "${x}/share/gsettings-schemas/${x.name}") [
            pkgs.glib.dev
            pkgs.gsettings-desktop-schemas
            pkgs.gtk3
          ];
        in "${base}:${gsettings_schema}";
      };
    });
}
