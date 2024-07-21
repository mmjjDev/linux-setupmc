#!/bin/bash

# Function to download the Minecraft server jar
download_server() {
  local version=$1
  local modloader=$2
  local url=""

  case $modloader in
    vanilla)
      url="https://launcher.mojang.com/v1/objects/$(curl -s https://launchermeta.mojang.com/mc/game/version_manifest.json | jq -r --arg version "$version" '.versions[] | select(.id == $version) | .url' | xargs curl -s | jq -r '.downloads.server.url')"
      ;;
    fabric)
      url="https://meta.fabricmc.net/v2/versions/loader/${version}/0.14.21/0.11.2/server/jar"
      ;;
    forge)
      forge_version=$(curl -s https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json | jq -r --arg version "$version" '.promos[$version + "-recommended"]')
      url="https://maven.minecraftforge.net/net/minecraftforge/forge/${version}-${forge_version}/forge-${version}-${forge_version}-installer.jar"
      ;;
    *)
      echo "Invalid modloader option"
      exit 1
      ;;
  esac

  wget -O ~/minecraft/server.jar "$url"
}

# Ensure necessary packages are installed
echo "Ensuring necessary packages are installed..."
sudo apt update
sudo apt install -y jq wget screen openjdk-17-jre-headless

# Ask the user for the Minecraft version and modloader
echo "What Minecraft version are you willing to host? (e.g., 1.20.1)"
read version

echo "Which modloader do you want to use? (vanilla, fabric, forge)"
read modloader

# Create the minecraft directory if it doesn't exist
mkdir -p ~/minecraft

# Download the server file
echo "Downloading the server file for Minecraft $version with $modloader modloader..."
download_server "$version" "$modloader"

# Accept the EULA
echo "eula=true" > ~/minecraft/eula.txt

# Step 1: Create the start script
echo "Creating start script..."
cat << 'EOF' > ~/start
#!/bin/bash
cd ~/minecraft
screen -dmS minecraft java -Xmx16384M -jar server.jar nogui
screen -r minecraft
EOF

# Make the start script executable
chmod +x ~/start

# Step 2: Add the start script to PATH
echo "Adding start script to PATH..."
if ! grep -q 'export PATH="$PATH:$HOME"' ~/.bashrc; then
  echo 'export PATH="$PATH:$HOME"' >> ~/.bashrc
fi

# Step 3: Add the reconnect alias
echo "Adding reconnect alias..."
if ! grep -q "alias reconnect='screen -r minecraft'" ~/.bashrc; then
  echo "alias reconnect='screen -r minecraft'" >> ~/.bashrc
fi

# Reload the shell profile
echo "Reloading shell profile..."
source ~/.bashrc

echo "Setup complete. You can now use the 'start' and 'reconnect' commands."