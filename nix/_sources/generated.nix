# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl }:
{
  zeek-master = {
    pname = "zeek-master";
    version = "2de38750fd76c90e3a0a76e87af9a2b2c8158d87";
    src = fetchgit {
      url = "https://github.com/zeek/zeek";
      rev = "2de38750fd76c90e3a0a76e87af9a2b2c8158d87";
      fetchSubmodules = true;
      deepClone = false;
      leaveDotGit = false;
      sha256 = "16l12my18yqbd54awnmbr0m063nrhz21qnq8zvg61dmc2acrf0ph";
    };
    
  };
  zeek-release = {
    pname = "zeek-release";
    version = "4.0.2";
    src = fetchurl {
      sha256 = "15gxxgg7nmfmswlbxhvcp6alq5k9wpvrm5cwyf1qfd7xsfli61sm";
      url = "https://github.com/zeek/zeek/releases/download/v4.0.2/zeek-4.0.2.tar.gz";
    };
    
  };
}
