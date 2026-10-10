# Herdr: the terminal multiplexer Flow places requests into. A scenario runs
# `herdr server` headless (no terminal attached) on its own HOME; its panes
# are the stand-in harnesses a scenario binds to metaflows.
{
  forPkgs = pkgs: rec {
    package = pkgs.herdr;
    bin = "${package}/bin/herdr";
  };
}
