{ fetchFromGitHub, fetchgit, writeScript, confdir
, PostgresqlPlugin, KafkaPlugin, zeekctl, Http2Plugin, SpicyPlugin, ikev2Plugin, communityIdPlugin
, llvmPackages_9 }:
let
  importJSON = file: builtins.fromJSON (builtins.readFile file);
  flakeLock = importJSON ./flake.lock;
  loadInput = { locked, ... }:
    assert locked.type == "git";
    fetchgit {
      url = "${locked.url}";
      rev = "${locked.rev}";
      sha256 = locked.narHash;
    };
in
rec {
  #import zeek script 
  zeek-postgresql = loadInput flakeLock.nodes.zeek-postgresql;
  metron-bro-plugin-kafka = loadInput flakeLock.nodes.metron-bro-plugin-kafka;
  bro-http2 =  loadInput flakeLock.nodes.bro-http2;
  zeek-plugin-ikev2 = loadInput flakeLock.nodes.zeek-plugin-ikev2;
  zeek-community-id = loadInput flakeLock.nodes.zeek-community-id;
  ##failed spicy plugin 
  Spicy = fetchFromGitHub (builtins.fromJSON (builtins.readFile ./zeek-plugin.json)).spicy;


  install_plugin = writeScript "install_plugin" (import ./install_plugin.nix { inherit llvmPackages_9; });
  postFixup =  (if zeekctl then ''
         substituteInPlace $out/etc/zeekctl.cfg \
         --replace "CfgDir = $out/etc" "CfgDir = ${confdir}/etc" \
         --replace "SpoolDir = $out/spool" "SpoolDir = ${confdir}/spool" \
         --replace "LogDir = $out/logs" "LogDir = ${confdir}/logs"


         echo "scriptsdir = ${confdir}/scripts" >> $out/etc/zeekctl.cfg
         echo "helperdir = ${confdir}/scripts/helpers" >> $out/etc/zeekctl.cfg
         echo "postprocdir = ${confdir}/scripts/postprocessors" >> $out/etc/zeekctl.cfg
         echo "sitepolicypath = ${confdir}/policy" >> $out/etc/zeekctl.cfg
         ## default disable sendmail
         echo "sendmail=" >> $out/etc/zeekctl.cfg
         '' else "") +
  (if communityIdPlugin then ''
         ##INSTALL ZEEK Plugins
       bash ${install_plugin} zeek-community-id ${zeek-community-id}
         '' else "") +
  (if KafkaPlugin then ''
         ##INSTALL ZEEK Plugins
       bash ${install_plugin} metron-bro-plugin-kafka ${metron-bro-plugin-kafka}
         '' else "") +
  (if ikev2Plugin then ''
         ##INSTALL ZEEK Plugins
       bash ${install_plugin} zeek-plugin-ikev2 ${zeek-plugin-ikev2}
         '' else "") +
  (if Http2Plugin then ''
         ##INSTALL ZEEK Plugins
       bash ${install_plugin} bro-http2 ${bro-http2}
         '' else "") +
  (if SpicyPlugin then ''
    mkdir -p /build/spicy
    cp -r ${Spicy}/* /build/spicy
    chmod 755  /build/spicy/*
    patchShebangs /build/spicy/scripts/autogen-type-erased
    patchShebangs /build/spicy/scripts/autogen-dispatchers
    bash ${install_plugin} spicy ${Spicy}
            '' else "") +
  (if PostgresqlPlugin then ''
             bash ${install_plugin} zeek-postgresql ${zeek-postgresql}
    '' else "");
}
