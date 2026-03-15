#!/bin/bash

sudo apt install -y unzip

oh-my-posh font install

mkdir -p ~/.poshthemes

# Download and extract themes one liner
curl -s https://api.github.com/repos/JanDeDobbeleer/oh-my-posh/releases/latest \
  | grep "browser_download_url.*themes.zip" \
  | cut -d '"' -f 4 \
  | xargs curl -L -o ~/.poshthemes/themes.zip \
  && unzip ~/.poshthemes/themes.zip -d ~/.poshthemes \
  && rm ~/.poshthemes/themes.zip

# Add oh-my-posh to bashrc 
grep -q "oh-my-posh init bash" ~/.bashrc || \
  echo 'eval "$(oh-my-posh init bash --config ~/.poshthemes/clean-detailed.omp.json)"' >> ~/.bashrc

echo "Done! Run: source ~/.bashrc"
