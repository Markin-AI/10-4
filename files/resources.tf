resource "yandex_vpc_network" "network-1" {
  name = "network-1"
}

resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-b"
  network_id     = "${yandex_vpc_network.network-1.id}"
  v4_cidr_blocks = ["10.129.0.0/24"]
}

resource "yandex_compute_instance" "vm" {
  count = 2
  name = "vm${count.index}"
  zone = var.zone

  resources {
    core_fraction = 5
    cores  = 2
    memory = 2
  }
  boot_disk {
    initialize_params {
      image_id = "fd87q4jvf0vdho41nnvr"
      size = 20
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-1.id
    nat = true
  }

  metadata = {
    user-data = "${file("./cloud.yml")}"
  }
}

resource "yandex_lb_target_group" "tg1" {
  name = "tg1"

  target {
    subnet_id    = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[0].network_interface.0.ip_address
  }
  target {
    subnet_id    = yandex_vpc_subnet.subnet-1.id
    address   = yandex_compute_instance.vm[1].network_interface.0.ip_address
  }
}

resource "yandex_lb_network_load_balancer" "lb1" {
  name = "lb1"
  listener {
    name = "lb-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg1.id
    healthcheck {
      name = "http-check"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
