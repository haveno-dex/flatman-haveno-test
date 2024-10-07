# Haveno Sample Build

This README provides instructions for setting up a `flat-manager` server for your Haveno instance Flatpaks using Docker. You should clone this repo on the machine you intend to host the repository on.

## Setup Instructions

### Edit Configuration Files

> If you're setting up a new Haveno instance, you may want to edit some strings from this example. You can automate this with `sed`:
>
> ```bash
> find . -type f -exec sed -i 's/exchange.haveno.Haveno/YOUR_ID_HERE/g' {} +
> find . -type f -exec sed -i 's|http://localhost:8080|your-url-here|g' {} +
> ```
>
> This will also change the string in the README. **Ensure that you have changed the ID and the `bind`ed folder in your Haveno builds too, otherwise users won't be able to install your application.**

1. Rename `sample.config.json` to `config.json`

2. Complete the todos in the project:
   - [ ] **Generate a GPG Key:**
     Create a GPG key with `./.gpg` as the gpg home directory. You can use [gpgkey.sh](./gpgkey.sh), but it's recommended to fill in the information manually.
   - [ ] **Update `config.json`:**
     Enter the new GPG key ID (short one) in `config.json` on lines 8 and 36.
   - [ ] **Generate and Enter Secret:**
     Generate a secret and enter it on line 38 of `config.json`. Then you can run the `gentoken` project (taken from the `flat-manager` project) to generate a token **using the secret you generated**:

     ```bash
     cd gentoken

     # Assuming the secret is stored in PROJ_DIR/secret.txt
     cargo run -- --base64 --secret-file ../secret.txt --name all > ../token.txt

     cd -
     ```
      You can generate multiple tokens with different permissions. Refer to the flat-manager docs for more info.
### Start Services

1. **Bring Up Docker Containers:**

   ```bash
   docker compose up -d
   ```

   You can use `docker compose up` to run the containers in the terminal and view logs. Alternatively, use `docker compose logs -f` to follow the logs without starting the containers in the foreground.

2. **Initialize Stable Repository:**

   Once you see "Started http server", initialize your stable repository (one-time setup):

   Enter the 'flat-manager' container with an interactive bash shell: `docker compose exec -it flat-manager bash`

   Then paste the following:

   ```bash
   # Update package lists and install 'ostree' inside the container
   apt update && apt install -y ostree

   # Initialize the 'ostree' repository at the specified path in archive-z2 mode
   ostree --repo=/var/run/flat-manager/stable-repo init --mode=archive-z2

   # Create a directory '/build-repo' if needed
   mkdir -p /build-repo

   # Exit the container
   exit
   ```

### Build and Publish

1. **Build an App:**
   Build your application into a local repository. This will usually be `./repo` from the build directory, it doesn't need to be in this folder. For details, refer to the [Flatpak Builder documentation](https://docs.flatpak.org/en/latest/flatpak-builder.html).

2. **Set TOKEN_FILE:**
   Set `TOKEN_FILE` to the location of the file containing your token (not the secret), which should be `PROJ_DIR/token.txt`.

3. **Publish the Repository:**

   ```bash
   ./publish.sh <DIR>
   ```

   - Set `FLATMAN_URL` if you're not using the default localhost URL.
   > The `sed` commands mentioned earlier does this for you.
   - Monitor the logs to ensure everything proceeds smoothly. You should be able to install the temporary build for testing, but I haven't seen an API endpoint for that yet.
   - If no errors occur, press `y` to confirm and publish the build. Reminder that any builds that aren't published don't appear in the user-visible repo, and will be lost if the container is removed.
   - You're done! Just repeat from 1. to build and publish later versions.

### Testing

To test the installation on your host machine:

```bash
flatpak install --from .flatpakref
flatpak run exchange.haveno.Haveno
```

## Notes

- **`.flatpakref` File:**
  There's a default `.flatpakref` file in this repo for testing. It acts as a manifest indicating where the app and related data are stored. However, once you have functioning builds, it's better to re-host a copy of the generated file which is at `http://localhost:8080/repo/stable/appstream/exchange.haveno.Haveno.flatpakref`, or better yet ask your users to run the following to install it in one line:
  ```sh
  flatpak install --from "http://localhost:8080/repo/stable/appstream/exchange.haveno.Haveno.flatpakref"
  ```

- **Updates:**
  Instruct users to run `flatpak update exchange.haveno.Haveno` to update the app.

- **Repository Size:**
  The build directory may grow large over time. `ostree` manages size to some extent, but running `docker compose down` and `docker compose up` should clear the cache.

- **Configuration Storage:**
  All saved configuration, except for `.gpg` and `config.json`, is stored in Docker volumes. Refer to the Docker documentation if you need to edit these volumes. This is done to ensure other programs can't see secrets, and as such I'd recommend `chmod` and `chown`ing those two so that only root (and docker) can view them. You can also remove `secret.txt`, and `token.txt` if you have stored it somewhere else. 

- **Pushing builds:**
  If you have a copy of a token and the repo's URL is publicly accessible, you can push builds from a different computer (this is why your secret should be secure!). Simply copy the `publish.sh` script wherever you need it and keep the token somewhere secure in your home directory or in a vault, and you can run it the same as you would from the host computer.
