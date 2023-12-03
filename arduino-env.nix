{ lib, pkgs }:

let
  mkArduinoEnv = {
    packages ? []
    , libraries ? []
    , runtimeInputs ? []
  }: let
    arduino-cli = pkgs.wrapArduinoCLI {
      inherit packages libraries;
    };
  in pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    name = "arduino-env";

    buildInputs = [ pkgs.makeWrapper ];

    phases = ["buildPhase"];

    buildPhase = ''
      mkdir -p $out
      makeWrapper ${arduino-cli}/bin/arduino-cli $out/bin/arduino-cli \
        --prefix PATH : ${lib.makeBinPath runtimeInputs}
    '';

    passthru = {
      buildArduinoSketch = buildArduinoSketch finalAttrs.finalPackage;
    };
  });

  buildArduinoSketch = arduinoEnv: {
    name
    , src
    , fqbn
  }: let
  in pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    inherit name src;

    buildPhase = ''
      ${arduinoEnv}/bin/arduino-cli compile --log --output-dir=out --fqbn=${fqbn}
    '';

    installPhase = ''
      mkdir -p $out
      cp -R out/* $out
    '';

    passthru = {
      uploadArduinoSketch = uploadArduinoSketch arduinoEnv {
        inherit fqbn;
        arduinoSketch = (finalAttrs.finalPackage);
      };
    };
  });

  uploadArduinoSketch = arduinoEnv: {
    arduinoSketch
    , fqbn
  }: pkgs.writeScriptBin "upload-arduino-sketch" ''
      ${arduinoEnv}/bin/arduino-cli upload --log --input-dir=${arduinoSketch} --fqbn=${fqbn} "$@"
  '';
in
  mkArduinoEnv
