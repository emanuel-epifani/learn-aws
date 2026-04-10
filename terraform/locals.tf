
# ============================================
# LAMBDA REST - HTTP Endpoints
# ============================================
# Ogni entry rappresenta una Lambda REST con il suo endpoint API Gateway
# Aggiungi nuove Lambda REST qui seguendo lo stesso pattern

locals {
  rest_lambdas = {
    get_data = {
      name    = "get-data"
      source  = "../lambda/dist/rest/lambda-rest.zip"
      handler = "handler.handler"
      path    = "data"
      method  = "GET"
    }
    # Esempio per aggiungere nuove Lambda REST:
    # get_users = {
    #   name    = "get-users"
    #   source  = "../lambda/dist/rest/get-users.zip"
    #   handler = "handler.handler"
    #   path    = "users"
    #   method  = "GET"
    # }
    # create_post = {
    #   name    = "create-post"
    #   source  = "../lambda/dist/rest/create-post.zip"
    #   handler = "handler.handler"
    #   path    = "posts"
    #   method  = "POST"
    # }
  }
}

# ============================================
# LAMBDA GRAPHQL - GraphQL Endpoints
# ============================================
# GraphQL usa tipicamente UNA sola Lambda per tutte le query/mutations
# AppSync chiama la stessa Lambda con differenti "actions"
# Aggiungi nuove Lambda GraphQL qui se necessario

locals {
  graphql_lambdas = {
    graphql_api = {
      name    = "graphql-api"
      source  = "../lambda/dist/graphql/lambda-graphql.zip"
      handler = "handler.handler"
    }
  }
}

# ============================================
# APPSYNC RESOLVERS - Campi GraphQL
# ============================================
# Ogni entry rappresenta un campo dello schema GraphQL (Query o Mutation)
# AppSync usa questi resolvers per collegare i campi alla Lambda
# Aggiungi nuovi resolvers qui per nuovi campi GraphQL

locals {
  graphql_resolvers = {
    get_data = {
      type  = "Query"
      field = "getData"
    }
    # Esempio per aggiungere nuovi resolvers:
    # get_users = {
    #   type  = "Query"
    #   field = "getUsers"
    # }
    # create_post = {
    #   type  = "Mutation"
    #   field = "createPost"
    # }
  }
}
