provider "google-beta" {
    credentials = file("./project_key.json")
    project = "mbr-dev-341307" //replace project name here
    region  = "asia-southeast1"
    zone    = "asia-southeast1-b"
}
