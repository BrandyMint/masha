# vagrant plugin install vagrant-berkshelf


Vagrant.configure("2") do |config|
  config.berkshelf.enabled = true

  config.vm.box = "quantal64"
  config.vm.box_url = "http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-05-08.box"

  config.vm.provider :lxc do |lxc|
    # Same effect as as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
  end

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["~/.berkshelf/cookbooks/"]
    #chef.add_recipe "myproject, nginx, postgresql, python, ..."

    # this assumes you have travis-ci/travis-cookbooks cloned at ./cookbooks
    #chef.cookbooks_path = ["cookbooks/ci_environment"]
    chef.log_level      = :debug

    chef.add_recipe     'apt'
    chef.add_recipe     'build-essential'
    chef.add_recipe     'nginx'
    #chef.add_recipe     'unicorn'
    #chef.add_recipe     'imagemagick'
    chef.add_recipe     'ubuntu'
    chef.add_recipe     'users'
    #chef.add_recipe     'networking_basic'
    chef.add_recipe     'git'
    chef.add_recipe     'postgresql::server'
    chef.add_recipe     'postgresql::client'
    #chef.add_recipe     'application_ruby'

    #chef.add_recipe     "elasticsearch"

    chef.json.merge!( {
        "postgresql" => {
          "password" => {
            #:max_connections => 256
            # Это так пароль postgres пишется в md5
            "postgres" => "iloverandompasswordsbutthiswilldo"
          }
        },

        'users'  => {
        },

        'ubuntu' => {
          'locale' => 'C'
        },

        "run_list" => ["recipe[postgresql::server]"]
      })
  end
end
