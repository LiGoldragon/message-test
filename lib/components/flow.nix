# Flow: the Flow Nexus and its `flow` / `flow-meta` clients, taken from the
# `flow` input. The Nexus starts with no arguments and its clients reach it
# at its default sockets. Requests are Flow's design at Primary e846c2ca,
# flows/f5a6e9/reports/flow-buildable-design.md (blob d45c1d45): Lock,
# Identify, Deliver, Release, Current and End on the flow socket; Configure
# and Bind on the meta socket.
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

    # One meta Configure payload per layer: the layer's model.
    modelPayload = layer: model: "Configure.Model.{ ${layer} ${model} }";
  };
}
