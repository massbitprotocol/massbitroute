# massbitroute
MassbitRoute is a Blockchain Distribution Network (BDN) that utilizes a global network of servers optimized for network performance.

## API component of Massbitroute


### Install with docker 
```
 services:
  api:
    privileged: true
    restart: unless-stopped
    image: massbit/massbitroute_api:_BRANCH_
    build:
      context: /massbit/massbitroute/app/src
      dockerfile: install/mbr/build/api/Dockerfile
      args:
        GIT_PUBLIC_URL: https://github.com        
        #MYAPP_IMAGE: massbit/massbitroute_base:_BRANCH_        
        BRANCH: _BRANCH_
    container_name: mbr_api
    environment:
      - GIT_PUBLIC_URL="https://github.com"                            # default public source control
      - MBR_ENV=_BRANCH_                                               # Git Tag version deployment of Api repo
      - MKAGENT_BRANCH=_BRANCH_                                        # Git Tag version deployment of Monitor client 
      - GIT_PRIVATE_BRANCH=_BRANCH_                                    # Private git branch default of runtime conf
      - GIT_PRIVATE_READ_URL=http://massbit:xxxx@git.massbitroute.net  # Private git url address with authorized account
    extra_hosts:
      - "git.massbitroute.net:172.20.0.2"
