resource "null_resource" "configure_bastion" {
  depends_on = [
    module.ec2_public
  ]

  connection {
    host = aws_eip.bastion_eip.public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("private-key/us-west-2-keypair.pem")
  }

  provisioner "file" {
    source = "private-key/us-west-2-keypair.pem"
    destination = "/tmp/us-west-2-keypair.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/us-west-2-keypair.pem"
    ]
  }
}