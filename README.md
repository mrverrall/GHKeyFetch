# GHKeyFetch

**GHKeyFetch** is a flexible Bash script designed to securely fetch and manage SSH public keys from a specified GitHub user. It allows you to update your `authorized_keys` file by either adding new keys or replacing existing ones, with options for quiet, default, and verbose modes.

## Features

- **Fetch Public SSH Keys**: Automatically download public SSH keys from any GitHub user profile.
- **Add or Replace Keys**: Choose to append new keys to the existing `authorized_keys` file or replace the entire file.
- **Deduplication**: Automatically removes duplicate keys when adding new keys.
- **Flexible Output**:
  - **Default Mode**: Outputs the number of keys added.
  - **Quiet Mode**: Suppresses all output, returning only exit codes.
  - **Verbose Mode**: Provides detailed step-by-step output for debugging or monitoring purposes.
- **Secure Temporary File Handling**: Ensures all temporary files are securely managed and cleaned up after execution.
- **Exit Codes**: Returns `0` on success and `1` on failure, suitable for use in automated systems.

## Requirements

- Bash
- `curl` or `wget` installed on your system

## Installation

Clone this repository to your local machine:

```bash
git clone https://github.com/yourusername/GHKeyFetch.git
cd GHKeyFetch
```

Make the script executable:

```bash
chmod +x ghkeyfetch.sh
```

## Usage

Run the script with the desired options:

```bash
./ghkeyfetch.sh <github-username> [-c|--confirm] [-a|--add] [-q|--quiet] [-v|--verbose]
```

### Options

- `<github-username>`: The GitHub username to fetch the public keys from.
- `-c, --confirm`: Confirm and execute the update to the `authorized_keys` file.
- `-a, --add`: Add the fetched keys to the existing `authorized_keys` file, rather than replacing it.
- `-q, --quiet`: Run the script in quiet mode, suppressing all output.
- `-v, --verbose`: Run the script in verbose mode, providing detailed output.

### Examples

- **Replace Existing Keys**:
  ```bash
  ./ghkeyfetch.sh octocat -c
  ```

- **Add New Keys to Existing File and Remove Duplicates**:
  ```bash
  ./ghkeyfetch.sh octocat -c -a
  ```

- **Run in Quiet Mode (No Output)**:
  ```bash
  ./ghkeyfetch.sh octocat -c -q
  ```

- **Run in Verbose Mode (Detailed Output)**:
  ```bash
  ./ghkeyfetch.sh octocat -c -v
  ```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request if you have suggestions or improvements.

## Acknowledgments

This script was inspired by the need to efficiently manage SSH keys from GitHub across multiple servers and environments. Thank you to the open-source community for providing the tools and inspiration to create this utility.
