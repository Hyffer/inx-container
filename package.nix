{ runCommand }:

let
  pname = "inx-container";
  version = "0.0.2";
in

runCommand "${pname}-${version}"
  { }
  ''
    mkdir -p $out/bin
    install -m +x ${./inx-container} $out/bin/inx-container
    cp ${./config.yaml} $out/bin/config.yaml
  ''
