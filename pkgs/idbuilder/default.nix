{ lib, pkgs, stdenv, fetchurl, runCommand, rustPlatform, makeDesktopItem
, yarn2nix-moretea }:

let
  overlay_pkgs = pkgs.appendOverlays [
    (import (fetchTarball
      "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];

  appBinName = "idbuilder";
  appVersion = "6.0.1";
  appComment = "More than an identifier building tool";

  desktopItem = makeDesktopItem rec {
    name = appBinName;

    desktopName = "IDBuilder";
    genericName = desktopName;
    comment = appComment;

    exec = name;
    icon = name;

    type = "Application";
  };

  src_ruster = builtins.fetchTarball {
    url = "https://github.com/Thaumy/ruster/archive/refs/tags/v0.1.0.tar.gz";
    sha256 = "03p6r0lviasd1c5cq1xvhhafhs5r9fgzym5mfi802y9rwx7xjmpv";
  };

  src_palaflake = builtins.fetchTarball {
    url =
      "https://github.com/Thaumy/palaflake/archive/refs/tags/v1.1.0-dev-rs.tar.gz";
    sha256 = "0i82hijl4hmn4b47dl8xxzza9z7z5g7nfck99yqd5am0piwvz2gp";
  };

  src_idbuilder = builtins.fetchTarball {
    url = "https://github.com/Thaumy/IDBuilder/archive/refs/tags/v6.0.1.tar.gz";
    sha256 = "0sy5qg1mbd3q39dfi3iswx2jd5vr6znvginj6474dylhwhbn1ksk";
  };

  node_modules = yarn2nix-moretea.mkYarnModules rec {
    pname = appBinName;
    version = appVersion;
    name = "${pname}_node_modules_${version}";

    # yarn2nix only support yarn1, so need to place here a v1 lock file
    yarnLock = ./yarn.lock;
    packageJSON = "${src_idbuilder}/package.json";
  };

  inputs = with overlay_pkgs; [
    gtk3
    glib
    dbus
    cairo
    libsoup
    webkitgtk
    openssl_3
    gdk-pixbuf
    pkg-config
    appimagekit

    yarn
    rust-bin.nightly.latest.minimal
  ];

in rustPlatform.buildRustPackage rec {
  pname = appBinName;
  version = appVersion;

  # TODO: here could be simplified
  buildInputs = inputs;
  nativeBuildInputs = inputs;

  src = "${src_idbuilder}/src-tauri";

  cargoLock = { lockFile = "${src}/Cargo.lock"; };

  # TODO: why it failed with 666 permission?
  buildPhase = ''
    cp -r ${src_idbuilder}/* .
    cp -r ${node_modules}/node_modules .
    yarn --offline build

    chmod -R 777 src-tauri

    mkdir -p deps/ruster
    cp -r ${src_ruster}/* deps/ruster
    cp -r ${src_palaflake}/* deps
    mv deps src-tauri

    cd src-tauri
    cargo build --release
  '';

  installPhase = ''
    cd ..

    # bin
    mkdir -p $out/bin
    cp src-tauri/target/release/${appBinName} $out/bin

    # icon & .desktop
    mkdir -p $out/share/icons
    cp public/tauri.svg $out/share/icons/${appBinName}.svg
    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications

    # echo for debug
    echo -e "\nApp was successfully installed in $out\n"
  '';

  meta = {
    description = appComment;
    homepage = "https://github.com/Thaumy/idbuilder";
    license = lib.licenses.mit;
    maintainers = [ "thaumy" ];
    platforms = lib.platforms.linux;
  };
}
