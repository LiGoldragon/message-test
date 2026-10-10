{
  description = "message-test — acceptance scenarios that run the real Message Nexus with the real Flow Nexus, written to Primary flows/73ada7/reports/build/message-design.md at e275b6bd (blob 66d3fdcf) and flows/f5a6e9/reports/flow-buildable-design.md at 7398a43c (blob ff8a60ce).";

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
