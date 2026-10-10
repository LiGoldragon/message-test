{
  description = "message-test — acceptance scenarios that run the real Message Nexus with the real Flow Nexus, written to Primary flows/73ada7/reports/build/message-design.md at 23d2c4c8 (blob 24fee3c0) and flows/f5a6e9/reports/flow-buildable-design.md at 30e8efc4 (blob 4bad0825).";

  inputs = {
    nixpkgs.url = "github:LiGoldragon/nixpkgs?ref=main";

    blueprint.url = "github:numtide/blueprint";
    blueprint.inputs.nixpkgs.follows = "nixpkgs";

    message.url = "github:LiGoldragon/message";
    message.inputs.nixpkgs.follows = "nixpkgs";

    # Old Message, whose version-1 store test 21 starts on.
    message-old.url = "github:LiGoldragon/message/6fa4d0c1ba19232132081be228c418c667fff120";
    message-old.inputs.nixpkgs.follows = "nixpkgs";

    flow.url = "github:LiGoldragon/flow";
    flow.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
