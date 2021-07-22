module "eks" {

    source  = "terraform-aws-modules/eks/aws"
    version = "17.1.0"
       
    cluster_name    = local.eks_cluster_name
    cluster_version = var.eks_cluster_version

    vpc_id          = module.vpc.vpc_id
    subnets         = module.vpc.private_subnets

   

    # Node Groups
    node_groups = {

        nodegroup-1 = {

            name = "${local.name_prefix}-eks-cluster-node-group"
            
            desired_capacity = var.eks_desired_worker_nodes
            max_capacity     = var.eks_max_worker_nodes
            min_capacity     = var.eks_min_worker_nodes

            launch_template_id      = aws_launch_template.eks_launch_template.id
            launch_template_version = aws_launch_template.eks_launch_template.latest_version

            # Instance type should be passed here with node groups
            # It throws error if you mention instance type in Launch template
            instance_types = [var.eks_worker_instance_type]

            additional_tags = local.tags

            #Default AMI to be picked for EKS Nodes as Part of Node Group Creation (AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64)
            #You can pass Custom AMI from Launch Template, but you need to pass bootstrap script as userdata for that AMI.
        }
    }
    
    # As of now there is no straight forward way to add additional Security Groups 
    # to the Managed EKS Nodes for SSH Ingress tules.

    cluster_endpoint_private_access = true
    
    # Creates OIDC Provider to Enable IRSA (IAM Role for Service Account)
    enable_irsa = true

    write_kubeconfig  = true
    kubeconfig_output_path = "./kubeconfig/kubeconfig"

    tags = local.tags

}

# "node_groups" are aws eks managed nodes whereas "worker_groups" are self managed nodes. 
