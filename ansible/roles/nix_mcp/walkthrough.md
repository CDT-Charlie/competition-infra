# Gemini CLI Service Installation Walkthrough

The `nix_mcp` Ansible role has been successfully augmented to automatically install the Gemini CLI as an interactive daemon using `tmux` and configure it to connect to your standalone MCP server.

Here is a full breakdown of the changes and how you can interact with the system once Ansible provisions it.

## 1. Ansible Files Added

The following files were created in `ansible/roles/nix_mcp`:

- **[NEW] `tasks/gemini_cli.yml`**: Houses the tasks to pull in Node.js 20.x, install `tmux`, globally install `@google/gemini-cli`, deploy the templates, and register the `systemd` service.
- **[MODIFIED] `tasks/main.yml`**: Appended a single line `import_tasks: gemini_cli.yml` at the bottom to execute the new task block.
- **[NEW] `templates/ref-review.service.j2`**: A systemd unit descriptor that wraps `gemini` in a detached `tmux` session.
- **[NEW] `templates/gemini.env.j2`**: A template holding `GEMINI_API_KEY`.
- **[NEW] `templates/gemini-settings.json.j2`**: A configuration file enabling `gemini` CLI to attach to your local server script.

## 2. Deployed Files on the Target

Once Ansible is run, the following elements will exist on your target Ubuntu 20.04 machines:

| Component | Target Path | Description |
| :--- | :--- | :--- |
| **API Keys `.env`** | `/etc/default/ref-review-gemini` | Insert your Gemini API Key here (or configure via Ansible `gemini_api_key`) |
| **MCP Config** | `~/.gemini/settings.json` | Contains the MCP pointer for `/opt/ref_review_mcp/run-ref-review-mcp.sh`. Stored under the configured `ssh_home`. |
| **Systemd Service** | `/etc/systemd/system/ref-review.service` | The unit file managing the tmux daemon process. |
| **Executables** | `/usr/bin/gemini`<br>`/usr/bin/node` | Latest Gemini CLI via globally installed NodeSource Node v20. |

> [!TIP]
> Make sure `GEMINI_API_KEY` is fully populated. If you didn't pass it into your Ansible variables, you must log into the target machine, edit `/etc/default/ref-review-gemini` by adding the key string, and then restart the service.

## 3. Interact With the Service (CLI Cmds)

Because we used **Option A (tmux)**, the daemon runs continuously but isn't just sending text into the void. You can actually attach to the terminal and chat with it locally on the server.

### System Service Commands
To manage the lifecycle of the wrapper session on the Ubuntu terminal:
```bash
# View if the service is running and healthy
sudo systemctl status ref-review

# Restart the service (useful after updating the API Key in the .env file)
sudo systemctl restart ref-review

# Stop the service entirely
sudo systemctl stop ref-review
```

### Interacting with Gemini via tmux
To actually "talk" to Gemini and utilize the MCP, SSH into the machine as the user (`greyteam@lakeplacid.local` according to `defaults/main.yml`), and simply attach to the background tmux session:
```bash
# Attach to the background interactive shell
tmux attach -t gemini
```

> [!CAUTION]
> **To exit the TUI interface, DO NOT TYPE `exit` or `Ctrl+C`**. Doing so acts as a quit command inside `gemini` or terminates the shell script. If that happens, systemd will notice it stopped and restart a fresh session immediately.
> 
> **To detach and keep it running in the background**: Press `Ctrl+B`, then release, and press `D`.


Here is exactly what happens with the current code when the machine boots:

systemd spins up the ref-review service.
The service starts a background tmux process which executes the gemini CLI.
As the gemini CLI initializes, it reads the ~/.gemini/settings.json file we configured via Ansible.
The CLI sees the mcpServers block and automatically spawns /opt/ref_review_mcp/run-ref-review-mcp.sh as a child process in the background.
That bash script natively loads the mcp virtual environment and executes ref_review_mcp.py.
Because of this, the virtual environment and the MCP server are strictly tied to the service. If the ref-review service crashes or restarts, the Gemini CLI stops, which cleanly terminates the Python MCP server. When it boots back up, it automatically starts a fresh instance of the MCP python script with it.