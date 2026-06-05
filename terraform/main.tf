# ── Réseau ────────────────────────────────────────────────────────────────────
module "network" {
  source  = "./modules/network"
  project = var.project
  region  = var.region
}

# ── Bastion (SSH-only, subnet public) ─────────────────────────────────────────
module "bastion" {
  source           = "./modules/bastion"
  project          = var.project
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_1_id
  my_ip            = var.my_ip
  key_name         = aws_key_pair.tpfinal.key_name
  instance_type    = var.instance_type
}

# ── Serveurs web + ALB HTTPS (subnet privé web) ───────────────────────────────
module "web" {
  source                = "./modules/web"
  project               = var.project
  vpc_id                = module.network.vpc_id
  public_subnet_1_id    = module.network.public_subnet_1_id
  public_subnet_2_id    = module.network.public_subnet_2_id
  private_web_subnet_id = module.network.private_web_subnet_id
  bastion_sg_id         = module.bastion.sg_id
  key_name              = aws_key_pair.tpfinal.key_name
  instance_type         = var.instance_type
  web_count             = var.web_count
  region                = var.region
}

# ── Storage : S3 (KMS) + FTP (subnet privé storage) ──────────────────────────
module "storage" {
  source                    = "./modules/storage"
  project                   = var.project
  vpc_id                    = module.network.vpc_id
  private_storage_subnet_id = module.network.private_storage_subnet_id
  bastion_sg_id             = module.bastion.sg_id
  key_name                  = aws_key_pair.tpfinal.key_name
  instance_type             = var.instance_type
  region                    = var.region
}

# ── Upload des fichiers Ansible vers S3 ───────────────────────────────────────
# Les fichiers statiques du rôle webserver
resource "aws_s3_object" "ansible_site" {
  bucket = module.storage.bucket_name
  key    = "ansible/site.yml"
  source = "${path.module}/../ansible/site.yml"
  etag   = filemd5("${path.module}/../ansible/site.yml")
}

resource "aws_s3_object" "ansible_cfg" {
  bucket = module.storage.bucket_name
  key    = "ansible/ansible.cfg"
  source = "${path.module}/../ansible/ansible.cfg"
  etag   = filemd5("${path.module}/../ansible/ansible.cfg")
}

resource "aws_s3_object" "webserver_tasks" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/webserver/tasks/main.yml"
  source = "${path.module}/../ansible/roles/webserver/tasks/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/webserver/tasks/main.yml")
}

resource "aws_s3_object" "webserver_handlers" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/webserver/handlers/main.yml"
  source = "${path.module}/../ansible/roles/webserver/handlers/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/webserver/handlers/main.yml")
}

resource "aws_s3_object" "webserver_defaults" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/webserver/defaults/main.yml"
  source = "${path.module}/../ansible/roles/webserver/defaults/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/webserver/defaults/main.yml")
}

resource "aws_s3_object" "webserver_template" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/webserver/templates/index.html.j2"
  source = "${path.module}/../ansible/roles/webserver/templates/index.html.j2"
  etag   = filemd5("${path.module}/../ansible/roles/webserver/templates/index.html.j2")
}

# Les fichiers du rôle ftpserver
resource "aws_s3_object" "ftpserver_tasks" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/ftpserver/tasks/main.yml"
  source = "${path.module}/../ansible/roles/ftpserver/tasks/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/ftpserver/tasks/main.yml")
}

resource "aws_s3_object" "ftpserver_handlers" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/ftpserver/handlers/main.yml"
  source = "${path.module}/../ansible/roles/ftpserver/handlers/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/ftpserver/handlers/main.yml")
}

resource "aws_s3_object" "ftpserver_defaults" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/ftpserver/defaults/main.yml"
  source = "${path.module}/../ansible/roles/ftpserver/defaults/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/ftpserver/defaults/main.yml")
}

resource "aws_s3_object" "ftpserver_template" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/ftpserver/templates/vsftpd.conf.j2"
  source = "${path.module}/../ansible/roles/ftpserver/templates/vsftpd.conf.j2"
  etag   = filemd5("${path.module}/../ansible/roles/ftpserver/templates/vsftpd.conf.j2")
}

# Rôle monitoring
resource "aws_s3_object" "monitoring_tasks" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/tasks/main.yml"
  source = "${path.module}/../ansible/roles/monitoring/tasks/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/tasks/main.yml")
}

resource "aws_s3_object" "monitoring_handlers" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/handlers/main.yml"
  source = "${path.module}/../ansible/roles/monitoring/handlers/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/handlers/main.yml")
}

resource "aws_s3_object" "monitoring_tpl_prometheus_yml" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/templates/prometheus.yml.j2"
  source = "${path.module}/../ansible/roles/monitoring/templates/prometheus.yml.j2"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/templates/prometheus.yml.j2")
}

resource "aws_s3_object" "monitoring_tpl_prometheus_service" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/templates/prometheus.service.j2"
  source = "${path.module}/../ansible/roles/monitoring/templates/prometheus.service.j2"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/templates/prometheus.service.j2")
}

resource "aws_s3_object" "monitoring_tpl_grafana_datasource" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/templates/grafana-datasource.yml.j2"
  source = "${path.module}/../ansible/roles/monitoring/templates/grafana-datasource.yml.j2"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/templates/grafana-datasource.yml.j2")
}

resource "aws_s3_object" "monitoring_tpl_grafana_dashboard" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/monitoring/templates/grafana-dashboard-provisioning.yml.j2"
  source = "${path.module}/../ansible/roles/monitoring/templates/grafana-dashboard-provisioning.yml.j2"
  etag   = filemd5("${path.module}/../ansible/roles/monitoring/templates/grafana-dashboard-provisioning.yml.j2")
}

# Rôle node_exporter
resource "aws_s3_object" "node_exporter_tasks" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/node_exporter/tasks/main.yml"
  source = "${path.module}/../ansible/roles/node_exporter/tasks/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/node_exporter/tasks/main.yml")
}

resource "aws_s3_object" "node_exporter_handlers" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/node_exporter/handlers/main.yml"
  source = "${path.module}/../ansible/roles/node_exporter/handlers/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/node_exporter/handlers/main.yml")
}

# Rôle hardening
resource "aws_s3_object" "hardening_tasks" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/hardening/tasks/main.yml"
  source = "${path.module}/../ansible/roles/hardening/tasks/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/hardening/tasks/main.yml")
}

resource "aws_s3_object" "hardening_handlers" {
  bucket = module.storage.bucket_name
  key    = "ansible/roles/hardening/handlers/main.yml"
  source = "${path.module}/../ansible/roles/hardening/handlers/main.yml"
  etag   = filemd5("${path.module}/../ansible/roles/hardening/handlers/main.yml")
}

# Inventaire généré avec les IPs privées des webs, FTP et monitoring
resource "aws_s3_object" "ansible_inventory" {
  bucket = module.storage.bucket_name
  key    = "ansible/inventory.ini"
  content = templatefile("${path.module}/../ansible/inventory.tftpl", {
    web_ips       = module.web.private_ips
    ftp_ip        = module.storage.ftp_private_ip
    monitoring_ip = module.monitoring.monitoring_private_ip
  })
}

# Variables d'infrastructure injectées dans le playbook
resource "aws_s3_object" "ansible_extra_vars" {
  bucket = module.storage.bucket_name
  key    = "ansible/extra_vars.yml"
  content = templatefile("${path.module}/templates/extra_vars.yml.tftpl", {
    vpc_id                = module.network.vpc_id
    vpc_cidr              = module.network.vpc_cidr
    region                = var.region
    bastion_public_ip     = module.bastion.public_ip
    bastion_private_ip    = module.bastion.private_ip
    s3_bucket_name        = module.storage.bucket_name
    s3_bucket_arn         = module.storage.bucket_arn
    alb_dns_name          = module.web.alb_dns_name
    ftp_private_ip        = module.storage.ftp_private_ip
    ftp_user_password     = module.storage.ftp_user_password
    monitoring_private_ip = module.monitoring.monitoring_private_ip
    kms_key_id            = module.storage.kms_key_id
    project               = var.project
    web_private_ips       = module.web.private_ips
  })
}

# ── Monitoring (Prometheus + Grafana, subnet privé web) ──────────────────────
module "monitoring" {
  source            = "./modules/monitoring"
  project           = var.project
  region            = var.region
  instance_type     = var.instance_type
  key_name          = aws_key_pair.tpfinal.key_name
  private_subnet_id = module.network.private_web_subnet_id
  vpc_id            = module.network.vpc_id
  bastion_sg_id     = module.bastion.sg_id
  web_sg_id         = module.web.web_sg_id
  ftp_sg_id         = module.storage.ftp_sg_id
}

# ── Règles SSH least-privilege : Ansible master → web/ftp/monitoring ──────────
resource "aws_security_group_rule" "ansible_to_web_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.web.web_sg_id
  source_security_group_id = module.ansible.sg_id
  description              = "SSH Ansible master vers serveurs web"
}

resource "aws_security_group_rule" "ansible_to_ftp_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.storage.ftp_sg_id
  source_security_group_id = module.ansible.sg_id
  description              = "SSH Ansible master vers serveur FTP"
}

resource "aws_security_group_rule" "ansible_to_monitoring_ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = module.monitoring.sg_monitoring_id
  source_security_group_id = module.ansible.sg_id
  description              = "SSH Ansible master vers serveur monitoring"
}

# ── Ansible master (subnet privé web, accessible via bastion) ─────────────────
# Créé après que tous les fichiers S3 existent
module "ansible" {
  source                = "./modules/ansible"
  project               = var.project
  vpc_id                = module.network.vpc_id
  private_web_subnet_id = module.network.private_web_subnet_id
  bastion_sg_id         = module.bastion.sg_id
  key_name              = aws_key_pair.tpfinal.key_name
  instance_type         = var.instance_type
  private_key_pem       = tls_private_key.tpfinal.private_key_pem
  s3_bucket_name        = module.storage.bucket_name
  region                = var.region

  depends_on = [
    aws_s3_object.ansible_site,
    aws_s3_object.ansible_cfg,
    aws_s3_object.webserver_tasks,
    aws_s3_object.webserver_handlers,
    aws_s3_object.webserver_defaults,
    aws_s3_object.webserver_template,
    aws_s3_object.ftpserver_tasks,
    aws_s3_object.ftpserver_handlers,
    aws_s3_object.ftpserver_defaults,
    aws_s3_object.ftpserver_template,
    aws_s3_object.monitoring_tasks,
    aws_s3_object.monitoring_handlers,
    aws_s3_object.monitoring_tpl_prometheus_yml,
    aws_s3_object.monitoring_tpl_prometheus_service,
    aws_s3_object.monitoring_tpl_grafana_datasource,
    aws_s3_object.monitoring_tpl_grafana_dashboard,
    aws_s3_object.node_exporter_tasks,
    aws_s3_object.node_exporter_handlers,
    aws_s3_object.hardening_tasks,
    aws_s3_object.hardening_handlers,
    aws_s3_object.ansible_inventory,
    aws_s3_object.ansible_extra_vars,
  ]
}

# ── Génération locale de l'inventaire (usage dev) ─────────────────────────────
resource "local_file" "ansible_inventory_local" {
  content = templatefile("${path.module}/../ansible/inventory.tftpl", {
    web_ips       = module.web.private_ips
    ftp_ip        = module.storage.ftp_private_ip
    monitoring_ip = module.monitoring.monitoring_private_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}
