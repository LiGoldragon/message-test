# Flow: the Flow Nexus and its `flow` / `flow-meta` clients, taken from the
# `flow` input. The Nexus starts with no arguments; sockets under
# XDG_RUNTIME_DIR, store under HOME. Requests are Flow's design at eaab24fa
# (f5a6e9 flow-buildable-design): Lock, Identify, Deliver, Release, Current,
# End and Launch on the ordinary socket; Configure and Bind on the meta socket.
{ inputs }:
{
  forSystem = system: rec {
    package = inputs.flow.packages.${system}.default;

    nexus = "${package}/bin/flow-nexus";
    client = "${package}/bin/flow";
    metaClient = "${package}/bin/flow-meta";

    ordinarySocket = "flow/flow.sock";
    metaSocket = "flow/flow-meta.sock";
    store = ".local/state/flow/flow.sema";

    # One meta Configure payload per layer: the layer's model.
    modelPayload = layer: model: "Configure.Model.{ ${layer} ${model} }";
  };
}
