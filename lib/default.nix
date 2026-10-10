{ inputs, ... }:
{
  # One entry per component a scenario drives. A scenario reaches these as
  # `flake.lib.components.<name>` and adds only its own drive and assertions.
  components = {
    message = import ./components/message.nix { inherit inputs; };
    flow = import ./components/flow.nix { inherit inputs; };
    herdr = import ./components/herdr.nix;
  };

  # The frame every pure message-flow scenario shares:
  # `flake.lib.messageFlow { pkgs, flake, system } { name, forks, script }`.
  messageFlow = import ./message-flow.nix;

  # The cheapest model per harness, the semi-sandbox default.
  cheapestModel = {
    claude = "haiku";
    codex = "luna";
  };
}
