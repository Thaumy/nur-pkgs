{ lib
, pkgs
, rustPlatform
, fetchFromGitHub
}:

let
  appBinName = "dup-img-finder";
  appVersion = "0.1.0";
  appComment = "Find duplicate images by similarity";

  # rust-overlay = import (builtins.fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz");

  rust-overlay = import (fetchFromGitHub {
    owner = "oxalica";
    repo = "rust-overlay";
    rev = "9ea38d547100edcf0da19aaebbdffa2810585495";
    sha256 = "kwKCfmliHIxKuIjnM95TRcQxM/4AAEIZ+4A9nDJ6cJs=";
  });

  extended-pkgs = pkgs.extend (rust-overlay);

  src = fetchFromGitHub {
    owner = "Thaumy";
    repo = "dup-img-finder";
    rev = "4ce767b8a0c854dc85b5f60515520fab08c27f2e";
    sha256 = "UkFyNw1sJuwPqODLua26V68mBR2kXIO5EqPcMpIWw4E=";
  };

  buildTimeDeps = with extended-pkgs; [
    rust-bin.nightly."2023-05-24".minimal
  ];
in
rustPlatform.buildRustPackage {
  pname = appBinName;
  version = appVersion;

  nativeBuildInputs = buildTimeDeps;

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  buildPhase = ''
    cp -r ${src}/* .
    cargo build -r
  '';

  installPhase = ''
    # bin
    mkdir -p $out/bin
    cp target/release/${appBinName} $out/bin

    # echo for debug
    echo -e "\nApp was successfully installed in $out\n"
  '';

  meta = {
    description = appComment;
    homepage = "https://github.com/Thaumy/dup-img-finder";
    license = lib.licenses.mit;
    maintainers = [ "thaumy" ];
    platforms = lib.platforms.linux;
  };
}
