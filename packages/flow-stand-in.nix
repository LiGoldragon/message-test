{ pkgs, ... }:
pkgs.rustPlatform.buildRustPackage {
  pname = "flow-stand-in";
  version = "0.1.0";
  src = ../fixtures/message-flow/flow-stand-in;
  cargoHash = pkgs.lib.fakeHash;

  meta.description = "Typed Flow ordinary-protocol stand-in for message-test fixtures";
}
