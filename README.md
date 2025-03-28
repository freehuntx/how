# how
A command-line tool that brings the power of GitHub Copilot to your terminal! Simply ask questions using the `how` command and get instant answers or executable commands.

## Features
- 🤖 Powered by GitHub Copilot
- 💡 Get instant answers to general questions
- 🔧 Receive executable shell commands for Linux/bash tasks
- 📋 Copy commands to clipboard or execute them directly
- 🔒 Secure GitHub authentication

## Dependencies
- [nodejs](https://nodejs.org/en/download)
- [xsel](https://github.com/kfish/xsel)

## Installation
```
curl -o- https://raw.githubusercontent.com/freehuntx/how/refs/heads/master/install.sh | bash
```

The script will:
- Install the required scripts to `~/.local/bin`
- Make the scripts executable
- Add the installation directory to your PATH
- Check for required dependencies

## Usage
Simply type `how` followed by your question:

```bash
# Get an answer to a general question
how what is docker

# Get a shell command
how list all running processes

# Get help with coding
how create a react component
```

When the tool provides a shell command, you can:
- Press `e` to execute the command directly
- Press `c` (or Enter) to copy the command to your clipboard

## Authentication
The first time you run the tool, it will guide you through the GitHub authentication process:

1. You'll be provided with a verification URL and code
2. Visit the URL in your browser
3. Enter the provided code
4. The tool will automatically complete the authentication

Your authentication token will be stored securely in `~/.config/copilot_token`.

## Examples
```bash
$ how check disk space
Command: df -h
[c]opy/[e]xecute [C]: e

Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       234G   89G  134G  40% /
...

$ how what is a symbolic link
A symbolic link (also known as a symlink or soft link) is a special type of file that points to another file or directory. It's like a shortcut or reference to the original file.

$ how create new user
Command: sudo useradd -m username
[c]opy/[e]xecute [C]: c
Copied!
```

## Contributing
Feel free to submit issues and enhancement requests!

## License
This project is licensed under the MIT License - see the LICENSE file for details.