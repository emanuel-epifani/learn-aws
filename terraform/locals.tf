
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
