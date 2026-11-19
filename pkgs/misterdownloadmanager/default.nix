{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  makeWrapper,
  libGL,
  vulkan-loader,
  wayland,
  libxkbcommon,
  libxcb,
  libX11,
  libXcursor,
  libXrender,
  libXi,
  dbus,
  _7zz,
  ffmpeg,
  yt-dlp,
  gallery-dl,
}:

let
  pname = "misterdownloadmanager";
  version = "0.5.2";

  src = fetchurl {
    url = "https://github.com/anefzaoui/misterdownloadmanager/releases/download/v${version}/MisterDownloadManager-${version}-linux-x86_64.AppImage";
    hash = "sha256-cLytlne3VN//0RjOoenwvLS38o+PcL0xKPvBs61qdPQ=";
  };

  # The AppImage is unpacked here instead of `appimageTools.wrapType2` because the
  # release ships FOUR programs (`misterdownloadmanager`, `-cli`, `-mcp`, `-nmhost`)
  # while wrapType2 only exposes AppRun (the GUI) from an FHS chroot, which would
  # leave the browser native-messaging host unreachable. Extracting also gives us the
  # real .desktop entry and 256x256 icon, which wrapType2 installs neither of.
  appimageContents = appimageTools.extract { inherit pname version src; };
in
stdenv.mkDerivation {
  inherit pname version;

  src = appimageContents;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # The programs link only libc/libm/libgcc_s (verified with `objdump -p`); every
  # window library below is dlopen()ed when a window opens, so it has to be found
  # through the RPATH at run time rather than linked.
  buildInputs = [
    stdenv.cc.cc.lib
    libGL
    vulkan-loader
    wayland
    libxkbcommon
    libxcb
    libX11
    libXcursor
    libXrender
    libXi
    dbus
  ];

  runtimeDependencies = [
    libGL
    vulkan-loader
    wayland
    libxkbcommon
    libxcb
    libX11
    libXcursor
    libXrender
    libXi
    dbus
  ];

  helperPath = lib.makeBinPath [
    _7zz
    ffmpeg
    yt-dlp
    gallery-dl
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/* -t "$out/bin"

    install -Dm644 misterdownloadmanager.png \
      "$out/share/icons/hicolor/256x256/apps/misterdownloadmanager.png"
    install -Dm644 misterdownloadmanager.desktop \
      "$out/share/applications/misterdownloadmanager.desktop"
    # The AppImage's entry lacks the window class (the .deb's has it); Plasma matches
    # a pinned taskbar entry to the window through it.
    echo "StartupWMClass=misterdownloadmanager" \
      >> "$out/share/applications/misterdownloadmanager.desktop"

    runHook postInstall
  '';

  # MDM can download yt-dlp/ffmpeg/gallery-dl itself, but 7-Zip (7z/RAR extraction)
  # it cannot; put all four on the programs' PATH so none of them is fetched at run
  # time (those downloads land in the user's data dir, outside the flake).
  postFixup = ''
    wrapProgram "$out/bin/misterdownloadmanager" --prefix PATH : "$helperPath"
    wrapProgram "$out/bin/misterdownloadmanager-cli" --prefix PATH : "$helperPath"
  '';

  meta = {
    description = "Open-source download manager with segmented downloads, torrents and video support";
    homepage = "https://github.com/anefzaoui/misterdownloadmanager";
    license = lib.licenses.gpl3Plus;
    # The release is a prebuilt AppImage (the source is GPL-3.0-or-later upstream).
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "misterdownloadmanager";
  };
}
