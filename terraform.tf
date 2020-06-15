//variable created to store the region
variable "region" {
  default = "ap-south-1"
}

//variable created to store the key
variable "key" {
  default = "my11"
}

//provider and profile
provider "aws" {
  region	= var.region
  profile	= "boss"
}

//generate key-pair
resource "aws_key_pair" "enter_key_name" {
  key_name   = var.key
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCl6w49kXwnYgPOyTUu8/34QCkpDM1YpMyi3p4Q0OoDuJhCj1qv9FtT9Mulh7Gwl6UR99Pve7IhQvCpokFO+529D7U1POqddIzBhptNwhvg/TGT2EPBbCsDqKu7/5R/uabeQeeyCcBFWUeT1mlXc9v8zXJJCdSgTkVFydcyyZgr8yaYLW5/yk3Qujy0QU94YWmalfwSbwGM/yqwn4gpnb1E04IjNbeyHIMBVPjY9CQN29fUAJl69CQZZJswuITj61aEbT/VC3F4Vq7c1QNQDqMrZugJxIh/h5e8mSuDrafbR9Lx53DGBqyhRtGxOI1e8VngGjroBsQ1sKU4S5gSKd9p root@localhost.localdomain"
}//security groups
resource "aws_security_group" "ingress_my_test" {
name = "allow-my-sg"

ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 22
    to_port = 22
    protocol = "tcp"
  }
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 0
    to_port = 80
    protocol = "tcp"
  }
// Terraform removes the default rule
  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
   
 }
}

//create instance
resource "aws_instance" "web1" {
          
  depends_on=[aws_key_pair.enter_key_name,
    aws_security_group.ingress_my_test
  ]
  key_name      = aws_key_pair.enter_key_name.key_name
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  
  security_groups = ["${aws_security_group.ingress_my_test.name}"]
  
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/C:/Users/sumit/Downloads/raw.pem")
    host     = aws_instance.web1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }


tags = {
    Name = "terraform"
  }
}

//download images from github
resource "null_resource" "image" {
  depends_on = [null_resource.imagedestroy]
  provisioner "local-exec" {
     
     command = " sudo git clone https://github.com/vimallinuxworld13/multicloud.git /var/www/html/"
     
  }
}
resource "null_resource" "imagedestroy" {
  provisioner "local-exec" {
     
     command = " rm -rf images"
     
  }
}

//creating EBS Volume of size 1
resource "aws_ebs_volume" "ebs_vol" {
  availability_zone = aws_instance.web1.availability_zone
  size              = 1

  tags = {
    Name = "tera_ebs"
  }
}

//Attach EBS Volume to the instance
resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.web1.id
  force_detach = true
}

output "op" {
	value = aws_instance.web1

}

//copied the IP to a .txt file
resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.web1.public_ip} > publicip.txt"
  	}
}




//make s3 bucket
resource "aws_s3_bucket" "sumit4321" {
  bucket = "sumit4321"
  acl = "public-read"
 
  tags = {
    Name  = "My-bucky1"
    Environment = "Dev"
  }
}
//bucket object
resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.sumit4321.bucket
  acl = "public-read"
  key    = "man.png"
  source = "man.png"
depends_on=[aws_s3_bucket.sumit4321,null_resource.image]

}

//make cloudfront distribution
resource "aws_cloudfront_distribution" "my_distribution" {
    origin {
         domain_name = "${aws_s3_bucket.sumit4321.bucket_regional_domain_name}"
         origin_id   = "${aws_s3_bucket.sumit4321.id}"
 
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    # By default, show index.html file
    default_root_object = "man.png"
    enabled = true
    # If there is a 404, return index.html with a HTTP 200 Response
    custom_error_response {
        error_caching_min_ttl = 3000
        error_code = 404
        response_code = 200
        response_page_path = "/index.php"
    }

default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${aws_s3_bucket.sumit4321.id}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE","IN"]
    }
  }

    # SSL certificate for the service.
    viewer_certificate {
        cloudfront_default_certificate = true
    }
 depends_on=[aws_s3_bucket.yash11]
}
resource "null_resource" "nullremote"  {
depends_on = [  aws_volume_attachment.ebs_att,aws_cloudfront_distribution.my_distribution]
    connection {
        type    = "ssh"
        user    = "ec2-user"
        host    = aws_instance.web1.public_ip
        port    = 22
        private_key = file("C:/Users/sumit/Downloads/tom.pem")
    }
}

resource "null_resource" "nullremote3"  {

depends_on = [
    aws_volume_attachment.ebs_att
  ]
 connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/sumit/Downloads/tom.pem")
    host     = aws_instance.web1.public_ip
  }

provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4  /dev/xvdf",
      "sudo mount  /dev/xvdf  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git sudo  https://github.com/vimallinuxworld13/multicloud.git /var/www/html/",
      "sudo su << EOF",
            "echo \"${aws_cloudfront_distribution.sumit4321.domain_name}\" >> /var/www/html/path.txt",
            "EOF",
      "sudo systemctl restart httpd"
    ]
  }
}
//open the website in chrome
resource "null_resource" "nulllocal1"  {
depends_on = [
    null_resource.nullremote3,
  ]
	provisioner "local-exec" {
	    command = "firefox ${aws_instance.web1.public_ip}"
         }
}



