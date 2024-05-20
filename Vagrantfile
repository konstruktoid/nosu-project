Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]
  end

  config.vm.define "nosu" do |nosu|
    nosu.vm.box = "bento/ubuntu-24.04"
    nosu.ssh.insert_key = true
    nosu.vm.hostname = "nosu"
    nosu.vm.boot_timeout = 600
   end
end
