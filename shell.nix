{
  pkgs ? import <nixpkgs> { },
}:

let
  tree-sitter-typst = pkgs.callPackage ./packages/tree-sitter-typst.nix { };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # Presentation tools
    typst

    # Code search and refactoring
    ast-grep

    # Tree-sitter support
    tree-sitter
    gcc

    # Shell
    nushell

    # Custom tree-sitter grammar
    tree-sitter-typst
  ];

  shellHook = ''
    # Make tree-sitter-typst available to ast-grep
    export TREE_SITTER_TYPST_LIB="${tree-sitter-typst}/lib/typst.so"

    # Create .tree-sitter directory and symlink using nu shell
    nu -c '
      mkdir .tree-sitter
      if not (".tree-sitter/typst.so" | path exists) {
        ln -sf $env.TREE_SITTER_TYPST_LIB .tree-sitter/typst.so
        print "Linked tree-sitter-typst grammar to .tree-sitter/typst.so"
      }
    '

    echo "Development environment loaded"
    echo "  Typst: $(typst --version)"
    echo "  ast-grep: $(ast-grep --version)"
    echo "  tree-sitter-typst: $TREE_SITTER_TYPST_LIB"
  '';
}
