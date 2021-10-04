////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack-kubernetes
//  File Name:      modules/hashicups/variables.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the input variables file for the hashicups module
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Database Configuration
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
variable "postgres" {
    type            = map
    description     = "Postgres Configuration"
    default         = {
        name        = "postgres"
        replicas    = 1
        image       = "hashicorpdemoapp/product-api-db:v0.0.17"
        port        = 5432
    }
}

variable "redis" {
    type            = map
    description     = "Redis Configuration"
    default         = {
        name        = "redis"
        replicas    = 1
        image       = "redis"
        port        = 6379
    }
}