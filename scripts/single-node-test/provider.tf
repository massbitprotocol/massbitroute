provider "google" {
    credentials = file("./project_key.json")
    project = "mbr-test-341307" //replace project name here
    region  = "asia-southeast2"
    zone    = "asia-southeast2-a"
}
