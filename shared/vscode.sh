#!/usr/bin/env bash

extensions=(
    "adpyke.codesnap"
    "adriano-markovic.c-cpp-makefile-project"
    "ardenivanov.svelte-intellisense"
    "bradlc.vscode-tailwindcss"
    "christian-kohler.path-intellisense"
    "codezombiech.gitignore"
    "csstools.postcss"
    "dannyconnell.split-html-attributes"
    "dbaeumer.vscode-eslint"
    "eamodio.gitlens"
    "esbenp.prettier-vscode"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-rename-tag"
    "formulahendry.code-runner"
    "github.github-vscode-theme"
    "github.vscode-github-actions"
    "github.vscode-pull-request-github"
    "mads-hartmann.bash-ide-vscode"
    "mhutchie.git-graph"
    "ms-vscode.cpptools"
    "ms-vscode.makefile-tools"
    "pkief.material-icon-theme"
    "rust-lang.rust-analyzer"
    "rvest.vs-code-prettier-eslint"
    "steoates.autoimport"
    "svelte.svelte-vscode"
    "tamasfe.even-better-toml"
    "timonwong.shellcheck"
    "ultram4rine.vscode-choosealicense"
    "usernamehw.errorlens"
    "vadimcn.vscode-lldb"
    "visualstudioexptteam.intellicode-api-usage-examples"
    "visualstudioexptteam.vscodeintellicode"
    "vue.volar"
    "vue.vscode-typescript-vue-plugin"
    "zignd.html-css-class-completion"
)

# Install extensions
for ext in "${extensions[@]}"; do
    code --force --install-extension "$ext"
done

# Copy key bindings
WORK_DIR=$(pwd)
cd "$WORK_DIR" || exit
cp -fv "./../config/keybindings.json" "$HOME/.config/Code/User"