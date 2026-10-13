{ appimageTools, fetchurl, lib }:
appimageTools.wrapType2 {
  pname = "photocraft";
  version = "0.7.0";

  src = fetchurl {
    url = "https://github.com/storytold/photocraft/releases/download/v0.7.0/photocraft-0.7.0-linux-x86_64.AppImage";
    sha256 = "sha256-h+vONrzfazHRapyiLOKfmtjbaBheTZgRiADRwt54rEI=";
  };

  # Ensure proper desktop entry/icon integration
  extraPkgs = pkgs: with pkgs; [
    fuse3
  ];

  meta = with lib; {
    description = "AI photo editor";
    homepage = "https://github.com/storytold/photocraft";
    license = licenses.mit; # or adjust if needed
    platforms = [ "x86_64-linux" ];
    mainProgram = "photocraft";
  };
}
