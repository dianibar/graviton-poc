module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "20.8.3"
    
    cluster_name = "my-eks"
    cluster_version = "1.29"

    cluster_endpoint_private_access = true
    cluster_endpoint_public_access = true

    enable_cluster_creator_admin_permissions = true

    vpc_id = module.vpc.vpc_id
    subnet_ids = module.vpc.private_subnets

    eks_managed_node_group_defaults = { 
        disk_size = 50
    }
    eks_managed_node_groups = {
        general_graviton = {
            desired_capacity = 1
            max_capacity = 10
            min_capacity = 1

            labels = {
                role = "general"
            }
            instance_type = ["t4g.micro"]
            capacity_type = "ON_DEMAND"

        }      

        general_spot = {
            desired_capacity = 1
            max_capacity = 10
            min_capacity = 1

            labels = {
                role = "spot"
            }
            instance_type = ["t3.micro"]
            capacity_type = "SPOT"
        }
    }
}