{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
  enable = true;
    history = {
      append = true;
      findNoDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      path = "/home/sunny/.config/zsh/.zsh_history";
      share = true;
      ignoreDups = true;
      saveNoDups = true;
      save = 8000;
      size = 8000;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = ["main" "brackets" "cursor" "root"];
    };
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
      ];
    };
    historySubstringSearch.enable = true;
    # zprof.enable = true; #benchmark shell
  };
}
