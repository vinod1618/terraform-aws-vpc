variable "project"{
    type = string
}

variable "environment"{
    type = string
}

variable "vpc_cidr"{
    type = stirng
    default = "10.0.0.0/16"
}


variable "vpc_tags"{
    type = map
    default = {
        
    }
}
