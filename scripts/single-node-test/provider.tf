provider "google-beta" {
    credentials = file("./project_key.json")
    project = "mbr-dev-341307" //replace project name here
    region  = "asia-east1"
    zone    = "asia-east1-b"
}
