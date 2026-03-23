env_file = File.expand_path(".env", __dir__)

if File.exist?(env_file)
  File.foreach(env_file) do |line|
    line = line.strip
    next if line.empty? || line.start_with?("#")

    key, value = line.split("=", 2)
    ENV[key] = value
  end
end

Vagrant.configure("2") do |config|

  base_conf = {
    box: "victacor-Rhel9/rhel9.7-1.0.1",
    box_version: "1.0.1",
    post_up_message: "Node correctly started",
    keep_alive: true
  }

  #Indicate the nodes to be created, their IPs and their roles (server or agent)
  #Node1 will be the first Node in the rke2 clúster.
  nodes = [
    { name: "Node1", ip: "10.40.0.2", role: "server" },
    { name: "Node2", ip: "10.40.0.3", role: "server" },
    { name: "Node3", ip: "10.40.0.4", role: "server" },
    { name: "Node4", ip: "10.40.0.5", role: "agent" },
    { name: "Node5", ip: "10.40.0.6", role: "agent" }
  ]

  hosts_entries = nodes.map { |n| "#{n[:ip]} #{n[:name]}" }.join("\n")

  nodes.each do |node_info|
    config.vm.define node_info[:name] do |node|  
      #common conf
      node.vm.box = base_conf[:box]
      node.vm.synced_folder ".", "/vagrant", disabled: true
      node.vm.box_version = base_conf[:box_version]
      node.vm.post_up_message = base_conf[:post_up_message]
      node.ssh.keep_alive = base_conf[:keep_alive]
      node.vm.network "public_network", bridge: "Ethernet"
      node.vm.provision "shell", path: "provisioning.sh", env: {
        "rh_user" => ENV["rh_user"],
        "rh_passwd" => ENV["rh_passwd"],
        "ROLE" => node_info[:role],
        "HOSTS_ENTRIES" => hosts_entries
      }
      #custom conf
      node.vm.hostname = node_info[:name]
      node.vm.network "private_network", ip: node_info[:ip]

      #provider
      node.vm.provider "virtualbox" do |vb|
        vb.name = node_info[:name]
        vb.memory = 4096
        vb.cpus = 2
      end
    end
  end
end