{ pkgs, ... }:
pkgs.rustPlatform.buildRustPackage {
  pname = "flow-stand-in";
  version = "0.1.0";
  src = ../fixtures/message-flow/flow-stand-in;
  cargoHash = "sha256-t+f6tWqk9SJ2KI2lgC3hMJGakQf9qzp6AwzgQU/oML8=";

  meta.description = "Typed Flow ordinary-protocol stand-in for message-test fixtures";
}
