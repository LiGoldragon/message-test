# Old Message: the Message Nexus before the design (0.19.1), from the
# `message-old` input. Its store at the Message store path is schema
# version 1, the store test 21 starts the new Message on.
{ inputs }:
{
  forSystem = system: rec {
    package = inputs.message-old.packages.${system}.default;
    nexus = "${package}/bin/message-nexus";
  };
}
