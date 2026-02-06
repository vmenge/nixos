# mk-plasma-theme.nix
{ pkgs, lib }:

let
  inherit (pkgs) stdenvNoCC;

  kindToShareSubdir = {
    desktoptheme = "plasma/desktoptheme";
    lookAndFeel = "plasma/look-and-feel";
    aurorae = "aurorae/themes";
    colorSchemes = "color-schemes";
    icons = "icons";
    cursors = "icons";
    wallpapers = "wallpapers";
    plasmoids = "plasma/plasmoids";
  };
in

{
  kind,
  pname,
  version,
  src,
  themeName ? pname,
  installSubdir ? null,
  stripTopLevel ? true,
  mode ? "single", # "single" | "collection"
  includeGlobs ? null, # e.g. [ "*aurorae" ] or [ "*.colors" ]
  excludeGlobs ? [ ], # e.g. [ "*.md" ".git*" ]
  meta ? { },
}:

let
  subdir =
    if installSubdir != null then
      installSubdir
    else
      kindToShareSubdir.${kind} or (throw "mkPlasmaTheme: unknown kind '${kind}'");

  mkCopyScript =
    { dstExpr }:
    ''
      set -euo pipefail
      shopt -s dotglob nullglob

      # Optionally strip a single top-level directory (common in archives)
      entries=( * )
      if ${
        if stripTopLevel then "true" else "false"
      } && [ "''${#entries[@]}" -eq 1 ] && [ -d "''${entries[0]}" ]; then
        cd "''${entries[0]}"
        shopt -s dotglob nullglob
      fi

      dst=${dstExpr}
      mkdir -p "$dst"

      ${
        if includeGlobs == null then
          ''
            items=( * )
          ''
        else
          ''
            items=()
            ${lib.concatStringsSep "\n" (
              map (g: ''
                for x in ${lib.escapeShellArg g}; do :; done
              '') includeGlobs
            )}
            # expand globs
            for g in ${lib.concatStringsSep " " (map lib.escapeShellArg includeGlobs)}; do
              for x in $g; do
                items+=( "$x" )
              done
            done
          ''
      }

      # apply excludes
      ${lib.concatStringsSep "\n" (
        map (g: ''
          for i in "''${!items[@]}"; do
            case "''${items[$i]}" in
              ${g}) unset 'items[$i]' ;;
            esac
          done
        '') (map lib.escapeShellArg excludeGlobs)
      )}

      # copy files/dirs (preserve directories)
      for x in "''${items[@]}"; do
        if [ -e "$x" ]; then
          cp -R "$x" "$dst/"
        fi
      done
    '';

  installSingle = mkCopyScript { dstExpr = ''"$out/share/${subdir}/${themeName}"''; };
  installCollection = mkCopyScript { dstExpr = ''"$out/share/${subdir}"''; };
in

stdenvNoCC.mkDerivation {
  inherit
    pname
    version
    src
    meta
    ;
  dontBuild = true;
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    ${if mode == "collection" then installCollection else installSingle}
    runHook postInstall
  '';
}
