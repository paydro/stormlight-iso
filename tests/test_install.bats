# This is a smoke test for an instance. Defaults to 127.0.0.1:2522 VM

HOST=${HOST:-"127.0.0.1"}
PORT=${PORT:-"2522"}
USERNAME=${USERNAME:-"hoid"}
SSH_KEY=${SSH_KEY:-"~/.ssh/stormlight2"}
SSH_OPTS=${SSH_OPTS:-"-o StrictHostkeyChecking=no"}

function setup() {
  # SSH should be open
  nc -vz ${HOST} ${PORT}
}

# Execute command on remote machine.
function rexec() {
  cmd=$1
  ssh -i ${SSH_KEY} ${SSH_OPTS} -p ${PORT} ${USERNAME}@${HOST} "${cmd}"
  return $?
}

@test "Main user '${USERNAME}' account is locked" {
  rexec "sudo grep hoid /etc/shadow | grep 'hoid:!'"
}

@test "sshd disables password login" {
  rexec "grep 'PasswordAuthentication no' /etc/ssh/sshd_config"
}

@test "Cannot login via SSH login with password from config/preseed.cfg" {
  password=$(grep 'd-i passwd/user-password password ' config/preseed.cfg | awk '{$1=$2=$3=""; print $0}' | tr -d '[:space:]')
  run ssh -o PasswordAuthentication=yes ${SSH_OPTS} -p ${PORT} ${USERNAME}@${HOST} echo hello
  [[ "$status" -ne 0 ]]
}

@test "Root partition is ext4" {
  rexec 'sudo mount | grep " / type ext4"'
}

@test "packages installed" {
  packages=( vim curl gnupg net-tools build-essential )
  for pkg in "${packages[@]}"; do
    rexec "dpkg -s ${pkg} | grep Status | grep 'install ok installed'"
  done
}
