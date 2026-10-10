# Flow: the Flow Nexus and its `flow` / `flow-meta` clients, taken from the
# `flow` input. The Nexus starts with Start.{ ordinary meta }, the sockets
# its clients reach by default. Requests are Flow's design at Primary 186dd701,
# flows/f5a6e9/reports/flow-buildable-design.md (blob 3bbe7b6a): Lock,
# Identify, Deliver, Release, Bind, Current, End, Stop and Metaflows on the
# flow socket; Configure and Configuration on the meta socket.
{ inputs }:
{
  forSystem = system: rec {
    package = inputs.flow.packages.${system}.default;

    nexus = "${package}/bin/flow-nexus";
    client = "${package}/bin/flow";
    metaClient = "${package}/bin/flow-meta";

    # The Flow edge Message's configuration names, relative to
    # XDG_RUNTIME_DIR (Message design, section 3).
    ordinarySocket = "flow/flow.sock";

    # The meta socket a runner starts Flow on with Start.{ ordinary meta }:
    # where Flow's clients look by default.
    metaSocket = "flow/flow-meta.sock";

    # One meta Configure payload per layer: the layer's model.
    modelPayload = layer: model: "Configure.Model.{ ${layer} ${model} }";
  };
}
