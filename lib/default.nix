{ inputs, ... }:
{
  # One entry per component a scenario drives. A scenario reaches these as
  # `flake.lib.components.<name>` and adds only its own drive and assertions.
  components = {
    message = import ./components/message.nix { inherit inputs; };
    messageOld = import ./components/message-old.nix { inherit inputs; };
    flow = import ./components/flow.nix { inherit inputs; };
    herdr = import ./components/herdr.nix;
    flowStandIn = {
      forSystem = system: {
        package = import ../packages/flow-stand-in.nix {
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          flake = inputs;
          inherit system;
        };
      };
    };
  };

  # The frame every pure message-flow scenario shares:
  # `flake.lib.messageFlow { pkgs, flake, system } { name, forks, script }`,
  # with `packages` for what one scenario alone puts in the machine.
  messageFlow = import ./message-flow.nix;

  # The skill-variable reader: `flake.lib.skillVariable { pkgs }`.
  skillVariable = import ./skill-variable.nix;

  # The cheapest model per harness, the semi-sandbox default.
  cheapestModel = {
    claude = "haiku";
    codex = "luna";
  };
}
