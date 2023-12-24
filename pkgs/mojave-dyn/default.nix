{ lib
, stdenv
, fetchFromGitHub
}:
let
  name = "mojave-dyn";

  src = fetchFromGitHub {
    owner = "Thaumy";
    repo = "gnome-dyn-wallpapers";
    rev = "df8472e660e0d1b1c96f72c8d2b43d3824de65d3";
    hash = "sha256-uQTfufw1xnNy5EiYJueEtTHErDLpUlJQAAL0IZEu8sw=";
  };
in
stdenv.mkDerivation {
  inherit name src;

  installPhase = ''
    declare inner_xml_root=$out/share/backgrounds/macOS/${name}
    declare name_xml_root=$out/share/gnome-background-properties
    mkdir -p $inner_xml_root
    mkdir -p $name_xml_root

    cp $src/${name}/inner.xml $inner_xml_root
    sed -i "s,ROOT,$src/${name},g" $inner_xml_root/inner.xml

    cp $src/${name}/${name}.xml $name_xml_root
    sed -i "s,ROOT,$inner_xml_root,g" $name_xml_root/${name}.xml
  '';

  meta = {
    description = "macOS mojave dynamic wallpaper for GNOME";
    license = lib.licenses.mit;
    maintainers = [ "thaumy" ];
    platforms = lib.platforms.linux;
  };
}
