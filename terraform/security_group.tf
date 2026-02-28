# ==================== SECURITY GROUPS ====================

resource "yandex_vpc_security_group" "internal" {
  name       = "internal-rules"
  network_id = yandex_vpc_network.diplom_network.id

  ingress {
    protocol       = "ANY"
    description    = "allow any connection from internal subnets"
	predefined_target = "self_security_group"
  }
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    port           = 22
    v4_cidr_blocks = ["10.10.4.0/24"]
  }
  egress {
    protocol       = "ANY"
    description    = "allow any outgoing connections"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для публичных серверов (bastion, zabbix, kibana)
resource "yandex_vpc_security_group" "public_sg" {
  name       = "public-sg"
  network_id = yandex_vpc_network.diplom_network.id

 # HTTP от интернета (для Zabbix)
  ingress {
    protocol       = "TCP"
    description    = "HTTP from internet (Zabbix)"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP от интернета (для Kibana)
  ingress {
    protocol       = "TCP"
    description    = "HTTP from internet (Kibana)"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH from internet"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH от bastion (для Ansible через ProxyJump)
  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion"
    port           = 22
    v4_cidr_blocks = ["10.10.4.0/24"]
  }
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "Allow any outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для веб-серверов
resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = yandex_vpc_network.diplom_network.id

  ingress {
    description    = "Allow HTTP protocol from local subnets"
    protocol       = "TCP"
    port           = "80"
    v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24"]
  }
ingress {
    description    = "Allow TCP Zabbex"
    protocol       = "TCP"
    port           = "10050"
    v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24"]
  }
  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    port              = 22
    v4_cidr_blocks = ["10.10.4.0/24"]
  }

  # ICMP от Bastion SG (для ping)
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Allow any outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для ALB
resource "yandex_vpc_security_group" "balancer_sg" {
  name       = "balancer_sg"
  network_id = yandex_vpc_network.diplom_network.id

  # Входящий трафик от интернета
  ingress {
    protocol       = "TCP"
    description    = "HTTP from internet"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }                         
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  # Общий исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "All outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
# SG для bastion host
resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.diplom_network.id

  ingress {
    protocol       = "TCP"
    description    = "SSH from internet"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "Allow any outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для Zabbix
resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix-sg"
  network_id = yandex_vpc_network.diplom_network.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP from internet"
    #port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent connections"
    port              = 10050
#    from_port              = 10050
#    to_port                = 10051
    v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24"]
    security_group_id = yandex_vpc_security_group.web_sg.id
  }
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "Allow any outgoing traffic"
    #v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24"]
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# SG для ELK стека
resource "yandex_vpc_security_group" "elk_sg" {
  name       = "elk-sg"
  network_id = yandex_vpc_network.diplom_network.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "Elasticsearch from web servers"
    port              = 9200
    v4_cidr_blocks = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24", "10.10.4.0/24"]
    security_group_id = yandex_vpc_security_group.web_sg.id
   }
 ingress {
    protocol       = "ICMP"
    description    = "allow ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "Allow any outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
