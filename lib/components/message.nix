# Message: the Message Nexus and its `message` / `message-meta` clients, taken
# from the `message` input. The Nexus starts with no arguments; its default
# configuration is relative to XDG_RUNTIME_DIR (sockets) and HOME (store),
# and its clients read the same defaults. Every path below is the Message
# design's at Primary 3a4bbb61 (blob 1a211b88), flows/73ada7/reports/build/message-design.md,
# section 3.
{ inputs }:
{
  forSystem = system: rec {
    package = inputs.message.packages.${system}.default;

    nexus = "${package}/bin/message-nexus";
    client = "${package}/bin/message";
    metaClient = "${package}/bin/message-meta";

    # Relative to XDG_RUNTIME_DIR and HOME.
    ordinarySocket = "message/message.sock";
    metaSocket = "message/message-meta.sock";
    store = ".local/state/message/message.sema";

    # The Message Configure payload: the two sockets and the Flow edge, all
    # under one runtime directory.
    configuration = runtime: ''
      Configure.{ ${runtime}/${ordinarySocket}
                  ${runtime}/${metaSocket}
                  ${runtime}/flow/flow.sock }
    '';
  };
}
