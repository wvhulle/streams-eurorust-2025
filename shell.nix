{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Presentation tools
    typst

    # Code search and refactoring with custom grammars
    ast-grep

    # Tree-sitter support
    tree-sitter
    gcc

    # Shell
    nushell
  ];

}
