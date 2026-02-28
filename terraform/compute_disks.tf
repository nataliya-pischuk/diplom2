resource "yandex_compute_disk" "disk-web-1" {
  name     = "disk-vm-web1"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 10
  
}

resource "yandex_compute_disk" "disk-web-2" {
  name     = "disk-vm-web2"
  type     = "network-hdd"
  zone     = "ru-central1-b"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 10
  
}

resource "yandex_compute_disk" "disk-bastion" {
  name     = "disk-vm-bastion"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 10
  
}

resource "yandex_compute_disk" "disk-zabbix" {
  name     = "disk-vm-zabbix"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 10
  
}

resource "yandex_compute_disk" "disk-elastic" {
  name     = "disk-vm-elastic"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 20
  
}

resource "yandex_compute_disk" "disk-kibana" {
  name     = "disk-vm-kibana"
  type     = "network-hdd"
  zone     = "ru-central1-a"
  image_id = "fd8kiogst6b2vj84enm8"
  size     = 10
  
}
