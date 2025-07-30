#!/bin/bash

set -e

# Prepares a concourse task to sign git commits. To use this script, be sure the below environment
# variables are set then source this script in your task before attempting to commit:
#
#`source pipeline-tasks/setup-commit-signing.sh`
# 
# The script "unlocks" the gpg key using the passphrase for 2 minutes. Therefore, you should source 
# this script right before committing to prevent timing out (ie do your work first). 
if [[ -z "$GH_SSH_PRIVATE_KEY" ]] || [[ -z "$GPG_PUBLIC_KEY" ]] || [[ -z "$GPG_PRIVATE_KEY" ]] || [[ -z "$GPG_USERNAME" ]] || [[ -z "$GPG_EMAIL" ]] || [[ -z "$GPG_PASSPHRASE" ]]; then
  cat <<EOF

Missing required environment variable(s). Please be sure the following are set:

  GH_SSH_PRIVATE_KEY: The private key of the bot using to commit to git. 
  GPG_PUBLIC_KEY: The gpg public key for the bot to use to sign commits. This must be configured in GitHub for it to verify the signing.
  GPG_PRIVATE_KEY: The gpg private key for the bot to use to sign commits.
  GPG_USERNAME: The git username which will be used to sign commits. 
  GPG_EMAIL: The email used to sign commit. This must be configured in GitHub for it to verify the signing.
  GPG_PASSPHRASE: The passphrase for the gpg key. 
EOF
  exit 1
fi

# setup the private key so you can do git related things (fetch, pull, etc)
echo "$GH_SSH_PRIVATE_KEY" > ssh.key
chmod 600 ssh.key
eval "$(ssh-agent -s)"
ssh-add ssh.key
rm ssh.key
mkdir -p ~/.ssh
ssh-keyscan -t rsa -H github.com >> ~/.ssh/known_hosts 

export GPG_TTY=$(tty)

# setup the gpg-agent to allow presetting a password and enable caching
mkdir -p ~/.gnupg
echo "allow-preset-passphrase" > ~/.gnupg/gpg-agent.conf
echo "default-cache-ttl 120" >> ~/.gnupg/gpg-agent.conf
echo "max-cache-ttl 240" >> ~/.gnupg/gpg-agent.conf

chown -R $(whoami) ~/.gnupg
find ~/.gnupg -type d -exec chmod 700 {} \;
find ~/.gnupg -type f -exec chmod 600 {} \;

echo "gpg agent config updated"

gpgconf --reload gpg-agent

echo "$GPG_PUBLIC_KEY" > public.key
gpg --import public.key
rm public.key
echo "Public key imported"

echo "$GPG_PRIVATE_KEY" > private.key
gpg --import --batch private.key
rm private.key
echo "Private key imported"

secret_keys=$(gpg --list-secret-keys --with-colons "$GPG_USERNAME <$GPG_EMAIL>")

# labeled as "fpr" 
gpg_fingerprint=$(echo "$secret_keys" | grep "fpr:" | head -n 1 | awk -F "fpr:*" '{print $2}' | awk -F ":" '{print $1}')
echo "${gpg_fingerprint}:6:" > ownertrust.txt
gpg --import-ownertrust < ownertrust.txt
rm ownertrust.txt
echo "Ownertrust updated"

gpg_secret_keyline=$(echo "$secret_keys" | grep "sec")

IFS=":" read -ra gpg_secret_key_details <<< "$gpg_secret_keyline"
gpg_secret_keyid="${gpg_secret_key_details[5]}"
# git setup
git config --global user.email "$GPG_EMAIL"
git config --global user.name "$GPG_USERNAME"
git config --global commit.gpgSign true
echo "Git configured"

# labeled as "grp"
gpg_keygrip=$(echo "$secret_keys" | grep "grp:" | head -n 1 | awk -F "grp:*" '{print $2}' | awk -F ":" '{print $1}')

/usr/lib/gnupg2/gpg-preset-passphrase -c $gpg_keygrip <<< $GPG_PASSPHRASE
echo "Passphrase preset"