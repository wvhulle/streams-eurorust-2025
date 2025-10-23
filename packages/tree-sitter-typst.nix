{
  lib,
  stdenv,
  fetchFromGitHub,
  tree-sitter,
}:

stdenv.mkDerivation {
  pname = "tree-sitter-typst";
  version = "unstable-2024-10-23";

  src = fetchFromGitHub {
    owner = "uben0";
    repo = "tree-sitter-typst";
    rev = "master";
    hash = "sha256-s/9R3DKA6dix6BkU4mGXaVggE4bnzOyu20T1wuqHQxk=";
  };

  nativeBuildInputs = [
    tree-sitter
  ];

  buildPhase = ''
    runHook preBuild

    # Compile the tree-sitter grammar
    gcc -shared -fPIC -fno-exceptions \
      -I src \
      -o typst.so \
      -O2 \
      src/scanner.c \
      -xc src/parser.c

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp typst.so $out/lib/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Tree-sitter grammar for Typst";
    homepage = "https://github.com/uben0/tree-sitter-typst";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
