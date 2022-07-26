# Install GameBox Cloud

It is recommended to install GBC (short for GameBox Cloud) from source code, so that it can adapt to different operating systems and operating environments.

Currently, the production operating environments supported by GBC are:

- CentOS 6+
-   Ubuntu 14+

Supported development environments are:

- Mac OS X
- Various Linux distributions


## Download GBC

Since GBC consists of software such as OpenResty, Redis, etc., you need to download the installation package and install it from the source code.

It is recommended to download the latest version of GBC from [https://github.com/dualface/gbc-core](https://github.com/dualface/gbc-core):

- Open the "[releases](https://github.com/dualface/gbc-core/releases)" page and download the latest `.zip` or `.tar.gz` archive from there
- Or use the `git` command to `clone` the GBC repository:

```bash
git clone https://github.com/dualface/gbc-core.git
```


## Build the development environment

There are two ways to set up the development environment:

- use the `make.sh` script
- Install using [Vagrant](https://www.vagrantup.com/)


### Install script using `make.sh`

After decompressing the downloaded `gbc-core` source code to the desired directory, enter the directory and execute the `make.sh` script to complete the installation.

Note: `gbc-core` source code should be placed in a directory without spaces and Chinese characters

After the installation is complete, you can use `start_server --debug` to start GBC for testing.


### Install with Vagrant

If you use a Windows environment, you must use Vagrant. Before using it, you need to install the latest version of VirtualBox and the latest version of Vagrant.

-   VirtualBox: [https://www.virtualbox.org/](https://www.virtualbox.org/)
-   Vagrant: [https://www.vagrantup.com/](https://www.vagrantup.com/)

After the installation is complete, go to the `gbc-core` source code directory and execute:

```bash
cd gbc-core
vagrant up
```

After executing `vagrant up`, the virtual machine image is downloaded and the virtual machine is powered on for installation.

After the installation is complete, open a browser and visit `http://localhost:8088/` to access the GBC welcome page.


## Production installation

In a production environment, security issues must be considered first, so it is recommended to follow the steps below:

1. Create a separate user for GBC, eg `gbc`:

    ```bash
    useradd -s /bin/false -m gbc
    ```

2. Install GBC to the directory where the `gbc` user is located, and change the file owner:

    ```bash
    cd gbc-core
    sudo ./make.sh --prefix=/home/gbc/gbc-core
    sudo chown -R gbc:gbc /home/gbc/gbc-core
    ```

After the above three steps, we are ready to run the GBC environment.

On some operating systems, such as CentOS, due to security restrictions, it is necessary to authorize network ports and other permissions for the `gbc` user. For details, please refer to related documents.


## Start and stop GBC

Enter the installation directory and execute:

```bash
./start_server
```

You can start GBC (ROOT_DIR output varies according to the installation directory):

```markdown
ROOT_DIR=/opt/gbc-core

Start GameBox Cloud Core

[CMD] supervisord -c /opt/gbc-core/tmp/supervisord.conf

Start supervisord DONE

beanstalkd                       STARTING
nginx                            STARTING
redis                            STARTING
worker-tests:00                  STARTING
worker-welcome:00                STARTING
worker-welcome:01                STARTING
```

To check that GBC started normally, execute:

```bash
./check_server
```

If output:

```markdown
beanstalkd                       RUNNING   pid 12352, uptime 0:01:11
nginx                            RUNNING   pid 12347, uptime 0:01:11
redis                            RUNNING   pid 12350, uptime 0:01:11
worker-tests:00                  RUNNING   pid 12351, uptime 0:01:11
worker-welcome:00                RUNNING   pid 12348, uptime 0:01:11
worker-welcome:01                RUNNING   pid 12349, uptime 0:01:11
```

Indicates that GBC is working properly.


### Stop GBC

implement:

```bash
./stop_server
```


### Start GBC in debug mode

GBC started in normal mode must be restarted to take effect after the developer modifies the script.

In order to improve development efficiency, GBC provides a debug mode, just execute:

```bash
./start_server --debug
```

In debug mode, there is no need to restart GBC after modifying the script, the next request or operation will make the new script take effect immediately.


### Controlling GBC start and stop in Vagrant

Each time `vagrant up` is executed, GBC will be automatically started in debug mode. We can also log in to the virtual machine created by Vagrant to control GBC:

```bash
vagrant ssh

cd /opt/gbc-core
./check_server
./stop_server
```


## Develop in debug mode

	When using `make.sh` or Vagrant to install and run GBC, as long as you modify the corresponding files in the source code directory, it can be understood and effective.
