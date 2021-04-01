{ stdenv
, lib
, fetchurl
, cmake
, flex
, bison
, openssl
, libpcap
, zlib
, file
, curl
, libmaxminddb
, gperftools
, swig
, fetchpatch
, ncurses5
, caf
  ## Plugin dependencies
, pkgs
, rdkafka
, postgresql
, coreutils
, callPackage
, libnghttp2
, brotli
, python38
, llvmPackages
, which
, geoip
, ccache
, libzip
, podofo
, makeWrapper
, PostgresqlPlugin ? false
, KafkaPlugin ? false
, Http2Plugin ? false
, SpicyPlugin ? false
, SpicyAnalyzersPlugin ? false
, Ikev2Plugin ? false
, CommunityIdPlugin ? false
, ZipPlugin ? false
, PdfPlugin ? false
, zeekctl ? true
, version ? "4.0.0"
}:
let
  preConfigure = (import ./script.nix { });

  pname = "zeek";
  confdir = "/var/lib/${pname}";

  plugin = callPackage ./plugin.nix {
    inherit confdir zeekctl pkgs
      PostgresqlPlugin ZipPlugin PdfPlugin CommunityIdPlugin KafkaPlugin Http2Plugin
      SpicyPlugin SpicyAnalyzersPlugin
      Ikev2Plugin;
  };
in
stdenv.mkDerivation rec {
  inherit pname version;
  src = fetchurl {
    url = "https://download.zeek.org/zeek-${version}.tar.gz";
    sha256 = "sha256-8u7asyYuqj9YqDRCsfOLrTXtcjmVZJF7cbukImbx/1Q=";
  };

  configureFlags = [
    "--with-geoip=${geoip}"
  ];

  ##for spicy ccache
  HOME = ".";

  nativeBuildInputs = [ cmake flex bison file makeWrapper ]
    ++ lib.optionals SpicyPlugin [ python38 ];
  buildInputs = [ openssl libpcap zlib curl libmaxminddb gperftools python38 swig caf ncurses5 ]
    ++ lib.optionals KafkaPlugin
    [ rdkafka ]
    ++ lib.optionals PostgresqlPlugin
    [ postgresql ]
    ++ lib.optionals ZipPlugin
    [ libzip ]
    ++ lib.optionals PdfPlugin
    [ podofo ]
    ++ lib.optionals Http2Plugin
    [ libnghttp2 brotli ]
    ++ lib.optionals SpicyPlugin
    [ which ccache llvmPackages.lld llvmPackages.clang-unwrapped llvmPackages.llvm ];

  ZEEK_DIST = "${placeholder "out"}";
  #see issue https://github.com/zeek/zeek/issues/804 to modify hardlinking duplicate files.
  inherit preConfigure;

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DPYTHON_EXECUTABLE=${python38}/bin/python"
    "-DPYTHON_INCLUDE_DIR=${python38}/include"
    "-DPYTHON_LIBRARY=${python38}/lib"
    "-DPY_MOD_INSTALL_DIR=${placeholder "out"}/${python38.sitePackages}"
    "-DENABLE_PERFTOOLS=true"
    "-DINSTALL_AUX_TOOLS=true"
    "-DINSTALL_ZEEKCTL=true"
    "-DZEEK_ETC_INSTALL_DIR=${placeholder "out"}/etc"
  ];

  postInstall = ''
    for file in $out/share/zeek/base/frameworks/notice/actions/pp-alarms.zeek $out/share/zeek/base/frameworks/notice/main.zeek; do
      substituteInPlace $file \
         --replace "/bin/rm" "${coreutils}/bin/rm" \
         --replace "/bin/cat" "${coreutils}/bin/cat"
    done
    for file in $out/share/zeek/policy/misc/trim-trace-file.zeek $out/share/zeek/base/frameworks/logging/postprocessors/scp.zeek $out/share/zeek/base/frameworks/logging/postprocessors/sftp.zeek; do
      substituteInPlace $file --replace "/bin/rm" "${coreutils}/bin/rm"
    done
  '';

  inherit (plugin) postFixup;

  meta = with lib; {
    description = "Powerful network analysis framework much different from a typical IDS";
    homepage = "https://www.zeek.org";
    license = licenses.bsd3;
    #maintainers = with maintainers; [ gtrunsec ];
    platforms = platforms.unix;
  };
}
