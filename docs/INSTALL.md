# Getting Started with Valdi

This guide will help you set up your development environment and get started with your first project.

## Prerequisites

Before you begin, ensure you have the necessary system dependencies installed:

- [MacOS Setup Guide](./setup/macos_setup.md)
- [Linux Setup Guide](./setup/linux_setup.md)

> [!IMPORTANT]
> Installing these dependencies is required. Without them, you may encounter errors during setup and development.

## Installation Steps

### 1. Clone the Repository

```bash
git clone git@github.com:Snapchat/Valdi.git
```

### 2. Install Valdi CLI

Navigate to the CLI directory and install the command-line tools:

```bash
cd Valdi/npm_modules/cli/

# This next command will install the valdi command line tool
npm run cli:install

# Set up the development environment
valdi dev_setup
```

## Creating Your First Project

The best way to start a new project is to bootstrap it using the Valdi CLI. The bootstrap command will create all of the necessary directories, source, and configuration files.

### 1. Bootstrap a New Project

```bash
# Create and enter your project directory
mkdir my_project
cd my_project

# Initialize a new Valdi project
valdi bootstrap
```

This will create all necessary files for a new Valdi project in your current directory.

### 2. Run Your Project

Choose your target platform and install dependencies:

```bash
# For iOS
valdi install ios

# For Android
valdi install android
```

> [!NOTE]
> The first build may take several minutes as it sets up the development environment.

### 3. Enable Hot Reloading

Once your app is running in a simulator or emulator, start the hot reloader to see your changes in real-time:

```bash
valdi hotreload
```

## Development Environment Setup

### VSCode Configuration

1. **Install VSCode**

   - Download and install [VSCode](https://code.visualstudio.com/download)
   - Launch VSCode
   - Open Command Palette (Cmd+Shift+P)
   - Type `shell command` and select `> Install 'code' command in PATH`
   - Restart your terminal

2. **Install Valdi Extension**

   ```bash
   scripts/vscode/install_extensions.sh
   ```

3. **Configure TypeScript**
   - Open any TypeScript file (.tsx)
   - Press `Cmd+Shift+P`
   - Select "TypeScript: Select TypeScript Version..."
   - Choose `Use Workspace Version`

> [!IMPORTANT]
> The TypeScript version configuration is crucial for proper development and cannot be automated.

## Project Synchronization

When you make changes to any of the following:

- Dependencies
- Localization files
- Resource files

Run this command to update your project configuration:

```bash
valdi projectsync
```

## Next Steps

Ready to start building? Check out:

- [Getting Started Codelab](https://github.com/Snapchat/Valdi/blob/main/docs/codelabs/getting_started/1-introduction.md)
- [Documentation](https://github.com/Snapchat/Valdi/tree/main/docs#the-basics)

## Need Help?

Join our [Discord community](https://discord.gg/VSUjDddRt3) for support and discussions.
