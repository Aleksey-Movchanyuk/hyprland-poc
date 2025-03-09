Below is the `README.md` content formatted as a code snippet that you can copy and paste directly into a file:

```markdown
# Hyprland Proof of Concept (PoC)

This project is a proof of concept for running [Hyprland](https://hyprland.org/), a dynamic tiling Wayland compositor, inside a Docker container with VNC access via [WayVNC](https://github.com/any1/wayvnc). The goal is to create a lightweight, headless Wayland environment accessible remotely using a VNC client.

## Prerequisites

- **Docker**: Ensure Docker is installed on your system. On macOS, use [Docker Desktop](https://www.docker.com/products/docker-desktop/). On Linux, install Docker via your package manager (e.g., `apt`, `pacman`, `dnf`).
- **VNC Client**: Install a VNC client like [TigerVNC](https://tigervnc.org/), [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/), or any other VNC-compatible client to connect to the container.
- **Operating System**: This setup is designed for Linux hosts but includes instructions for macOS with caveats (see [Notes for macOS](#notes-for-macos)).

## Project Structure

- `Dockerfile`: Defines the container image with Hyprland, WayVNC, and dependencies.
- `README.md`: This file with instructions and notes.

## Building the Container

1. **Clone or Create the Project Directory**:
   - If this is part of a repository, clone it:
     ```bash
     git clone <repository-url>
     cd hyprland-poc
     ```
   - Otherwise, create a directory and place the `Dockerfile` inside:
     ```bash
     mkdir hyprland-poc
     cd hyprland-poc
     # Copy or create the Dockerfile here
     ```

2. **Build the Docker Image**:
   - Run the following command to build the image using the `Dockerfile`:
     ```bash
     docker build -t arch-hyprland .
     ```
   - This command:
     - Uses the `archlinux:latest` base image.
     - Installs Hyprland, WayVNC, and all required dependencies.
     - Configures a non-root user and sets up runtime directories.
     - Takes a few minutes depending on your internet speed and system performance.

## Running the Container

1. **Run the Container**:
   - Start the container and map port 5900 (VNC) to your host:
     ```bash
     docker run --rm -it -p 5900:5900 arch-hyprland
     ```
   - `--rm`: Removes the container after it stops.
   - `-it`: Runs interactively with a terminal.
   - `-p 5900:5900`: Maps the container’s VNC port (5900) to your host’s port 5900.

2. **Expected Output**:
   - The container will:
     - Set up runtime directories.
     - Start Hyprland with a D-Bus session.
     - Wait for the Wayland socket (`/run/user/1000/wayland-0`) to be created.
     - Start WayVNC to provide VNC access.
   - If successful, you’ll see:
     ```
     Ensuring runtime directories exist...
     Starting Hyprland with D-Bus session...
     Waiting for Wayland socket...
     Wayland socket found!
     Starting WayVNC...
     Startup complete!
     ```
   - If it fails, debug logs will be printed (see [Troubleshooting](#troubleshooting)).

3. **Connect Using a VNC Client**:
   - Open your VNC client and connect to:
     - **Host**: `localhost` (or `127.0.0.1`)
     - **Port**: `5900`
   - If running on a remote Linux host or VM, use the host’s IP address (e.g., `<vm-ip>:5900`).

## Notes for macOS

Running this container on macOS via Docker Desktop is challenging due to the VM environment used by Docker Desktop. Key limitations include:

- **Wayland Backend Issues**: Hyprland’s headless backend may fail with errors like `CBackend::create() failed!` due to missing GPU device access (e.g., `/dev/dri`) or incomplete Wayland support in the VM.
- **Reliability**: While the container may build successfully, runtime issues are common on macOS.

For reliable operation, consider running on a native Linux host (see [Running on a Native Linux Host](#running-on-a-native-linux-host)).

## Troubleshooting

If the container fails to start or you cannot connect via VNC:

1. **Check Logs**:
   - Look at the output after running the container. If Hyprland fails, you’ll see:
     ```
     Error: Wayland socket not found after 10 seconds!
     Hyprland logs:
     <detailed logs here>
     ```
   - Common issues:
     - **Missing Dependencies**: Logs may indicate a missing library (e.g., `cannot find libXYZ`).
     - **Backend Failure**: `CBackend::create() failed!` suggests a problem with the headless backend, often due to the Docker environment.

2. **Run Interactively**:
   - Start the container with a shell to debug manually:
     ```bash
     docker run --rm -it -p 5900:5900 arch-hyprland /bin/bash
     ```
   - Then run Hyprland manually:
     ```bash
     export XDG_RUNTIME_DIR=/run/user/1000
     export WAYLAND_DISPLAY=wayland-0
     export WLR_BACKENDS=headless
     export WLR_LIBINPUT_NO_DEVICES=1
     dbus-launch --exit-with-session hyprland
     ```

3. **Try Privileged Mode (macOS Only)**:
   - As a temporary workaround, run in privileged mode to bypass security restrictions:
     ```bash
     docker run --rm -it --privileged -p 5900:5900 arch-hyprland
     ```
   - **Note**: This is insecure and for debugging only.

4. **Review VNC Issues**:
   - If Hyprland starts but WayVNC fails, check for protocol mismatch errors (e.g., `Screencopy protocol not supported`). This may require adjusting WayVNC or using a different VNC server.

## Running on a Native Linux Host

For best results, run this container on a native Linux host, as Docker Desktop on macOS introduces compatibility issues with Wayland compositors.

### Option 1: Linux VM on macOS (Using UTM)

1. **Install UTM**:
   - Download from [https://mac.getutm.app/](https://mac.getutm.app/) and install.

2. **Create a VM**:
   - Download the Ubuntu 24.04 LTS ISO from [https://ubuntu.com/download/desktop](https://ubuntu.com/download/desktop).
   - In UTM, create a new VM:
     - Select "Virtualize" > "Linux".
     - Choose the Ubuntu ISO.
     - Allocate 2 CPUs, 4GB RAM, 20GB disk.
   - Install Ubuntu following the prompts.

3. **Install Docker**:
   - In the VM terminal:
     ```bash
     sudo apt update
     sudo apt install -y docker.io
     sudo systemctl enable --now docker
     sudo usermod -aG docker $USER
     ```
   - Log out and back in.

4. **Transfer the Dockerfile**:
   - Copy the `Dockerfile` to the VM (e.g., via a shared folder or `scp`):
     ```bash
     scp Dockerfile user@<vm-ip>:/home/user/
     ```

5. **Build and Run**:
   - In the VM:
     ```bash
     docker build -t arch-hyprland .
     docker run --rm -it -p 5900:5900 --device=/dev/dri arch-hyprland
     ```

6. **Connect**:
   - Use a VNC client on macOS to connect to `<vm-ip>:5900`.

### Option 2: Cloud-Based Linux Host

1. **Set Up an Instance**:
   - Use a provider like DigitalOcean, AWS EC2, or Google Cloud.
   - Launch a small Ubuntu instance (e.g., $5/month Droplet).

2. **Install Docker**:
   - SSH into the instance:
     ```bash
     sudo apt update
     sudo apt install -y docker.io
     sudo systemctl enable --now docker
     sudo usermod -aG docker $USER
     ```

3. **Transfer the Dockerfile**:
   - Use `scp`:
     ```bash
     scp -i <your-key.pem> Dockerfile user@<cloud-ip>:/home/user/
     ```

4. **Build and Run**:
   - SSH into the instance:
     ```bash
     docker build -t arch-hyprland .
     docker run --rm -it -p 5900:5900 --device=/dev/dri arch-hyprland
     ```

5. **Connect**:
   - Open port 5900 in the cloud provider’s firewall.
   - Use a VNC client on macOS to connect to `<cloud-ip>:5900`.

## Contributing

If you encounter issues or improve the setup:
- Open an issue or pull request if this is part of a repository.
- Share detailed logs and system information to help debug.

## License

This project is unlicensed and provided as-is for experimental purposes.
```

### How to Use

1. Copy the entire content above.
2. Open a text editor (e.g., VS Code, Sublime Text, or `nano`).
3. Paste the content into a new file.
4. Save it as `README.md` in your `hyprland-poc` directory.
5. Verify the file exists:
   ```bash
   ls -l README.md
   ```

This `README.md` is now ready for your project and provides clear, copy-pasteable instructions for building and running the container. Let me know if you need any adjustments!