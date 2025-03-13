# NoSU - an Ubuntu system without sudo binaries

NoSU is a system that has been stripped of all `sudo` binaries and will try to
remove as many SUID/SGID file permissions as possible.

The system is based on Ubuntu 24.04, and uses `run0` and `polkit` rules instead.

> **Note**
> This is a concept project, work in progess and not intended for production use.

## Requirements

- [Vagrant](https://www.vagrantup.com/)
- [systemd v256](https://github.com/systemd/systemd) or later.
- Ansible [community.general 10.2.0](https://github.com/ansible-collections/community.general)
  or later.

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
  `bash /vagrant/scripts/build_systemd.sh`.
- Create an initial privileged `polkit` rule:
  `sudo bash /vagrant/scripts/privileged_polkit_rule.sh`.

  The script will create the `wheel` group and add the `vagrant` user to it.
  The `polkit` rule will allow member `vagrant` of the `wheel` group to run any command
  without authentication.

- Exit and reboot the VM: `vagrant reload`
- After the reboot, SSH into the VM again and verify that the system is running
  `systemd v256` or later: `systemd --version`
- Remove the `sudo`, related packages and set `apt` preferences so that `sudo`
  can't be installed again: `run0 bash /vagrant/scripts/remove_sudo.sh`.
  `sudo` will now only be a symlink to `run0`.

## Usage: Using `run0` as a `become_method` in Ansible

Note that systemd v258 or later is required if you want to use encrypted
credentials in an user context.

- Install Ansible:

  ```sh
  run0 apt-get install --assume-yes python3-pip python3-venv
  python3 -m venv ansible
  source ansible/bin/activate
  python3 -m pip install ansible
  ```

- The `run0` module is used as a `become_method` in the example playbook:
  `become_method: community.general.run0`

  And as a test, we'll run an playbook that will start a web server as a
  Podman quadlet after the system has been [additionaly hardened](https://github.com/konstruktoid/ansible-role-hardening),
  the quadlet also uses the [systemd-creds encrypt module](https://docs.ansible.com/ansible/latest/collections/community/general/systemd_creds_encrypt_module.html)
  in an user context.

  ```sh
   ansible-galaxy install --force -r /vagrant/ansible/requirements.yml
   ansible-playbook -v -i '127.0.0.1,' -c local --skip-tags sudo /vagrant/ansible/playbook.yml
  ```

  Verify that the web server is running:

  ```sh
  run0 --user=container-nginx systemctl --user status nginx
  curl -s http://localhost:8080
  run0 --user=container-nginx podman logs nginx
  ```

  Reboot the server and perform the same test to verify that the web server is
  still running and monitor the journal for any issues.
