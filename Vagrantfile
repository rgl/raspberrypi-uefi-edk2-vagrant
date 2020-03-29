Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-18.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs'
  end

  config.vm.provider :virtualbox do |vb|
    vb.linked_clone = true
    vb.memory = 4*1024
    vb.cpus = 4
  end

  config.vm.hostname = 'uefi'
  config.vm.provision :shell, path: 'provision-base.sh'
  config.vm.provision :shell, path: 'provision-edk2.sh'
end
