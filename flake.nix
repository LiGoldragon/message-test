{
  description = "message-test — acceptance scenarios that run the real Message Nexus with the real Flow Nexus, written to Primary flows/73ada7/reports/build/message-design.md at 3a4bbb61 (blob 1a211b88) and flows/f5a6e9/reports/flow-buildable-design.md at e846c2ca (blob d45c1d45).";

  inputs = {
    nixpkgs.url = "github:LiGoldragon/nixpkgs?ref=main";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    message.url = "github:LiGoldragon/message";
    message.inputs.nixpkgs.follows = "nixpkgs";

    flow.url = "github:LiGoldragon/flow";
    flow.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
