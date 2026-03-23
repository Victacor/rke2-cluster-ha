📦 RKE2 Lab with Vagrant

🧾 Overview
    This project uses Vagrant to automate the deployment of a RKE2 cluster on virtual machines running on VirtualBox.

    Nodes are provisioned using a Bash script that:

    - Prepares the operating system
    - Installs RKE2
    - Generates a basic cluster configuration

    Once the process is complete, the lab is ready to start RKE2 services and begin working with Kubernetes.

    ⚠️ This environment is intended for development and testing purposes only.
    To simplify the setup:

    - firewalld is disabled
    - SELinux is set to permissive mode

⚙️ Prerequisites

    Before starting, make sure you have:

    Installed Vagrant
    👉 https://developer.hashicorp.com/vagrant/install
    Installed VirtualBox
    A valid account in the Red Hat Developer Program
    (required to register the system and download RPM packages)

    A .env file in the project directory with your Red Hat credentials:

    rh_user=<your_redhat_username>
    rh_passwd=<your_redhat_password>

    ⚠️ Do not use quotes or spaces
    ⚠️ Do not commit this file to GitHub

📁 Project Structure
    🔹 Vagrantfile

        Defines the lab infrastructure:

        Virtual machines
        Network configuration
        Resource allocation (CPU, RAM)
        Node roles (server / agent)

        No changes are required for a basic setup, but you can customize:

        Number of nodes
        IP addresses
        Hardware resources

    ⚠️ Advanced modifications may break the provisioning logic.

    🔹 provisioning.sh

        Provisioning script responsible for:

        Registering the system with Red Hat
        Configuring /etc/hosts
        Adjusting OS settings (SELinux, firewall)
        Installing and configuring RKE2

        Its purpose is to leave each node ready to start the RKE2 systemd services.

        ⚠️ Modifying this script is not recommended.
        If you encounter issues, please report them here:

        👉 https://github.com/Victacor/rke2-cluster-ha

    🔹 .env

        Used to store sensitive data (credentials):

        Prevents hardcoding secrets in the code
        Used during provisioning
        The script cleans system metadata after execution

🚀 Usage Guide
    1. Prepare the environment

        Ensure all prerequisites are met.

    2. Create the .env file
        rh_user=your_username
        rh_passwd=your_password

    3. (Optional) Adjust nodes

        Edit the Vagrantfile if you want to change:

        Number of nodes
        Roles (server / agent)

    4. Start the lab
        vagrant up

    5. Access a node
        vagrant ssh Node1

    6. Start RKE2 services

        On each node:

        systemctl start rke2-<role>

        Example:

        systemctl start rke2-server
        systemctl start rke2-agent
🧪 Additional Notes
    The cluster does not start automatically → this is intentional
    Designed for:
        testing
        learning
        debugging
        
⚠️ Security Notice

    This lab:

    Is not hardened
    Disables security components
    Uses a minimal configuration

👉 Do NOT use in production environments
