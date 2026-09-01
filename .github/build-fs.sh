#!/usr/bin/env bash
# prototype: build a project offline from a mounted squashfs nix store
# instead of an extracted OCI image. runs nix as root (single-user model,
# same as the seed container).
set -eux -o pipefail

cache=$1        # dir containing store.squashfs + registration
src=${2:-.}

# read-only baked store (squashfs) unioned with a writable overlay ->
# /nix/store. no extraction: mount is O(1), reads decompress lazily.
sudo mkdir -p /nix/.ro-store /nix/.rw/upper /nix/.rw/work /nix/store /nix/var/nix
echo "::group::mount"
time sudo mount -t squashfs -o loop,ro "$cache/store.squashfs" /nix/.ro-store
sudo mount -t overlay overlay \
  -o lowerdir=/nix/.ro-store,upperdir=/nix/.rw/upper,workdir=/nix/.rw/work \
  /nix/store
echo "::endgroup::"

# nix comes from the mounted store; register the baked closure as valid
nixdir=$(dirname "$(ls /nix/store/*/bin/nix | head -1)")
sudo "$nixdir/nix-store" --load-db <"$cache/registration"

# nix runs as root, /src is the runner-owned checkout -> mark it safe
printf '[safe]\n\tdirectory = *\n' | sudo tee -a /etc/gitconfig >/dev/null

conf=$'experimental-features = nix-command flakes\nsubstituters =\nbuild-users-group =\nsandbox = false'
echo "::group::build"
time sudo env HOME=/tmp NIX_CONFIG="$conf" \
  "$nixdir/nix" build --offline --no-link --print-out-paths "$src"
echo "::endgroup::"
