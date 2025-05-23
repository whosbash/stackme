<p align="center">
  <img src="https://github.com/whosbash/stackme/blob/main/assets/images/stackme_tiny.png" alt="stackme" />
</p>

StackMe is a comprehensive shell script designed to manage Docker Swarm deployments. It includes a variety of functions to handle tasks such as error handling, color and style definitions, JSON parsing, email sending, Docker operations, and more.

## Features

- **Error Handling and Logging**: Robust error handling and logging mechanisms;
- **Color and Style Definitions**: Consistent use of colors and text styles for better readability;
- **Utility Functions**: JSON decoding, base64 decoding, random string generation, masking strings, sending emails, and more;
- **Docker Management**: Check Docker Swarm status, deploy stacks, list services, and manage Docker networks;
- **SMTP Email Testing**: Configure and send test emails using the `swaks` tool;
- **Configuration Management**: Generate and validate configurations for various services like Traefik, Portainer, Redis, Postgres, n8n and others;
- **User Interaction**: Prompt the user for input, collect and validate information, and display messages with formatted text.

## Prerequisites

- Docker
- Python 3
- Bash
- Tool `swaks` for SMTP email testing

## Installation

1. Clone the repository:
    ```bash
    git clone https://github.com/whosbash/stackme.git
    cd stackme
    ```

2. Make the script executable:
    ```bash
    chmod +x stackme.sh
    ```

## Usage

### Command-Line Options

- `-a, --arrow`: Choose the application arrow.
- `-h, --help` : Display the help message and exit.

### Examples

**Change the default arrow:**
    ```bash
    ./stackme.sh --arrow 'diamond' 
    ```

### Main Menu

The script will display a main menu where you can choose the stack to install. Navigate through the options to select the desired stack.

```bash
./stackme.sh
```

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your improvements.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## To do

Take a look at [these stacks](https://github.com/awesome-selfhosted/awesome-selfhosted) and be creative.

## Acknowledgments

- Inspired by [SetupOrion](https://github.com/oriondesign2015/SetupOrion).
- Thanks to all contributors and users for their support.

---

*Happy coding and stay curious!*
