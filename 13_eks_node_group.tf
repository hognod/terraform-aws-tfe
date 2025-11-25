# resource "aws_eks_node_group" "main" {
#   cluster_name = aws_eks_cluster.main.name

#   node_group_name = "hognod-eks-node-group"
#   node_role_arn = aws_iam_role.eks_node_group.arn
#   subnet_ids = [
#     aws_subnet.private-a.id,
#     aws_subnet.private-b.id
#   ]
#   capacity_type = "ON_DEMAND" # ON_DEMAND / SPOT
#   instance_types = [
#     var.node_group_instance_type
#   ]
#   ami_type = 
# }