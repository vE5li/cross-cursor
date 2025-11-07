{
  lib,
  stdenv,
  inkscape,
  xcursorgen,
}:
stdenv.mkDerivation {
  pname = "cross-cursor";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    inkscape
    xcursorgen
  ];

  buildPhase = ''
    runHook preBuild

    for theme_src_dir in src/*; do
      # Skip if not a directory or doesn't contain index.theme
      [ -d "$theme_src_dir" ] || continue
      [ -f "$theme_src_dir/index.theme" ] || continue

      theme_name="$(basename "$theme_src_dir")"
      theme_build_dir="build/$theme_name"

      echo "=> Building theme: $theme_name"

      mkdir -p "$theme_build_dir"

      # Convert SVG to PNG at multiple sizes
      for svg_file in "$theme_src_dir"/*.svg; do
        [ -f "$svg_file" ] || continue
        base_name="$(basename "$svg_file" .svg)"

        for size in 24 32 48 64; do
          echo "Converting $base_name to ''${size}px PNG..."
          inkscape \
            -o "$theme_build_dir/''${base_name}_''${size}.png" \
            -w $size -h $size \
            "$svg_file"
        done
      done
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons

    for theme_src_dir in src/*; do
      [ -d "$theme_src_dir" ] || continue
      [ -f "$theme_src_dir/index.theme" ] || continue

      theme_name="$(basename "$theme_src_dir")"
      theme_build_dir="build/$theme_name"
      theme_out_dir="$out/share/icons/$theme_name"

      mkdir -p "$theme_out_dir/cursors"

      echo "=> Installing theme: $theme_name"

      # Generate cursor files using xcursorgen
      for config in src/config/*.cursor; do
        [ -f "$config" ] || continue
        base_name="$(basename "$config" .cursor)"
        echo "Generating cursor: $base_name"
        xcursorgen -p "$theme_build_dir" "$config" "$theme_out_dir/cursors/$base_name"
      done

      # Create symlink aliases from cursorList
      while read -r symlink target; do
        [ -z "$symlink" ] && continue
        [ -e "$theme_out_dir/cursors/$symlink" ] && continue
        ln -sf "$target" "$theme_out_dir/cursors/$symlink"
      done < src/cursorList

      # Copy theme metadata files
      cp "$theme_src_dir/index.theme" "$theme_out_dir/"
      cp "$theme_src_dir/cursor.theme" "$theme_out_dir/"
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "Cross cursor theme";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [];
  };
}
