To set up Rust and Cargo locally on a Linux system, follow these steps:
## 1. Update Your System (Optional but recommended)

Before installing anything, it's a good idea to update your system packages:

#### sudo apt update
#### sudo apt upgrade

## 2. Install Rust Using rustup

The easiest way to install Rust and Cargo (the Rust package manager and build tool) is by using the official tool called rustup.

    Open a terminal and run the following command to download and install rustup:

#### curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

This will download a script and install rustup. This tool will manage Rust versions and install both Rust and Cargo.

    After the installation completes, you'll see a message instructing you to add Rust to your system's PATH. Usually, the installer will ask you to run this command:

#### source $HOME/.cargo/env

To make this change permanent, you can add the command to your shell's configuration file. If you're using Bash, open your .bashrc file:

#### nano ~/.bashrc

Then, add the following line at the end of the file:

#### source $HOME/.cargo/env

Save and close the file by pressing Ctrl + X, then Y, and finally Enter.

To apply the changes, run:

#### source ~/.bashrc

## 3. Verify the Installation

To verify that Rust and Cargo were installed correctly, run the following commands:

#### rustc --version
#### cargo --version
