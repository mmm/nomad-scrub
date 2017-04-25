job "scrub" {
  type = "batch"
  datacenters = ["us-west-2"]

  task "example" {
    driver = "raw_exec"

    config {
      command = "/usr/bin/nomad-scrub.sh"
    }
  }
}
