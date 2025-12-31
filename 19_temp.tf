# resource "terraform_data" "destroy" {
#   depends_on = [
#     aws_eks_node_group.main
#   ]

#   input = {
#     tfe_kube_namespace               = var.tfe_kube_namespace
#     tfe_lb_controller_kube_namespace = var.tfe_lb_controller_kube_namespace
#     host                             = aws_instance.public.public_ip
#     user                             = var.instance_user
#     private_key                      = tls_private_key.main.private_key_pem
#   }

#   connection {
#     host        = self.output.host
#     user        = self.output.user
#     private_key = self.output.private_key

#     timeout = "2m"
#   }

#   provisioner "remote-exec" {
#     when       = destroy
#     on_failure = continue
#     inline = [
#       "helm delete terraform-enterprise --namespace ${self.output.tfe_kube_namespace}",
#       "sleep 30s",
#       "helm delete aws-load-balancer-controller --namespace ${self.output.tfe_lb_controller_kube_namespace}",
#       "sleep 30s"
#     ]
#   }
# }