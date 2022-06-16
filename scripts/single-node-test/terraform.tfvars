project_prefix = "mbr"
environment = "test"
default_zone = "asia-southeast2-a"
network_interface = "default"
email = "mbr-dev@mbr-dev-341307.iam.gserviceaccount.com"
map_machine_types={"git":"e2-micro","mbr-core":"e2-medium","mbr-core-micro":"e2-micro","api":"e2-custom-4-4096","dns":"e2-micro","gateway":"e2-small","node":"e2-small"}
map_ips={"test-git1":"34.101.215.184","test-api1":"34.101.158.133","dns1":"34.101.202.49","dns2":"34.101.231.46"}
list_dns_names=["dns1","dns2"]
multiLineString=""