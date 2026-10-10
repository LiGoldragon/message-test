{
  description = "message-test — acceptance scenarios that run the real Message Nexus with the real Flow Nexus, written to Primary flows/73ada7/reports/build/message-design.md at be5c2e5b (blob e3ea9872) and flows/f5a6e9/reports/flow-buildable-design.md at 9b006dd2 (blob c443d8a8).";

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

    signal-flow.url = "github:LiGoldragon/signal-flow/a991c1499b201ad75a084a6542d2f110c46720ce";
    signal-flow.inputs.nixpkgs.follows = "nixpkgs";

    signal.url = "github:LiGoldragon/signal/e0e3c05573405e793037205640e54cfd769bb1b4";
    signal.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs: inputs.blueprint { inherit inputs; };
}
