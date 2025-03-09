FROM archlinux:latest

# Set environment variables
ENV USER=user
ENV XDG_RUNTIME_DIR=/run/user/1000
ENV WAYLAND_DISPLAY=wayland-0
ENV WLR_BACKENDS=headless
ENV WLR_LIBINPUT_NO_DEVICES=1

# Install all possible dependencies for hyprland and wayvnc, including seatd
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    dbus \
    sudo \
    wayland \
    wayland-protocols \
    xorg-xwayland \
    hyprland \
    polkit \
    wlroots \
    pipewire \
    pipewire-pulse \
    wayvnc \
    xdg-utils \
    bash \
    nano \
    libdrm \
    libinput \
    libxkbcommon \
    pixman \
    mesa \
    seatd \
    libegl \
    libgles \
    libglvnd \
    libcap \
    libpng \
    ffmpeg \
    libva \
    cairo \
    pango \
    gdk-pixbuf2

# Create non-root user
RUN useradd -m -u 1000 -G wheel $USER && \
    echo "$USER:$USER" | chpasswd && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel && \
    mkdir -p /home/$USER/.config/hypr && \
    mkdir -p /home/$USER/.config/wayvnc && \
    chown -R $USER:$USER /home/$USER

# Setup runtime directories during build (as root)
RUN mkdir -p /run/user/1000 && \
    chmod 700 /run/user/1000 && \
    chown -R $USER:$USER /run/user/1000 && \
    # Setup crash report directory
    mkdir -p /var/crash && \
    chmod 777 /var/crash && \
    # Setup seatd socket directory
    mkdir -p /run/seatd && \
    chmod 777 /run/seatd

# Hyprland configuration with debug logging enabled
RUN echo "debug {" > /home/$USER/.config/hypr/hyprland.conf && \
    echo "    disable_logs = false" >> /home/$USER/.config/hypr/hyprland.conf && \
    echo "    enable_stdout_logs = true" >> /home/$USER/.config/hypr/hyprland.conf && \
    echo "}" >> /home/$USER/.config/hypr/hyprland.conf && \
    chown user:user /home/$USER/.config/hypr/hyprland.conf

# WayVNC configuration
RUN echo "[server]" > /home/$USER/.config/wayvnc/config.ini && \
    echo "address = 0.0.0.0" >> /home/$USER/.config/wayvnc/config.ini && \
    echo "port = 5900" >> /home/$USER/.config/wayvnc/config.ini && \
    echo "enable_auth = false" >> /home/$USER/.config/wayvnc/config.ini

# Startup script (start seatd with sudo)
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'export XDG_RUNTIME_DIR=/run/user/1000' >> /start.sh && \
    echo 'export WAYLAND_DISPLAY=wayland-0' >> /start.sh && \
    echo 'export WLR_BACKENDS=headless' >> /start.sh && \
    echo 'export WLR_LIBINPUT_NO_DEVICES=1' >> /start.sh && \
    echo 'echo "Ensuring runtime directories exist..."' >> /start.sh && \
    echo 'mkdir -p /run/user/1000' >> /start.sh && \
    echo 'chmod 700 /run/user/1000' >> /start.sh && \
    echo 'chown -R user:user /run/user/1000' >> /start.sh && \
    echo 'echo "Starting seatd..."' >> /start.sh && \
    echo 'sudo seatd -u user &' >> /start.sh && \
    echo 'sleep 1' >> /start.sh && \
    echo 'echo "Starting Hyprland with D-Bus session..."' >> /start.sh && \
    echo 'sudo -u user bash -c "XDG_RUNTIME_DIR=/run/user/1000 dbus-launch --exit-with-session hyprland > /tmp/hyprland.log 2>&1 &"' >> /start.sh && \
    echo 'echo "Waiting for Wayland socket..."' >> /start.sh && \
    echo 'for i in {1..10}; do' >> /start.sh && \
    echo '    if [ -S /run/user/1000/wayland-0 ]; then' >> /start.sh && \
    echo '        echo "Wayland socket found!"' >> /start.sh && \
    echo '        break' >> /start.sh && \
    echo '    fi' >> /start.sh && \
    echo '    echo "Waiting for Wayland socket... ($i/10)"' >> /start.sh && \
    echo '    sleep 1' >> /start.sh && \
    echo 'done' >> /start.sh && \
    echo 'if [ ! -S /run/user/1000/wayland-0 ]; then' >> /start.sh && \
    echo '    echo "Error: Wayland socket not found after 10 seconds!"' >> /start.sh && \
    echo '    echo "Hyprland logs:"' >> /start.sh && \
    echo '    cat /tmp/hyprland.log' >> /start.sh && \
    echo '    exit 1' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'echo "Starting WayVNC..."' >> /start.sh && \
    echo 'sudo -u user bash -c "XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 wayvnc -L debug 0.0.0.0 5900"' >> /start.sh && \
    echo 'echo "Startup complete!"' >> /start.sh && \
    chmod +x /start.sh

EXPOSE 5900
WORKDIR /home/user
USER user
CMD ["/start.sh"]