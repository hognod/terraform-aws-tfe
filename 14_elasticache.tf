resource "aws_elasticache_subnet_group" "main" {
  name = "hognod-elasticache-subent-group"
  subnet_ids = [
    aws_subnet.private-a.id,
    aws_subnet.private-b.id
  ]
}

resource "aws_elasticache_cluster" "main" {
  cluster_id = "hognod-elasticache"
  engine = "redis" # memcached / redis / valkey
  node_type = var.elasticache_node_type
  num_cache_nodes = 1
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [
    aws_security_group.ealsticache.id
  ]
  
  tags = {
    Name = "hognod-elasticache"
  }
}