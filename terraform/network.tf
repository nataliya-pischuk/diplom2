# ==================== VPC NETWORK ====================
resource "yandex_vpc_network" "diplom_network" {
  name = "diplom-network"
}

# Публичная подсеть (для bastion, zabbix, kibana, balansir)
resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.10.4.0/24"]
}

# Приватная подсеть A (для web-1)
resource "yandex_vpc_subnet" "private_subnet_a" {
  name           = "private-subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.10.1.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
}

# Приватная подсеть B (для web-2)
resource "yandex_vpc_subnet" "private_subnet_b" {
  name           = "private-subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.10.2.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
}

# Приватная подсеть для Elasticsearch
resource "yandex_vpc_subnet" "private_subnet_elk" {
  name           = "private-subnet-elk"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.diplom_network.id
  v4_cidr_blocks = ["10.10.3.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route_table.id
}

# ==================== NAT GATEWAY ====================
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nat_route_table" {
  name       = "nat-route-table"
  network_id = yandex_vpc_network.diplom_network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}
# ==================== BASTION HOST ====================
resource "yandex_compute_instance" "bastion" {
  name        = "wm-bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  allow_stopping_for_update = true
  zone        = "ru-central1-a"


  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-bastion.id}"
    }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
    ip_address         = "10.10.4.4"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# ==================== WEB SERVERS ====================
# Web Server 1
resource "yandex_compute_instance" "web-1" {
  name        = "wm-web-1"
  hostname    = "web1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-web-1.id}"
    }
  

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_a.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
    ip_address         = "10.10.1.5"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# Web Server 2
resource "yandex_compute_instance" "web-2" {
  name        = "wm-web-2"
  hostname    = "web2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-web-2.id}"
    }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_b.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
     ip_address         = "10.10.2.5"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# ==================== ZABBIX SERVER ====================
resource "yandex_compute_instance" "zabbix" {
  name        = "wm-zabbix"
  hostname    = "zabbix"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 50
    memory        = 4
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-zabbix.id}"
    }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.zabbix_sg.id]
    ip_address         = "10.10.4.5"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# ==================== ELASTICSEARCH SERVER ====================
resource "yandex_compute_instance" "elasticsearch" {
  name        = "wm-elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 50
    memory        = 4
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-elastic.id}"
    }
  
  network_interface {
    subnet_id          = yandex_vpc_subnet.private_subnet_elk.id
    security_group_ids = [yandex_vpc_security_group.elk_sg.id]
    ip_address         = "10.10.3.5"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}

# ==================== KIBANA SERVER ====================
resource "yandex_compute_instance" "kibana" {
  name        = "wm-kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

 boot_disk {
    disk_id     = "${yandex_compute_disk.disk-kibana.id}"
     }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.public_sg.id]
     ip_address         = "10.10.4.6"
  }

  scheduling_policy {
    preemptible = true
  }
 metadata = {
    user-data = "${file("./meta.txt")}"
  }
}
# ==================== APPLICATION LOAD BALANCER ====================
resource "yandex_alb_target_group" "web_tg" {
  name = "web-target-group"

  target {
    ip_address = yandex_compute_instance.web-1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private_subnet_a.id
  }

  target {
    ip_address = yandex_compute_instance.web-2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private_subnet_b.id
  }
}

# Backend Group
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    port             = 80
    target_group_ids = [yandex_alb_target_group.web_tg.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "1s"
      interval            = "1s"
      healthy_threshold   = 2
      unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# HTTP Router
resource "yandex_alb_http_router" "web_router" {
  name = "web-http-router"
}

# Virtual Host
resource "yandex_alb_virtual_host" "web_vh" {
  name           = "web-virtual-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route"
    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout          = "3s"
      }
    }
  }
}

# Application Load Balancer
resource "yandex_alb_load_balancer" "web_alb" {
  name               = "web-balancer"
  network_id         = yandex_vpc_network.diplom_network.id
  security_group_ids = [yandex_vpc_security_group.balancer_sg.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_subnet.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
   
  }





