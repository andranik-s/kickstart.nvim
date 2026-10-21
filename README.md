# kickstart.nvim

## Personal keymaps and C++ debugging

The leader key is **Space**. Restart Neovim after updating this config; `vim.pack`
installs the three debugger plugins on the first start.

### Git hunks

These mappings are available in buffers attached to a Git repository.

| Keys | Action |
| --- | --- |
| `]h` / `[h` (also `]c` / `[c`) | Next / previous hunk |
| `<leader>hp` / `<leader>hi` | Preview hunk in a popup / inline |
| `<leader>hr` | Reset (undo/discard) the current hunk; `u` undoes the reset |
| `<leader>hs` | Stage the current hunk; on a staged hunk, unstage it |
| `<leader>hS` / `<leader>hR` | Stage / reset all changes in this buffer |
| `<leader>hb` | Blame the current line |
| `<leader>hd` / `<leader>hD` | Diff against the index / last commit |
| `<leader>hq` / `<leader>hQ` | List changes in this file / repository in quickfix |
| `<leader>tb` / `<leader>tw` | Toggle inline blame / word diff |
| `ih` | Hunk text object, e.g. `vih` to select a hunk |

In visual mode, `<leader>hs` and `<leader>hr` act on the selected lines.
Reset changes the editor buffer; save with `:w` to write it to disk.

### LSP

Available after a language server attaches (C/C++ uses clangd):

| Keys | Action |
| --- | --- |
| `<leader>gd` / `<leader>gD` | Definition / declaration |
| `<leader>gr` / `<leader>gi` / `<leader>gt` | References / implementation / type definition |
| `<leader>gn` / `<leader>ga` | Rename / code action (also visual mode for code actions) |
| `<leader>gs` / `<leader>gS` | Document / workspace symbols |
| `K` / `<C-t>` | Hover documentation / jump back |

Press `<leader>g`, `<leader>h`, or `<leader>d` to see the available actions in which-key.

### Debug a C++ program

The config uses [nvim-dap](https://github.com/mfussenegger/nvim-dap),
[nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), and LLVM's
[lldb-dap](https://github.com/llvm/llvm-project/blob/main/lldb/tools/lldb-dap/README.md).
It detects `lldb-dap` or a versioned executable such as `lldb-dap-18` on `PATH`.
This machine already has `/usr/bin/lldb-dap-18`. On Ubuntu 24.04, if needed,
install it with `sudo apt install lldb-18`.
For another location, set `vim.g.lldb_dap = '/absolute/path/to/lldb-dap'` in
`init.lua` before `require 'kickstart.plugins.debug'`.

1. Open Neovim from the project root (`cd your-project && nvim main.cpp`).
   The debugger uses Neovim's working directory for the program's working directory.
2. Build with debug information and optimizations disabled:

   ```sh
   mkdir -p build
   clang++ -std=c++20 -g -O0 main.cpp -o build/app
   # g++ works with the same flags.
   ```

   For CMake projects, configure with `cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug`,
   then run `cmake --build build` (multi-config generators also need `--config Debug`).
   The debugger launches a compiled executable; it does not build the project.
3. Put the cursor on an executable source line and press `<leader>db` to set a breakpoint.
4. Press `<F5>` (or `<leader>dc`), select **C/C++: Launch executable (LLDB)**,
   and enter the executable path, e.g. `build/app`. The debugger UI opens automatically.
5. When execution pauses, inspect locals in **Scopes**, expand values with Enter,
   and add expressions in **Watches** with `a`. Use `<leader>de` to inspect the
   word under the cursor or a visual selection. The integrated terminal supports
   program input; enter insert mode there to type. Use `<Esc><Esc>` to leave terminal mode.
6. Continue or step using the keys below; stop with `<leader>dt`. Rebuild after source changes.

| Keys | Action |
| --- | --- |
| `<F5>` / `<leader>dc` | Start / continue |
| `<F10>` / `<leader>dn` | Step over (next line without entering the called function) |
| `<F11>` / `<leader>di` | Step into a called function |
| `<S-F11>` / `<leader>do` | Step out to the caller |
| `<leader>db` / `<leader>dB` | Toggle breakpoint / set conditional breakpoint, e.g. `i == 10` |
| `<leader>de` | Evaluate expression under cursor / visual selection |
| `<F7>` / `<leader>du` | Toggle debugger UI (also reopens it after the session ends) |
| `<leader>dr` / `<leader>dt` | Run last configuration / terminate session |

To debug a running process, choose **C/C++: Attach to process (LLDB)** on `<F5>`
and select its PID. The OS must allow attaching to that process.

For persistent executable paths, arguments, and environment variables, create
`.vscode/launch.json` in the project root. nvim-dap reads it automatically on `<F5>`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug app",
      "type": "lldb-dap",
      "request": "launch",
      "program": "${workspaceFolder}/build/app",
      "cwd": "${workspaceFolder}",
      "args": ["--example", "value"],
      "env": { "EXAMPLE": "1" },
      "stopOnEntry": false,
      "initCommands": ["settings clear plugin.symbol-locator.debuginfod.server-urls"],
      "preRunCommands": ["process handle -p true -s false -n false SIGWINCH"],
      "runInTerminal": true
    }
  ]
}
```

Use valid JSON without comments or trailing commas. Choose **Debug app** on `<F5>`.
`runInTerminal` supports the installed LLDB 18; LLVM 21+ also supports
`"console": "integratedTerminal"`.

The default configurations disable debuginfod downloads because this machine's
Ubuntu symbol server connection stalled LLDB during verification. Symbols in your
executable and locally installed debug symbol files remain available. To enable
downloads for system libraries, use a project launch configuration without that
`initCommands` setting.
The `preRunCommands` entry lets Unix terminal resize signals pass without pausing.

If breakpoints are not hit, check that you built with `-g -O0`, selected the right
binary, and rebuilt after editing. `:DapShowLog` shows adapter errors.

Verification with the installed LLDB 18.1.3 hit a breakpoint, inspected a local,
stepped, and exited the test program with code 0. The adapter then crashed in
`SBTarget::GetStatistics` while ending the session. If you encounter this exit-time
crash, update LLDB and select its executable with `vim.g.lldb_dap` as shown above.

## Introduction

A starting point for Neovim that is:

* Small
* Single-file
* Completely Documented

**NOT** a Neovim distribution, but instead a starting point for your configuration.

## Installation

### Install Neovim

Kickstart.nvim targets *only* the latest
['stable'](https://github.com/neovim/neovim/releases/tag/stable) and latest
['nightly'](https://github.com/neovim/neovim/releases/tag/nightly) of Neovim.
If you are experiencing issues, please make sure you have at least the latest
stable version. Most likely, you want to install neovim via a [package
manager](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-package).
To check your neovim version, run `nvim --version` and make sure it is not
below the latest
['stable'](https://github.com/neovim/neovim/releases/tag/stable) version. If
your chosen install method only gives you an outdated version of neovim, find
alternative [installation methods below](#alternative-neovim-installation-methods).

### Install External Dependencies

External Requirements:
- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation),
  [fd-find](https://github.com/sharkdp/fd#installation)
- [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md#installation)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Emoji fonts (Ubuntu only, and only if you want emoji!) `sudo apt install fonts-noto-color-emoji`
- Language Setup:
  - If you want to write Typescript, you need `npm`
  - If you want to write Golang, you will need `go`
  - etc.

> [!NOTE]
> See [Install Recipes](#Install-Recipes) for additional Windows and Linux specific notes
> and quick install snippets

### Install Kickstart

> [!NOTE]
> [Backup](#FAQ) your previous configuration (if any exists)

Neovim's configurations are located under the following paths, depending on your OS:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)| `%localappdata%\nvim\` |
| Windows (powershell)| `$env:LOCALAPPDATA\nvim\` |

#### Recommended Step

Create your own copy of this repo using GitHub's
["Use this template"](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
button so that you have your own copy that you can modify, then install by
cloning your new repo to your machine using one of the commands below,
depending on your OS.

Alternatively, you can [fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo)
this repo if you prefer an easy upstream sync path (e.g., keeping your config
on a separate branch and fast-forwarding `master` from upstream). See the
[discussion in #1740](https://github.com/nvim-lua/kickstart.nvim/issues/1740)
for the tradeoffs between the two approaches.

> [!NOTE]
> Your repo's URL will be something like this:
> `https://github.com/<your_github_username>/kickstart.nvim.git`

You likely want to remove `nvim-pack-lock.json` from your repo's `.gitignore`
file too - it's ignored in the kickstart repo to make maintenance easier, but
it's recommended to track it in version control (see `:help vim.pack-lockfile`).

#### Clone kickstart.nvim

> [!NOTE]
> If following the recommended step above (i.e., creating your own repo from
> the template or fork), replace `nvim-lua` with `<your_github_username>`
> in the commands below

<details><summary> Linux and Mac </summary>

```sh
git clone https://github.com/nvim-lua/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>

If you're using `cmd.exe`:

```
git clone https://github.com/nvim-lua/kickstart.nvim.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```
git clone https://github.com/nvim-lua/kickstart.nvim.git "${env:LOCALAPPDATA}\nvim"
```

</details>

### Post Installation

Start Neovim

```sh
nvim
```

That's it! `vim.pack` will install all the plugins from your config. Use
`:lua vim.pack.update(nil, { offline = true })` to inspect plugin state and
`:lua vim.pack.update()` to fetch updates (`:write` applies updates, `:quit`
cancels them).

#### Read The Friendly Documentation

Read through the `init.lua` file in your configuration folder for more
information about extending and exploring Neovim. That also includes
examples of adding popularly requested plugins.

> [!NOTE]
> For more information about a particular plugin check its repository's documentation.


### Getting Started

[The Only Video You Need to Get Started with Neovim](https://youtu.be/m8C0Cq9Uv9o)

### FAQ

* What should I do if I already have a pre-existing Neovim configuration?
  * You should back it up and then delete all associated files.
  * This includes your existing init.lua and the Neovim files in `~/.local`
    which can be deleted with `rm -rf ~/.local/share/nvim/`
* Can I keep my existing configuration in parallel to kickstart?
  * Yes! You can use [NVIM_APPNAME](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)`=nvim-NAME`
    to maintain multiple configurations. For example, you can install the kickstart
    configuration in `~/.config/nvim-kickstart` and create an alias:
    ```
    alias nvim-kickstart='NVIM_APPNAME="nvim-kickstart" nvim'
    ```
    When you run Neovim using `nvim-kickstart` alias it will use the alternative
    config directory and the matching local directory
    `~/.local/share/nvim-kickstart`. You can apply this approach to any Neovim
    distribution that you would like to try out.
* What if I want to "uninstall" this configuration:
  * Remove your config directory and local data directory (for example,
    `~/.config/nvim` and `~/.local/share/nvim`).
* Why is the kickstart `init.lua` a single file? Wouldn't it make sense to split it into multiple files?
  * The main purpose of kickstart is to serve as a teaching tool and a reference
    configuration that someone can easily use to `git clone` as a basis for their own.
    As you progress in learning Neovim and Lua, you might consider splitting `init.lua`
    into smaller parts. A fork of kickstart that does this while maintaining the
    same functionality is available here:
    * [kickstart-modular.nvim](https://github.com/dam9000/kickstart-modular.nvim)
  * Discussions on this topic can be found here:
    * [Restructure the configuration](https://github.com/nvim-lua/kickstart.nvim/issues/218)
    * [Reorganize init.lua into a multi-file setup](https://github.com/nvim-lua/kickstart.nvim/pull/473)

### Install Recipes

Below you can find OS specific install instructions for Neovim and dependencies.

After installing all the dependencies continue with the [Install Kickstart](#install-kickstart) step.

#### Windows Installation

<details><summary>Windows with Microsoft C++ Build Tools and CMake</summary>
Kickstart's default config is make-only for `telescope-fzf-native.nvim`.
If `make` is unavailable, the plugin is skipped.

Recommended: install `make` (see the chocolatey section below).

If you want a CMake-only setup, customize `init.lua` in two places:

1. Include `telescope-fzf-native.nvim` when `cmake` is available:

```lua
if vim.fn.executable 'make' == 1 or vim.fn.executable 'cmake' == 1 then
  table.insert(plugins, gh 'nvim-telescope/telescope-fzf-native.nvim')
end
```

2. In the `PackChanged` hook, use CMake when `make` is unavailable:

```lua
if name == 'telescope-fzf-native.nvim' then
  if vim.fn.executable 'make' == 1 then
    run_build(name, { 'make' }, ev.data.path)
  elseif vim.fn.executable 'cmake' == 1 then
    run_build(name, { 'cmake', '-S.', '-Bbuild', '-DCMAKE_BUILD_TYPE=Release' }, ev.data.path)
    run_build(name, { 'cmake', '--build', 'build', '--config', 'Release', '--target', 'install' }, ev.data.path)
  end
  return
end
```

See `telescope-fzf-native` documentation for [build details](https://github.com/nvim-telescope/telescope-fzf-native.nvim#installation).
</details>
<details><summary>Windows with gcc/make using chocolatey</summary>
Alternatively, one can install gcc and make which don't require changing the config,
the easiest way is to use choco:

1. install [chocolatey](https://chocolatey.org/install)
either follow the instructions on the page or use winget,
run in cmd as **admin**:
```
winget install --accept-source-agreements chocolatey.chocolatey
```

2. install all requirements using choco, exit the previous cmd and
open a new one so that choco path is set, and run in cmd as **admin**:
```
choco install -y neovim git ripgrep wget fd unzip gzip mingw make tree-sitter
```
</details>
<details><summary>WSL (Windows Subsystem for Linux)</summary>

```
wsl --install
wsl
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```
</details>

#### Linux Install
<details><summary>Ubuntu Install Steps</summary>

```
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip neovim
```
</details>
<details><summary>Debian Install Steps</summary>

```
sudo apt update
sudo apt install make gcc ripgrep fd-find tree-sitter-cli unzip git xclip curl

# Now we install nvim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo mkdir -p /opt/nvim-linux-x86_64
sudo chmod a+rX /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# make it available in /usr/local/bin, distro installs to /usr/bin
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/
```
</details>
<details><summary>Fedora Install Steps</summary>

```
sudo dnf install -y gcc make git ripgrep fd-find tree-sitter-cli unzip neovim
```
</details>

<details><summary>Arch Install Steps</summary>

```
sudo pacman -S --noconfirm --needed gcc make git ripgrep fd tree-sitter-cli unzip neovim
```
</details>

### Alternative neovim installation methods

For some systems it is not unexpected that the [package manager installation
method](https://github.com/neovim/neovim/blob/master/INSTALL.md#install-from-package)
recommended by neovim is significantly behind. If that is the case for you,
pick one of the following methods that are known to deliver fresh neovim versions very quickly.
They have been picked for their popularity and because they make installing and updating
neovim to the latest versions easy. You can also find more detail about the
available methods being discussed
[here](https://github.com/nvim-lua/kickstart.nvim/issues/1583).


<details><summary>Bob</summary>

[Bob](https://github.com/MordechaiHadad/bob) is a Neovim version manager for
all platforms. Simply install
[rustup](https://rust-lang.github.io/rustup/installation/other.html),
and run the following commands:

```bash
rustup default stable
rustup update stable
cargo install bob-nvim
bob use stable
```

</details>

<details><summary>Homebrew</summary>

[Homebrew](https://brew.sh) is a package manager popular on Mac and Linux.
Simply install using [`brew install`](https://formulae.brew.sh/formula/neovim).

</details>

<details><summary>Flatpak</summary>

Flatpak is a package manager for applications that allows developers to package their applications
just once to make it available on all Linux systems. Simply [install flatpak](https://flatpak.org/setup/)
and setup [flathub](https://flathub.org/setup) to [install neovim](https://flathub.org/apps/io.neovim.nvim).

</details>

<details><summary>asdf and mise-en-place</summary>

[asdf](https://asdf-vm.com/) and [mise](https://mise.jdx.dev/) are tool version managers,
mostly aimed towards project-specific tool versioning. However both support managing tools
globally in the user-space as well:

<details><summary>mise</summary>

[Install mise](https://mise.jdx.dev/getting-started.html), then run:

```bash
mise plugins install neovim
mise use neovim@stable
```

</details>

<details><summary>asdf</summary>

[Install asdf](https://asdf-vm.com/guide/getting-started.html), then run:

```bash
asdf plugin add neovim
asdf install neovim stable
asdf set neovim stable --home
asdf reshim neovim
```

</details>

</details>
