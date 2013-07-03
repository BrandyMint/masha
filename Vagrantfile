# vagrant plugin install vagrant-berkshelf


Vagrant.configure("2") do |config|
  config.berkshelf.enabled = true

  config.vm.box = "quantal64"
  config.vm.box_url = "http://dl.dropbox.com/u/13510779/lxc-quantal-amd64-2013-05-08.box"

  config.vm.provider :lxc do |lxc|
    # Same effect as as 'customize ["modifyvm", :id, "--memory", "1024"]' for VirtualBox
    lxc.customize 'cgroup.memory.limit_in_bytes', '1024M'
  end

  #config.vm.provision :shell do |sh|
    #sh.inline = <<-EOF
      #/opt/ruby/bin/gem install chef --no-ri --no-rdoc --no-user-install
    #EOF
  #end

  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["~/.berkshelf/cookbooks/"]
    #chef.add_recipe "myproject, nginx, postgresql, python, ..."

    # this assumes you have travis-ci/travis-cookbooks cloned at ./cookbooks
    #chef.cookbooks_path = ["cookbooks/ci_environment"]
    chef.log_level      = :debug

    # Highly recommended to keep apt packages metadata in sync and
    # be able to use apt mirrors.
    chef.add_recipe     "apt"

    # List the recipies you are going to work on/need.
    chef.add_recipe     "build-essential"
    #chef.add_recipe     "networking_basic"

    # chef.add_recipe     "travis_build_environment"
    chef.add_recipe     "git"

    # chef.add_recipe     "java::openjdk7"
    # chef.add_recipe     "leiningen"

    # chef.add_recipe     "rabbitmq::with_management_plugin"

    #chef.add_recipe     "rvm"
    #chef.add_recipe     "rvm::multi"
    # chef.add_recipe     "nodejs::multi"
    # chef.add_recipe     "python::multi"

    # chef.add_recipe     "libqt4"
    # chef.add_recipe     "xserver"
    # chef.add_recipe     "firefox"

    #chef.add_recipe     "memcached"
    # chef.add_recipe     "redis"
    # chef.add_recipe     "riak"
    # chef.add_recipe     "mongodb"
    # chef.add_recipe     "mysql::client"
    # chef.add_recipe     "mysql::server"
    chef.add_recipe     "postgresql::client"
    chef.add_recipe     "postgresql::server"
    # chef.add_recipe     "couchdb::ppa"
    # chef.add_recipe     "neo4j-server::tarball"
    # chef.add_recipe     "firebird"

    #chef.add_recipe     "elasticsearch"
    # chef.add_recipe     "cassandra::datastax"
    # chef.add_recipe     "hbase::ppa"
    # chef.add_recipe     "pypy::ppa"
    #
    chef.json.merge!( {
        "postgresql" => {
          "password" => {
            "postgres" => "iloverandompasswordsbutthiswilldo"
          }
        },
        "run_list" => ["recipe[postgresql::server]"]
      })


     #chef.json.merge!({
    ##                    :apt => {
    ##                      :mirror => :ru
    ##                    },
                        #:rvm => {
                          #:rubies  => [
                            #{ :name => "2.0.0-p195" }
    ##                        { :name => "rbx-head", :arguments => "--branch 2.0.testing", :using => "1.8.7" },
    ##                        { :name => "jruby-d19", :arguments => "--19" },
    ##                        { :name => "ruby-head-s92b6597be67738490c0ab759303a0e81a421b89a" },
    ##                        { :name => "1.9.3" },
    ##                        { :name => "rbx-head-d19", :arguments => "--branch 2.0.testing --19", :using => "1.9.3" },
    ##                        { :name => "jruby" },
    ##                        { :name => "jruby-head" },
    ##                        { :name => "1.9.2" },
                          #],
    ##                      :aliases => {
    ##                        "rbx"         => "rbx-head",
    ##                        "rbx-2.0"     => "rbx-head",
    ##                        "rbx-2.0.pre" => "rbx-head"
    ##                      }
                        #},
    ##                    :mysql => {
    ##                      :server_root_password => ""
    ##                    },
                        #:postgresql => {
                          #:max_connections => 256
                        #}
                      #})
  end
end
