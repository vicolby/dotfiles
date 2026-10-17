{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    jq        # json on the command line
    lazygit
    neovim
    nodejs    # node/npx, needed by MCP servers like argocd-mcp and repograph
    basedpyright  # python LSP for nvim (go to definition etc.)
    go        # go toolchain
    gopls     # go LSP for nvim
    kubectl
    awscli2   # aws-iam-authenticator via `aws eks get-token`, used by kubectl exec credential plugin
    argocd
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  # Tools not packaged in nixpkgs or Homebrew (firstmate's toolchain) install into user-writable
  # prefixes, since the Nix-managed npm prefix is read-only.
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
    "${config.home.homeDirectory}/.local/bin"
  ];
  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.npm-global
  '';
  home.activation.installFirstmateTools = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Subshell so the PATH change cannot leak into later home-manager steps (macOS /usr/bin
    # readlink lacks -e, which breaks link generation).
    (
      export PATH="${pkgs.nodejs}/bin:${pkgs.git}/bin:$PATH:/usr/bin:/bin"
      # Set explicitly: this step can run before ~/.npmrc is linked on the first activation.
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
      for pkg in gh-axi chrome-devtools-axi tasks-axi quota-axi lavish-axi; do
        if [ ! -e "$HOME/.npm-global/bin/$pkg" ]; then
          run npm install -g "$pkg" || echo "warning: npm install -g $pkg failed"
        fi
      done
      if [ ! -e "$HOME/.local/bin/no-mistakes" ]; then
        run env NO_MISTAKES_INSTALL_DIR="$HOME/.local/bin" sh -c \
          'curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh' \
          || echo "warning: no-mistakes install failed"
      fi
    )
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^e' autosuggest-accept

      # Ctrl+F: fuzzy-find a file and open it in nvim
      find-file-widget() {
        local file
        file=$(fd --type f --hidden --exclude .git 2>/dev/null | fzf --height 40% --reverse)
        if [[ -n "$file" ]]; then
          BUFFER="nvim -- ''${(q)file}"
          zle accept-line
        else
          zle reset-prompt
        fi
      }
      zle -N find-file-widget
      bindkey '^f' find-file-widget
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
      k = "kubectl";
    };
  };

  programs.pyenv = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Ctrl+R / Ctrl+T / Alt+C open the fuzzy menu instead of plain single-line search
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
