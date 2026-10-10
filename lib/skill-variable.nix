# skill-variable <file> <name>: prints the value of the line `<name>: <value>`
# in a skill variables file, the whole name matched and the line split at the
# first ": " after it. Exits 1 when no line carries the name.
{ pkgs }:
pkgs.writeShellApplication {
  name = "skill-variable";
  text = ''
    file="$1" name="$2"
    while IFS= read -r line; do
      case "$line" in
        "$name: "*)
          printf '%s\n' "''${line#"$name: "}"
          exit 0
          ;;
      esac
    done < "$file"
    exit 1
  '';
}
