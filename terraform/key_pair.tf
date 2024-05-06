resource "aws_key_pair" "msaicharan_keypair" {
  key_name   = "msaicharan_keypair"
  public_key = file("key.pub")
}
