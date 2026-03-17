# NoSU - an Ubuntu system without sudo binaries

NoSU is a system that has been stripped of all `sudo` binaries and will try to
confine as many applications as possible using `apparmor` and limit user actions
with `polkit` rules. The system uses `run0` as a replacement for `sudo`.

The system is based on Ubuntu 26.04.

> **Note**
> This is a concept project, work in progess and not intended for production use.

## Requirements

- [Vagrant](https://www.vagrantup.com/)
- [systemd v256](https://github.com/systemd/systemd) or later.
- [polkit 127](https://github.com/polkit-org/polkit) or later.
- Ansible [community.general 10.2.0](https://github.com/ansible-collections/community.general)
  or later if you want to use `run0` as a `become_method` in Ansible.

## `run0`

See [this thread from @poettering](https://mastodon.social/@pid_eins/112353324518585654)
and the [systemd changelog](https://github.com/systemd/systemd/releases/)
for more information.

## `systemd-creds`

See [System and Service Credentials](https://systemd.io/CREDENTIALS/) for more
information.

## Setup

- Start the VM: `vagrant up`.
- SSH into the VM: `vagrant ssh`.
- Build the latest release of `systemd` if it's not already installed:
  `/vagrant/scripts/build_systemd.sh`.
- Build the latest release of `polkit` if it's not already installed:
  `/vagrant/scripts/build_polkit.sh`.
- Create an initial privileged `polkit` rule:
  `sudo /vagrant/scripts/privileged_polkit_rule.sh`.

  The script will create the `wheel` group and add the `vagrant` user to it.
  The `polkit` rule will allow member `vagrant` of the `wheel` group to run any command
  without authentication.

- Exit and reboot the VM using `vagrant reload`.
- After the reboot, SSH into the VM again and verify that the system is running
  `systemd v256` or later with `systemd --version` and that `polkit` is running
  the latest version with `pkaction --version`.
- Remove the `sudo`, related packages and set `apt` preferences so that `sudo`
  can't be installed again: `run0 /vagrant/scripts/remove_sudo.sh`.
  `sudo` will now only be a symlink to `run0`.
  `pkexec` will have the suid bit removed and will be owned by root,
  so it can't be used to gain root privileges.
- Ensure `apparmor` and `auditd` is installed, configured and enabled
  by running `run0 /vagrant/scripts/configure_apparmor.sh`.
- Exit and reboot the VM again using `vagrant reload`.
- After the reboot, SSH into the VM again and verify that `sudo` is no longer
  available (`ls -l "$(which sudo)"` and `sudo --version`) and verify apparmor status
  (`aa-status`).

## Usage: Using `run0` as a `become_method` in Ansible

Note that systemd v258 or later is required if you want to use encrypted
credentials in an user context.

```sh
uv venv "${HOME}/ansible-venv"
source "${HOME}/ansible-venv/bin/activate"
uv pip install ansible
```

- The `run0` module is used as a `become_method` in the example playbook:
  `become_method: community.general.run0`

  And as a test, we'll run an playbook that will start a web server as a
  Podman quadlet, the quadlet also uses the [systemd-creds encrypt module](https://docs.ansible.com/ansible/latest/collections/community/general/systemd_creds_encrypt_module.html)
  in an user context.

  ```sh
   ansible-galaxy install --force -r /vagrant/ansible/requirements.yml
   ansible-playbook -i 'localhost,' -c local /vagrant/ansible/playbook.yml
  ```

  Verify that the web server is running:

  ```sh
  run0 --user=container-nginx systemctl --user status nginx
  curl -s http://localhost:8080
  run0 --user=container-nginx podman logs nginx
  ```

  Reboot the server and perform the same test to verify that the web server is
  still running and monitor the journal for any issues.
