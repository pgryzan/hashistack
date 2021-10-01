////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           hashistack
//  File Name:      kubernetes/modules/terraform-kubernetes-boundary/boundary.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           September 2021
//  Description:    This is the boundary execution file for boundary module
//                  https://github.com/hashicorp/boundary-reference-architecture/tree/main/deployment/kube/kubernetes
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Environment
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
terraform {
    required_version            = ">= 1.0.6"
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Scope
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "boundary_scope" "global" {
    global_scope = true
    name         = "global"
    scope_id     = "global"
}

resource "boundary_scope" "org" {
    scope_id    = boundary_scope.global.id
    name        = "HashiCorp"
    description = "HashiCorp Organization Scope"
}

// resource "boundary_scope" "project" {
//     name                     = "databases"
//     description              = "Databases Project"
//     scope_id                 = boundary_scope.org.id
//     auto_create_admin_role   = true
//     auto_create_default_role = true
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Roles
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "boundary_role" "global_anon_listing" {
    scope_id = boundary_scope.global.id
    grant_strings = [
        "id=*;type=auth-method;actions=list,authenticate",
        "type=scope;actions=list",
        "id={{account.id}};actions=read,change-password"
    ]
    principal_ids = ["u_anon"]
}

resource "boundary_role" "org_anon_listing" {
    scope_id = boundary_scope.org.id
    grant_strings = [
        "id=*;type=auth-method;actions=list,authenticate",
        "type=scope;actions=list",
        "id={{account.id}};actions=read,change-password"
    ]
    principal_ids = ["u_anon"]
}

resource "boundary_role" "org_admin" {
    scope_id       = "global"
    grant_scope_id = boundary_scope.org.id
    grant_strings  = ["id=*;type=*;actions=*"]
    principal_ids = concat(
        [for user in boundary_user.user : user.id],
        ["u_auth"]
    )
}

// resource "boundary_role" "proj_admin" {
//     scope_id       = boundary_scope.org.id
//     grant_scope_id = boundary_scope.project.id
//     grant_strings  = ["id=*;type=*;actions=*"]
//     principal_ids = concat(
//         [for user in boundary_user.user : user.id],
//         ["u_auth"]
//     )
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Auth Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "boundary_auth_method" "password" {
    name        = "org_password_auth"
    description = "Password auth method for org"
    type        = "password"
    scope_id    = boundary_scope.org.id
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Account
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "boundary_account" "user" {
    for_each       = var.users
    name           = each.key
    description    = "User account for ${each.key}"
    type           = "password"
    login_name     = lower(each.key)
    password       = "password"
    auth_method_id = boundary_auth_method.password.id
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Users
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
resource "boundary_user" "user" {
    for_each    = var.users
    name        = each.key
    description = "User resource for ${each.key}"
    account_ids = [boundary_account.user[each.value].id]
    scope_id    = boundary_scope.org.id
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Targets
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// resource "boundary_target" "redis" {
//     type                     = "tcp"
//     name                     = "redis"
//     description              = "Redis container"
//     scope_id                 = boundary_scope.project.id
//     session_connection_limit = -1
//     session_max_seconds      = 10000
//     default_port             = 6379
//     host_set_ids = [
//         boundary_host_set.redis_containers.id
//     ]
// }

// resource "boundary_target" "postgres" {
//     type                     = "tcp"
//     name                     = "postgres"
//     description              = "Postgres server"
//     scope_id                 = boundary_scope.project.id
//     session_connection_limit = -1
//     session_max_seconds      = 10000
//     default_port             = 5432
//     host_set_ids = [
//         boundary_host_set.postgres_containers.id
//     ]
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Host Catalog
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// resource "boundary_host_catalog" "databases" {
//     name        = "databases"
//     description = "Database targets"
//     type        = "static"
//     scope_id    = boundary_scope.project.id
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Host
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// resource "boundary_host" "redis" {
//     type            = "static"
//     name            = "redis"
//     description     = "redis container"
//     address         = "redis.svc"
//     host_catalog_id = boundary_host_catalog.databases.id
// }

// resource "boundary_host" "postgres" {
//     type            = "static"
//     name            = "postgres"
//     description     = "postgres container"
//     address         = "postgres.svc"
//     host_catalog_id = boundary_host_catalog.databases.id
// }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Host Set
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// resource "boundary_host_set" "redis_containers" {
//     type            = "static"
//     name            = "redis_containers"
//     description     = "Host set for redis containers"
//     host_catalog_id = boundary_host_catalog.databases.id
//     host_ids        = [boundary_host.redis.id]
// }

// resource "boundary_host_set" "postgres_containers" {
//     type            = "static"
//     name            = "postgres_containers"
//     description     = "Host set for postgres containers"
//     host_catalog_id = boundary_host_catalog.databases.id
//     host_ids        = [boundary_host.postgres.id]
// }