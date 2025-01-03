# Kumander

Kumander is a powerful command-line tool for organizing and executing your frequently used commands. It allows you to:

- Store commands in easy-to-read markdown files
- List available command sets and individual commands
- Execute stored commands with simple syntax
- Customize your command directory
- Automatically generate command completions for Bash and Zsh

Kumander streamlines your workflow by turning complex, hard-to-remember commands into simple, intuitive actions. Perfect for developers, system administrators, and power users who want to boost their productivity at the command line.

![Usage](assets/usage.gif)

## Installation

### Quick Install

You can install Kumander directly using curl:

```bash
curl -o- https://raw.githubusercontent.com/christopheredrian/kumander/main/install.sh | bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/christopheredrian/kumander/main/install.sh | bash
```

This will install kumander to your ~/.kumander directory and add the necessary configuration to your shell configuration file.

## Removing Kumander

> **Warning**
> This will remove all your commands and the Kumander directory as well, use with caution. Recommend to backup your ~/.kumander/commands before removing.
 
```bash
rm -rf ~/.kumander
```

Then on your shell configuration file (e.g. ~/.bashrc, ~/.zshrc, or ~/.bash_profile), remove the following lines:

```bash
# Kumander Configuration
export KUMANDER_COMMANDS_DIR="$HOME/.kumander/commands"
alias km='kumander'
source $HOME/.kumander/kumander.sh
```

## Usage

```bash
kumander [file] [command]

# or using the alias
km [file] [command]
```

Options:
- `--help`: Show the help message
- `--dir <path>`: Specify a custom commands directory

Examples:
- List all available files: `./kumander`
- List commands in a file: `./kumander git`
- Execute a command: `./kumander git push`

## Configuration

By default, Kumander looks for command files in the `commands` directory. You can customize this by setting the `KUMANDER_COMMANDS_DIR` environment variable or using the `--dir` option  (for temporary use).

## Creating Command Files

Open the commands directory: `~/.kumander/commands` e.g. `code ~/.kumander/commands`

Create markdown files in your commands directory with the following structure (defaults to ~/.kumander/commands):

For example, create a file called `my-commands.md` and add the following content:

```markdown
# Listing commands 

## ls-home
Command description

```bash
ls -la ~
```

To run the command: `km my-commands ls-home`

## Contributing

To contribute to this project, please follow these steps:
1. Fork the repository
2. Create a new branch for your changes
3. Make your changes and commit them
4. Push your changes to your forked repository
5. Create a pull request to the original repository
6. Wait for the pull request to be reviewed and merged
7. Your changes will be available in the original repository

## License

GNU General Public License (GPL)


## Contact

Contact me at christopheredrian@trenchapps.com